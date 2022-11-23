###
### Standard Lib Imports
import subprocess
import shlex
import sys
import pkgutil
import shutil
import os
import re
import pathlib
import importlib
import configparser
import logging
from pathlib import Path

logging.getLogger().setLevel(logging.INFO)

###
### Dependencies to run basic PyInvoke
###
from invoke import task

###
### Install / Import non Standare Lib Libraries other than pyinvoke
###
def install_package(package):
    """
    Install package if they are not already installed
    Import the pacakge
    Return the module which you should assign to the name you will use just like `import`
    """
    try:
        module = importlib.import_module(package)
    except ImportError:
        subprocess.check_call([sys.executable, "-m", "pip", "install", package])
    finally:
        module = importlib.import_module(package)
    return module


toml = install_package("toml")


###
### Global Defines
###
class Glbs:
    """
    Global Variables
    """

    def __init__(
        self,
        env_name=None,
        arch=None,
        otel_version=None,
        otel_layer_version=None,
        plan_flag=None,
    ):
        # Full path to the top of the repo
        self.path_to_repo_top: Path = Path(__file__).parent.parent.resolve()

        # Directory that the invoke command is invoked in
        self.current_dir = os.getcwd()
        self.pyproject_toml = f"{self.current_dir}/pyproject.toml"
        self.gemfile = f"{self.current_dir}/Gemfile"

        # Builds a path to the pyproject.toml file from the current working directory
        # Tests if the pyproject.toml file exists in the current_dir
        # If it does, we assume that the invocation
        # directory is at the top of a poetry project
        # and is_python_in_top_dir is set to true, otherwise false
        self.is_python_in_top_dir = os.path.exists(self.pyproject_toml)
        self.is_ruby_project = os.path.exists(self.gemfile)

        # If we are in the top directory of a poetry project, this will be the project name
        # as the convetion is the top dirname of the project is the project name
        self.project_name = os.path.basename(self.current_dir)
        self.project_dash_name = self.project_name.replace("_", "-")

        self.shell = os.path.basename(os.getenv("SHELL"))
        self.aws_region = os.getenv("AWS_REGION", default="us-west-2")

        ## SSM Path to lambda layers. Mainly for dependdency layer
        self.ssm_path_lambda_layers = "/tc/platform/api-handler/lambda/layers"
        if plan_flag:
            self.plan_flag = plan_flag
        else:
            self.plan_flag = False
        if env_name:
            self.env_name = env_name
        else:
            self.env_name = os.getenv("DEVX_ENV", default=os.getenv("USER"))
        if arch:
            self.arch = arch
        else:
            self.arch = "amd64"
        if otel_version:
            self.otel_version = "otel_version"
        else:
            self.otel_version = "1.13.0"
        if otel_layer_version:
            self.otel_layer_version = otel_layer_version
        else:
            self.otel_layer_version = "1"

    def set_env_name(self, env_name):
        self.env_name = env_name

    def set_arch(self, arch):
        self.arch = arch

    def set_otel_version(self, otel_version):
        self.otel_version = otel_version

    def set_otel_layer_version(self, otel_layer_version):
        self.otel_layer_version = otel_layer_version


glbs = Glbs()

aws_config_file = os.path.expanduser("~/.aws/config")

###
### Error Handling
###


def exception_info():
    """
    Returns the exception info as a dict for use in clean error messages
    """
    import sys, traceback

    exc_type, exc_value, exc_traceback = sys.exc_info()
    values = {}
    values["filename"] = os.path.split(exc_traceback.tb_frame.f_code.co_filename)[1]
    values["linenum"] = exc_traceback.tb_lineno
    values["type"] = exc_type.__name__
    values["value"] = exc_value
    values["traceback"] = traceback.format_exc()
    return values


def exception_message(msg="", prefix="ERROR", e=None):
    """
    Returns a formatted error message
    """
    if e is None:
        e = exception_info()
    msg = f"{prefix} in {e['filename']} line {e['linenum']}: {msg}"
    return msg


###
### AWS Config Info
###


def aws_config(profile_name=glbs.env_name):
    """
    Returns the contents of the aws config file as a dict
    """
    if os.path.exists(aws_config_file):
        config = configparser.ConfigParser()
        aws_full_config = config.read(aws_config_file)
        full_profile_name = f"profile {profile_name}"
        try:
            profile = config[full_profile_name]
        except KeyError as e:
            e = exception_info()
            msg = exception_message(
                f"[{full_profile_name}] not found in {aws_config_file}"
            )
            raise SystemExit(msg)

    else:
        logging.error(f"ERROR: Expecting an AWS config file at {aws_config_file}")
        logging.error("See techno-core/docs/devx/initial-setup.md for more info")
        logging.error(
            "And https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html"
        )
        raise SystemExit

    return profile


def aws_account_id(env_name=glbs.env_name):
    """
    Returns the AWS account id for the current environment
    """
    profile = aws_config(env_name)
    account_id = profile["sso_account_id"]
    return account_id


###
### Misc
###


def shell_out(cmd):
    """
    Runs a command in a shell and returns the output
    No Error Handling
    """
    result = subprocess.run(cmd, shell=True, check=True, text=True, capture_output=True)
    logging.debug(f"shell_out: cmd: {cmd}")
    logging.debug(f"result.stdout: {result.stdout}")
    logging.debug(f"result.stderr: {result.stderr}")
    return result.stdout


def is_in_python_top_dir():
    """
    Tests to see if current directory is the top of a python project
    If not at top writes message and exits
      This will short circuit any task calling this,
      ending any task chain
    """
    if glbs.is_ruby_project:
        return True
    elif not glbs.is_python_in_top_dir:
        msg = "ERROR: You must execute this command at the top level of a Python Project that has a pyproject.toml file"
        raise SystemExit(msg)
    else:
        return True


def get_pyproject_toml():
    """
    Returns the contents of the pyproject.toml file as a dict
    """
    return toml.load(glbs.pyproject_toml)


def python_version(seperator="dot"):
    """
    Returns the python version from the pyproject.toml file
    seperator: 'dot', 'dash', 'underscore', none. Default: 'dot'
               If 'none', no seperator is used
    """
    poetry_version = get_pyproject_toml()["tool"]["poetry"]["dependencies"]["python"]
    py_version = re.findall("[0-9]+\.[0-9]+\.?[0-9]*", poetry_version)[0]
    if seperator == "dot":
        version = py_version
    elif seperator == "dash":
        version = py_version.replace(".", "-")
    elif seperator == "underscore":
        version = py_version.replace(".", "_")
    elif seperator == "none":
        version = py_version.replace(".", "")
    else:
        msg = f"ERROR: utils/python_version: Invalid seperator: {seperator}"
        raise SystemExit(msg)

    return version


def project_version(with_sha=False):
    """
    Returns the project version for the current  subproject directory
    with_sha: if true, appends the git sha to the version. Default: False
    """
    logging.debug(f"PROJECT VERSION glbs.current_dir: {glbs.current_dir}")
    if is_in_python_top_dir():
        base_version = shell_out("version_from_git_tag -b")
        if with_sha:
            sha = shell_out("git rev-parse --short HEAD")
            version = f"{base_version}-{sha}"
        else:
            version = base_version
        return version.strip()


def is_sandbox(env):
    """
    Returns True if the environment is a sandbox
    """
    return not env in ["dev", "dev-api", "qa", "staging", "prod"]


def s3_lambda_bucket(env=glbs.env_name):
    """
    Returns the name of the S3 bucket for the current environment
    If its a sandbox environment it returns a bucket in the sandbox account
    Otherwise it returns the cicd bucket
    """
    if is_sandbox(env):
        bucket = f"informed-techno-core-{env}-lambda-images"
    else:
        bucket = "iq-artifacts-cicd-uswest2"
    return bucket


def lambda_name(env=glbs.env_name, project_dash_name=glbs.project_dash_name):
    """
    Returns the name of the lambda function for the current environment
    """
    logging.debug(
        f"lambda_name: project_dash_name: {glbs.project_dash_name} env: {env}"
    )
    return os.getenv(
        "LAMBDA_NAME", default=f"techno-core-{env}-{glbs.project_dash_name}"
    )


def ecr_repo(env=glbs.env_name, aws_region=glbs.aws_region):
    """
    Returns the name of the ECR repo for the current environment
    """
    return f"{aws_account_id(env)}.dkr.ecr.{glbs.aws_region}.amazonaws.com"
