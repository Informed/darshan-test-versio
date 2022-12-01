from invoke import task
import shutil, os, sys, re, json, logging
import pprint, inspect
from pathlib import Path
from pyinvokedepends import depends

project_top_dir = Path(__file__).parents[3]
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


@task
def show(c):
    """Show layers"""
    print(f"Layers: {glbs.aws_region}")


## TODO: Add ability to add the otel layer as a docker layer
## https://aws.amazon.com/blogs/compute/working-with-lambda-layers-and-extensions-in-container-images/
##
default_otel_version = "1-13-0"
default_arch = "amd64"
default_layer_version = "1"
default_layer_name = "aws-otel-python"
default_layer_arn = f"arn:aws:lambda:us-west-2:901920570463:layer:{default_layer_name}-{default_arch}-ver-{default_otel_version}:{default_layer_version}"


@depends(on=["./otel_layer.zip"], creates=["./opt"])
@task
def download_otel_layer(c, arn=default_layer_arn):
    """
    Download the OpenTelemetry Python Lambda Layer as a zip file
    """
    result = c.run(
        re.sub(
            " +",
            " ",
            f"aws lambda get-layer-version-by-arn \
            --arn {arn} \
            --query Content.Location \
            --output text",
        ),
        hide="stdout",
    )
    if layer_url := result.stdout.strip():
        logging.debug(f"layer_url: {layer_url}")
        c.run(f"curl -s '{layer_url}' -o otel_layer.zip")
    else:
        logging.error("Could not get layer URL for arn: {arn}")
        SystemExit()


@depends(on=["./otel_layer.zip"], creates=["./opt"])
@task(pre=[download_otel_layer])
def unzip_otel_layer(c):
    """
    Unzip the OpenTelemetry Python Lambda Layer into ./opt
    Will not run if ./opt is newer than ./otel_layer.zip.
    You can `rm -r opt` to force a re-unzip.
    """
    c.run("rm -rf opt")
    c.run("unzip otel_layer.zip -d opt", hide="stdout")


@task(
    pre=[unzip_otel_layer],
    optional=[
        "env",
        "layer_name",
        "arch",
        "otel_version",
        "layer_version",
    ],
)
def build_otel_docker_layer(
    c,
    env=None,
    layer_name=default_layer_name,
    arch=default_arch,
    otel_version=default_otel_version,
    layer_version=default_layer_version,
):
    """
    Build the OpenTelemetry Python Lambda Layer as a Docker layer
        env: The environment to build the layer for. Defaults to $DEVX_ENV or $USER
        layer_name: The name of the layer. Defaults to `default_layer_name`
        arch: The architecture of the layer. Defaults to `default_arch`
        otel_version: The version of the OpenTelemetry Python Lambda Layer. Defaults to `default_otel_version`
        layer_version: The version of the layer. Defaults to `default_layer_version`
    """
    c.run(
        f"docker build -t {ecr_repo(env)}/{layer_name}-{arch}-ver-{otel_version}:{layer_version} .",
    )


# aws ecr create-repository --repository-name myorg/myapp
@task(pre=[build_otel_docker_layer])
def build_and_push_otel_docker_layer(
    c,
    env=None,
    layer_name=default_layer_name,
    arch=default_arch,
    otel_version=default_otel_version,
    layer_version=default_layer_version,
):
    """
    Build and Push the OpenTelemetry Python Lambda Layer as a Docker layer
        env: The environment to build the layer for. Defaults to $DEVX_ENV or $USER
        layer_name: The name of the layer. Defaults to `default_layer_name`
        arch: The architecture of the layer. Defaults to `default_arch`
        otel_version: The version of the OpenTelemetry Python Lambda Layer. Defaults to `default_otel_version`
        layer_version: The version of the layer. Defaults to `default_layer_version`
    """
    env = env or glbs.env_name
    with_sha = not env in ["dev", "qa", "prod"]
    repository_name = f"{layer_name}-{arch}-ver-{otel_version}"
    print(f"Pushing docker image to ECR env: {env}")
    c.run(
        f"aws --output json ecr describe-repositories --repository-names {repository_name} || aws ecr create-repository --repository-name {repository_name}",
        hide="stdout",
    )
    c.run(
        f"aws ecr get-login-password --profile {glbs.env_name} --region {glbs.aws_region} | docker login --username AWS --password-stdin {ecr_repo(env)}/{glbs.project_dash_name}"
    )
    c.run(f"docker push {ecr_repo(env)}/{repository_name}:{layer_version}")


@task
def show_defaults(c):
    """
    Show the default values used to build the Repository name and version
    """
    print(f"    layer_name: {default_layer_name}")
    print(f"    arch: {default_arch}")
    print(f"    otel_version: {default_otel_version}")
    print(f"    layer_version: {default_layer_version}")
    print(f"    layer_arn: {default_layer_arn}")
