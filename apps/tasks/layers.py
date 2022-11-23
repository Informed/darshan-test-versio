from invoke import task
import shutil, os, sys, re, json, logging
import pprint, inspect
from pathlib import Path

## TODO: Right now only the `build_and_deploy_deps_layer` and
## `upload_and_deploy_deps_layer` tasks will properly accept a `--env` argument
## If you want to change the environment, for other tasks, you will need to set
## the shell Environment variable: `DEPLOY_ENV`

## Import tasks from the top_tasks directory from the project root
## It is need here in addtion to __init__.py to allow for inv --collection tasks/layers to work
##
project_top_dir = Path(__file__).parents[2]
sys.path.append(str(project_top_dir))

## Import  util functions and variables from the top_tasks package in the project root
##
from top_tasks.utils import (
    glbs,
    s3_lambda_bucket,
    project_version,
    is_in_python_top_dir,
    python_version,
    lambda_name,
    ecr_repo,
    aws_account_id,
)

#### Local defines ####

## SSM Path for the Lambda Layers


## To override pre-tasks
_build = True


def get_layer_versions(c, layer_name, env):
    """Get a list of layer versions for a given layer name"""
    result = c.run(
        f"aws --output json --profile {env} lambda list-layer-versions --layer-name {layer_name} --query 'LayerVersions[*].LayerVersionArn'"
    )
    if result.stdout.strip():
        layer_versions = json.loads(result.stdout.strip())
    else:
        logging.warning(f"No layer versions found for {layer_name}")
        logging.warning("This will happen if you are using doing a Dry Run")
        layer_versions = []
    return layer_versions


def get_latest_layer(c, layer_name, env):
    """Get the latest layer version for a given layer name"""
    layer_versions = get_layer_versions(c, layer_name, env)
    logging.debug(
        f"get_latest_layer: layer_name: {layer_name} env: {env} layer_versions: {layer_versions}"
    )
    if len(layer_versions) > 0:
        versions = list(map(lambda x: int(x.split(":")[-1]), layer_versions))
        logging.debug(f"get_latest_layer: versions: {versions}")
        latest_version = max(versions)
    else:
        latest_version = 1
    logging.debug(f"Latest version of {layer_name} is {latest_version}")
    return latest_version


def get_existing_function_layers(c, lambda_name, env):
    """Get a list of layers for a given lambda function"""
    result = c.run(
        f"aws --output json lambda get-function-configuration --profile {env} --function-name {lambda_name} --query '{{layers: Layers, revisionId: RevisionId}}'"
    )
    if result.stdout.strip():
        config = json.loads(result.stdout.strip())
        layer_arns = list(map(lambda x: x["Arn"], config["layers"]))
        revision_id = config["revisionId"]
        logging.debug(
            f"get_existing_function_layers: layer_arns: {layer_arns} revision_id: {revision_id}"
        )
    else:
        logging.warning(f"No layers found for {lambda_name}")
        logging.warning("This will happen if you are using doing a Dry Run")
        layers = []
    return (layer_arns, revision_id)


@task(optional=["env"])
def build(c, env=None):
    """
    Build the layers of the project dependencies
    """
    if _build:
        env = env or glbs.env_name
        if is_in_python_top_dir():
            logging.info(
                f"Building layers for python version: {python_version()} env: {env}"
            )
            shutil.rmtree("layer_build", ignore_errors=True)
            os.mkdir("layer_build")
            c.run(
                "poetry export --with layer -f requirements.txt --output requirements.txt"
            )
            c.run(f"build-lambda-layer-python -p {python_version()}")
            try:
                os.remove("requirements.txt")
            except FileNotFoundError:
                pass
    else:
        pass


@task(pre=[build], optional=["env"])
def upload_to_s3(c, env=None):
    """
    Upload the layer zip file to s3
    """
    env = env or glbs.env_name
    src_zip = f"{glbs.project_name}_python{python_version()}.zip"
    s3_dst_versioned = f"s3://{s3_lambda_bucket(env)}/layers/{glbs.project_dash_name}-deps-{project_version()}.zip"
    s3_dst_latest = (
        f"s3://{s3_lambda_bucket(env)}/layers/{glbs.project_dash_name}-deps-latest.zip"
    )

    with c.cd("layer_build"):
        logging.info(f"Uploading to env: {env} {s3_lambda_bucket(env)}")
        c.run(
            f"aws --profile {env} s3 cp {src_zip} {s3_dst_versioned} --region {glbs.aws_region}"
        )
        c.run(
            f"aws --profile {env} s3 cp {s3_dst_versioned} {s3_dst_latest} --region {glbs.aws_region}"
        )


# Load zip file into lambda layers
@task(pre=[upload_to_s3], optional=["env"])
def publish_layer(c, env=None):
    """Publish the layer to AWS"""
    if is_in_python_top_dir():
        env = env or glbs.env_name
        layer_name = (
            f"{glbs.project_dash_name}-deps-python{python_version(seperator='none')}"
        )
        filename = f"{glbs.project_dash_name}-deps-latest.zip"
        logging.info(
            f"Publishing layer {layer_name} to s3://{s3_lambda_bucket(env)}/layers/{filename}"
        )
        c.run(
            re.sub(
                " +",
                " ",
                f"aws --profile {env} lambda publish-layer-version \
                      --layer-name {layer_name} \
                      --description '{glbs.project_name} deps' \
                      --content S3Bucket={s3_lambda_bucket(env)},S3Key=layers/{filename} \
                      --compatible-runtimes python{python_version('dot')} \
                      --compatible-architectures x86_64",
            )
        )


# Add or update layer to the lambda function
# Will keep any other existing layers
@task(pre=[publish_layer], optional=["env"])
def add_layer_to_lambda(c, env=None):
    """Add or update layer to the lambda function"""
    if is_in_python_top_dir():
        env = env or glbs.env_name

        # Get the lambda function name
        lambda_function_name = lambda_name(env)

        # Get the layer name
        layer_name = (
            f"{glbs.project_dash_name}-deps-python{python_version(seperator='none')}"
        )

        # Get the layer version
        layer_version = get_latest_layer(c, layer_name, env)

        # Get the layer ARN
        layer_arn = f"arn:aws:lambda:{glbs.aws_region}:{aws_account_id(env)}:layer:{layer_name}:{layer_version}"

        existing_layers, revision_id = get_existing_function_layers(
            c, lambda_function_name, env
        )
        other_layers = list(filter(lambda x: layer_name not in x, existing_layers))
        final_layers = other_layers + [layer_arn]
        logging.info(f"add_layer_to_lambda: final_layers: {final_layers}")
        # Add the layer to the lambda function
        result = c.run(
            re.sub(
                " +",
                " ",
                f"aws --profile {env} lambda update-function-configuration \
                --function-name {lambda_function_name} \
                --layers {' '.join(final_layers)} \
                --revision-id {revision_id}",
            )
        )

        if result:
            logging.info(
                f"Layer {layer_arn} added to lambda function {lambda_function_name}\nUpdating SSM Parameter Store with Layer ARN"
            )
            c.run(
                re.sub(
                    " +",
                    " ",
                    f"aws --profile {env} ssm put-parameter \
                    --name '{glbs.ssm_path_lambda_layers}' \
                    --description 'Update SSM with ARNs for Lambda dependency layer' \
                    --type 'StringList' \
                    --value '{layer_arn}' \
                    --overwrite",
                )
            )
        else:
            logging.warning(
                f"result: {result} Layer {layer_arn} not added to lambda function {lambda_name}"
            )


@task(post=[add_layer_to_lambda], optional=["env"])
def upload_and_deploy_deps_layer(c, env=None):
    """
    Upload and deploy an already built layer to AWS
    Public entry point to upload an existing layer zip file to s3 and deploy it to AWS layers as an ARN
    Work around for the fact that pyinvoke does not  yet pass command line arguments to` pre` .tasks
    """
    global _build
    env = env or glbs.env_name
    glbs.set_env_name(env)
    _build = False
    logging.info(
        f"Uploading layers for {glbs.project_name} python version: {python_version()} env: {env} build: {_build}"
    )
    pass


@task(post=[add_layer_to_lambda], optional=["env"])
def build_upload_and_deploy_deps_layer(c, env=None):
    """
    Build and publish the layers from scratch
    Public Entry point to do the complete build and publish proecss based on the specified aws environment
    Work around for the fact that pyinvoke does not  yet pass command line arguments to` pre` tasks
    """
    env = env or glbs.env_name
    glbs.set_env_name(env)
    logging.info(
        f"Building layers for {glbs.project_name} python version: {python_version()} env: {env}"
    )
    pass
