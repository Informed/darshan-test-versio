from invoke import task
import shutil, os, sys, re, json, logging
import pprint, inspect
from pathlib import Path

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

## Local defines to override pre-tasks
_build = True


@task
def install(c):
    """
    Poetry install main, layers and dev dependencies for local development
    """
    c.run(f"poetry install --with layers,dev")


# Uses [python-lambda-local](https://github.com/HDE/python-lambda-local)
@task(optional=["env"])
def run(c, env=None):
    """
    Run the lambda function locally using python-lambda-local
        env - The environment to run the lambda function in.  Default is $USER
    """
    env = env or glbs.env_name
    c.run(
        re.sub(
            " +",
            " ",
            f"AWS_PROFILE={env} poetry run \
               python-lambda-local \
               -f handler \
               -t 30 \
               -e environment.json \
               api_handler.py \
               application_event.json",
        )
    )
