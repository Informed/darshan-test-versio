from invoke import task
import shutil, os, sys
from pathlib import Path

## Import tasks from the top_tasks directory from the project root
## It is need here in addtion to __init__.py to allow for inv --collection tasks/git to work
##
project_top_dir = Path(__file__).parents[2]
sys.path.append(str(project_top_dir))
from top_tasks.utils import *


@task
def commit(c):
    """
    Uses commitizen (cz) to do the commit
    """
    if is_in_python_top_dir():
        c.run("cz commit")


@task
def bump_sandbox(c, env=glbs.env_name):
    """
    Will bump the sandbox SEMVER of the current project
    """
    if is_in_python_top_dir():
        c.run(f"cz bump --tag-format 'api_handler-$version-{env}'")
