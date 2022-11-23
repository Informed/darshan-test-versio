from typing import Optional
from invoke import task, call, Call
import sys
from pathlib import Path

## Import tasks from the top_tasks directory from the project root
## It is need here in addtion to __init__.py to allow for inv --collection tasks/git to work
##
project_top_dir = Path(__file__).parents[2]
sys.path.append(str(project_top_dir))
from top_tasks.utils import *

def check_aws_auth(c,env):
       logging.info(f"Checking for AWS SSO login")
       c.run(f"aws sts get-caller-identity --profile={env} &> /dev/null;\
            EXIT_CODE=$?;\
            if [ $EXIT_CODE == 0 ]; \
            then \
                echo AWS Profile Logged in; \
            else \
                export AWS_PROFILE={env} ;\
                aws sso login; \
            fi;"
    )

@task(optional=["env"])
def create_sandbox(c,env=None):
    """
    Create the sandbox for the infrastructure
    ARGS:
      env[optional] - if you have different uname for AWS profile then override. 
    """
    env = env or glbs.env_name
    logging.info(f"Creating Sandbox")
    base_version = shell_out(f"create_sandbox -a {glbs.project_dash_name} -u {env}")

@task(optional=["env","plan"])
def deploy_terraform_sandbox(c,env=None,plan=False):
    """
    Deploy the terraform code for the sandbox
    ARGS:
      env[optional]   - If you have different uname for AWS profile then override. 
      plan[optional]  - If you want to verify terraform before applying pass True.
    """
    env = env or glbs.env_name
    plan = plan or glbs.plan_flag
    check_aws_auth(c,env)
    logging.debug(f"Running Terraform init , plan and apply...")
    if plan:
        c.run(
            f"cd sand/{env}; \
                terraform init ;\
                terraform validate ;\
                terraform plan ;\
                terraform apply ;" \
            )
    else:
        c.run(
            f"cd sand/{env}; \
                terraform init ;\
                terraform validate ;\
                terraform plan -out .tfout ;\
                terraform apply --auto-approve .tfout ;" \
            )
        

@task(optional=["env","plan"])
def create_and_deploy_terraform_sandbox(c,env=None,plan=False):
    """
    Create the sandbox for the infrastructure and deploy it all together
    ARGS:
      env[optional]   - If you have different uname for AWS profile then override. 
      plan[optional]  - If you want to verify terraform before applying pass True.
    """
    env = env or glbs.env_name
    plan = plan or glbs.plan_flag
    logging.info(f"Creating Sandbox of {glbs.project_dash_name}")
    create_sandbox(c,env)
    logging.info(f"Deploying terraform to Sandbox of {glbs.project_dash_name}")
    deploy_terraform_sandbox(c,env,plan)
    logging.info(f"Successfully created and deployeds")
