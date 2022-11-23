import sys
from inspect import getmembers
from pathlib import Path
from invoke import Collection, task, main

## Import tasks from the top_tasks directory from the project root
project_top_dir = Path(__file__).parents[2]
sys.path.append(str(project_top_dir))
import top_tasks

## Import tasks from the tasks directory in the apps/tasks directory
from . import terraform

ns = Collection()

tf = Collection("terraform")
tf.add_task(terraform.create_sandbox)
tf.add_task(terraform.deploy_terraform_sandbox)
tf.add_task(terraform.create_and_deploy_terraform_sandbox)
ns.add_collection(tf)

# ns.add_collection(top_tasks.utils)

# Print the info if no command line arguments or if the list option is passed
if len(main.program.argv) == 1 or any(i in ["--list", "-l"] for i in main.program.argv):
    print(
        f"\nDefault Env: {top_tasks.utils.glbs.env_name}. Override by setting DEVX_ENV environment variable or --env flag"
    )
