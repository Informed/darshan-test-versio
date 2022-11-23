import sys
import json
import pprint
from inspect import getmembers
from pathlib import Path
from invoke import Collection, task, main

## Import tasks from the top_tasks directory from the project root
project_top_dir = Path(__file__).parents[2]
sys.path.append(str(project_top_dir))
import top_tasks

## Import tasks from the tasks directory in the apps/tasks directory
from . import lambdas, layers, git, local

ns = Collection()
lmbdas = Collection("lambdas")
lmbdas.add_task(lambdas.clean_python_build)
lmbdas.add_task(lambdas.build_and_deploy_python_lambda)
# lmbdas.add_task(lambdas.build_python_lambda)
lmbdas.add_task(lambdas.docker_build_and_push_image_to_ecr)
# lmbdas.add_task(lambdas.docker_build_image)
lmbdas.add_task(lambdas.docker_build_push_and_deploy_image)
ns.add_collection(lmbdas)

lyers = Collection("layers")
lyers.add_task(layers.build_upload_and_deploy_deps_layer)
lyers.add_task(layers.upload_and_deploy_deps_layer)
# lyers.add_task(layers.upload_to_s3)
ns.add_collection(lyers)

## TODO: Work with Platform team as to how we want to do SEMVER bumping
##  The current git tasks use commitizen to bump the version, but it seems that is not the best way to do it
##
# gt = Collection("git")
# gt.add_task(git.bump_sandbox)
# ns.add_collection(gt)

ns.add_collection(local)

## If you need to add in tasks from a top level top_tasks directory, you can do so here
# ns.add_collection(top_tasks.utils)

# Print the info if no command line arguments or if the list option is passed
if len(main.program.argv) == 1 or any(i in ["--list", "-l"] for i in main.program.argv):
    print(
        f"\nDefault Env: {top_tasks.utils.glbs.env_name}. Override by setting DEVX_ENV environment variable or --env flag"
    )
