import pprint
from inspect import getmembers
from invoke import task, call, Call
import shutil, os, sys, logging
from pathlib import Path
import datetime
from pyinvokedepends import depends

## TODO: Right now only the `build_and_deploy_deps_layer` task will properly
## accept a `--env` argument and pass it to other task dependencies If you want
## to change the environment, for other tasks, you will need to set the shell
## Environment variable: `DEPLOY_ENV`

## Import tasks from the top_tasks directory from the project root
## It is need here in addtion to __init__.py to allow for inv --collection tasks/lambdas to work
##
project_top_dir = Path(__file__).parents[2]
sys.path.append(str(project_top_dir))

## Import util functions and variables from the top_tasks package in the project root
##
from top_tasks.utils import (
    glbs,
    s3_lambda_bucket,
    project_version,
    is_in_python_top_dir,
    python_version,
    lambda_name,
    ecr_repo,
    is_sandbox,
)

###
# Defines
###

# Used to pass the `build_mode` from a top level task to build_python_lambda thru a chain of task `pre`
_build_mode = "main"


def zip_name_with_version(env=None):
    """
    Return the name of the zip file for the lambda with the version number
    """
    env = env or glbs.env_name
    with_sha = is_sandbox(env)
    zip_file_name = f"{project_version(with_sha=with_sha)}.zip"
    logging.debug(f"zip_file_name: {zip_file_name}")
    return zip_file_name


@task
def show(c, env=None):
    """
    Show the current lambda name and s3 bucket
    """
    env = env or glbs.env_name
    print(f"env: {env}")
    print(f"Lambda name: {lambda_name(env)}")
    print(f"S3 bucket: {s3_lambda_bucket(env)}")
    print(f"ECR repo: {ecr_repo(env)}")


###
# Python Recipes
###


@task
def clean_python_build(c):
    """
    Remove all generated files from poetry / python builds
    """
    if is_in_python_top_dir():
        c.run("rm -rf build out dist package")


# @depends(on=["./pyproject.toml"], creates=["./package"])
@task(pre=[clean_python_build], optional=["build_mode"])
def build_python_lambda(c, build_mode=None):
    """
    Build the package and the python wheel files for the lambda Zip file (Local only)
    build_mode can be passed in as an arg or if that is not set,
      it will get it from _build_mode
    build_mode:
      local  - For local development
               All main, dev and layer dependencies
      main   - Minimal deployable code. Expects all dependencies in layer[s]
               Just main dependencies
      layer  - Just the layer dependencies
      full   - Main and layer dependencies
      docker - Docker based Lambda
               main, layer and docker dependencies
    """
    global _build_mode
    # See if local build_mode should be set from global _build_mode
    logging.info(
        f"1: build_python_lambda build_mode: {build_mode} _build_mode: {_build_mode}"
    )
    if build_mode == None:
        build_mode = _build_mode

    logging.info(
        f"2: build_python_lambda build_mode: {build_mode} _build_mode: {_build_mode}"
    )
    if build_mode == "local":
        extra_args = "--with layer,dev"
    elif build_mode == "full":
        extra_args = "--with layer"
    elif build_mode == "main":
        extra_args = "--only main"
    elif build_mode == "layer":
        extra_args = "--only layer"
    elif build_mode == "docker":
        extra_args = "--only main,layer"
    else:
        SystemExit(
            f"Invalid build_mode: {build_mode} for task lambdas.build_python_lambda"
        )

    c.run(
        f"poetry export {extra_args} -f requirements.txt --output requirements.txt --without-hashes"
    )
    c.run("poetry build")
    c.run(
        "poetry run pip install -r requirements.txt --upgrade --only-binary :all: --platform manylinux2010_x86_64 --target package dist/*.whl"
    )


###
### Regular (non-docker) Lambda Tasks
###


@task(pre=[build_python_lambda], optional=["env"])
def python_zip_it(c, env=None):
    """
    Zip the package and the python wheel files suitable for a lambda function
    """
    env = env or glbs.env_name
    zip_file_name = zip_name_with_version(env)
    with c.cd("package"):
        c.run("mkdir -p out")
        logging.info(f"Zipping up the package to out/{zip_file_name}")
        c.run(f"zip -r -q out/{zip_file_name} . -x '*.pyc'")


@task(pre=[python_zip_it], optional=["env"])
def upload_to_s3(c, env=None):
    """
    Upload the zip file to s3
    """
    env = env or glbs.env_name
    zip_file_name = zip_name_with_version(env)
    version_asset_s3_path = f"{s3_lambda_bucket(env)}/{env}/{glbs.project_name}/{project_version(with_sha=is_sandbox(env))}.zip"
    latest_asset_s3_path = (
        f"{s3_lambda_bucket(env)}/{env}/{glbs.project_name}/latest.zip"
    )
    with c.cd("package"):
        logging.info(f"Uploading to s3 bucket: {version_asset_s3_path}")
        c.run(
            f"aws s3 cp out/{zip_file_name} s3://{version_asset_s3_path} --region {glbs.aws_region} --profile 'cicd'"
        )
        c.run(
            f"aws s3 cp s3://{version_asset_s3_path} s3://{latest_asset_s3_path} --region {glbs.aws_region} --profile 'cicd'"
        )

@task(pre=[call(upload_to_s3, env=None)], optional=["env"])
def update_lambda_function(c, env=None):
    """
    Update the lambda function with the new code from the image in s3 bucket
    """
    env = env or glbs.env_name
    version = project_version(with_sha=is_sandbox(env)) 
    upload_time = datetime.datetime.now().strftime("%x %X")
    logging.info(f"Updating lambda {lambda_name(env)}")
    function_arn=c.run(
        f"aws lambda update-function-code \
    --function-name {lambda_name(env)} \
    --s3-bucket {s3_lambda_bucket(env)} \
    --s3-key {env}/{glbs.project_name}/latest.zip \
    --region {glbs.aws_region} \
    --profile {env} \
    --output json | jq -r .FunctionArn"
    )
    function_arn = function_arn.stdout.strip()
    c.run(f"aws lambda tag-resource \
        --resource {function_arn} \
        --tags version='{version}',time='{upload_time}' \
        --region {glbs.aws_region} \
        --profile {env}"
    )


@task(post=[update_lambda_function], optional=["build_mode", "env"])
def build_and_deploy_python_lambda(c, env=None, build_mode="main"):
    """
    Build the Zip file and deploy to AWS Lambda function
    build_mode:
      *main   - (Default) Minimal deployable code. Expects all dependencies in layer[s]
               Just main dependencies
      layer  - Just the layer dependencies
      docker - Docker based Lambda
               main, layer and docker dependencies
    """
    global _build_mode
    if env:
        glbs.set_env_name(env)
    else:
        env = glbs.env_name

    _build_mode = build_mode
    logging.info(
        f"build_and_deploy_python_lambda build_mode: {build_mode} _build_mode: {_build_mode} env: {env}"
    )
    pass


###
### Docker based Lambda Tasks
###


@task(pre=[clean_python_build])
def docker_generate_requirements(c):
    """
    Generate the requirements.txt file for the docker build. Not normally run directly
    """
    if glbs.is_ruby_project:
        return
    else:
        c.run(
            "poetry export --only main,layer,docker -f requirements.txt --output requirements.txt --without-hashes -vvv"
        )


## TODO: Add options to override otel layer and arch
@task(pre=[docker_generate_requirements], optional=["env"])
def docker_build_image(c, env=None):
    """
    Build a docker image of the lambda function (Does not deploy to ECR or Lambda)
    """
    env = env or glbs.env_name
    with_sha = not env in ["dev", "qa", "prod"]
    if not glbs.is_ruby_project:
        otel_layer_arn = f"{ecr_repo(env)}/aws-otel-python-{glbs.arch}-ver-{glbs.otel_version.replace('.', '-')}:{glbs.otel_layer_version}"
        logging.info(
            f"Building docker image env: {env} otel_layer_arn: {otel_layer_arn} with_sha: {with_sha}"
        )
    c.run(
        f"aws ecr get-login-password \
        --profile {glbs.env_name} \
        --region {glbs.aws_region} | \
        docker login \
        --username AWS \
        --password-stdin {ecr_repo(env)}"
    )
    build_args = ""
    if not glbs.is_ruby_project:
        build_args = f"--build-arg PYTHON_VERSION={python_version()} \
          --build-arg OTEL_LAYER_ARN={otel_layer_arn} \
         --build-arg HANDLER={glbs.project_name}.handler"

    c.run(
        f"DOCKER_BUILDKIT=1 \
        docker build --platform linux/amd64 \
        -t {glbs.project_dash_name}:latest \
        {build_args} \
        ."
    )
    c.run(
        f"docker tag {glbs.project_dash_name}:latest {ecr_repo(env)}/{glbs.project_dash_name}:latest"
    )
    c.run(
        f"docker tag {glbs.project_dash_name}:latest {ecr_repo(env)}/{glbs.project_dash_name}:{project_version(with_sha)}"
    )


## TODO: Add options to override otel layer and arch
@task(pre=[docker_build_image], optional=["env"])
def docker_build_and_push_image_to_ecr(c, env=None):
    """
    Build and Push the docker image to ECR
    """
    env = env or glbs.env_name
    with_sha = not env in ["dev", "qa", "prod"]
    logging.info(f"Pushing docker image to ECR env: {env}")
    c.run(
        f"aws ecr get-login-password --profile {glbs.env_name} --region {glbs.aws_region} | docker login --username AWS --password-stdin {ecr_repo(env)}/{glbs.project_dash_name}"
    )
    c.run(f"docker push {ecr_repo(env)}/{glbs.project_dash_name}:latest")
    c.run(
        f"docker push {ecr_repo(env)}/{glbs.project_dash_name}:{project_version(with_sha)}"
    )


## TODO: Add options to override otel layer and arch
@task(pre=[docker_build_and_push_image_to_ecr], optional=["env"])
def docker_update_lambda_function_with_image(c, env=None):
    """
    Update the lambda function with the new code from the image in s3 bucket
    """
    env = env or glbs.env_name
    logging.info(f"Updating lambda {lambda_name(env)}")
    c.run(
        f"aws lambda update-function-code \
    --profile {glbs.env_name} \
    --function-name {lambda_name(env)} \
    --image-uri {ecr_repo(env)}/{glbs.project_dash_name}:latest \
    --region {glbs.aws_region}"
    )


@task(
    post=[call(docker_update_lambda_function_with_image, env=None)],
    optional=["env"],
)
def docker_build_push_and_deploy_image(c, env=None):
    """
    Build, push to ECR, and deploy the Docker image to the Lambda function in AWS
    """
    env = env or glbs.env_name
    logging.info(f"build_and_deploy_lambda_docker_image env: {env}")
    glbs.set_env_name(env)
    pass
