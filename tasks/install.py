#####
#####
# Tasks to install various pre-requisites
#####
#####

from invoke import task
import shutil, os
from .utils import *

devx_dir = f"{glbs.path_to_repo_top}/shared/devx"
direnv_source_lib_dir = f"{devx_dir}/bootstrap/direnv/lib"
direnv_target_lib_dir = "~/.config/direnv/lib"


@task
def poetry_dynamic_versioning_plugin(c):
    """
    Install the poetry-dynamic-versioning plugin
    """
    try:
        plugin_installed = c.run(
            "poetry self show plugins | grep poetry-dynamic-versioning"
        )
    except Exception as e:
        print(f"poetry-dynamic-versioning plugin not installed. Installing...")
        plugin_installed = False
    finally:
        if not plugin_installed:
            c.run("poetry self add 'poetry-dynamic-versioning[plugin]'")
        else:
            print(f"poetry-dynamic-versioning plugin already installed.")


@task
def python_deps(c):
    """
    Install Python based CLI dependencies via pipx and library dependencies via pip
    """
    c.run("pip --exists-action i install pyinvokedepends", hide="stdout")
    c.run("pip --exists-action i install icecream", hide="stdout")

    if not shutil.which("pipx"):
        print("pipx not found, installing...")
        c.run("brew install pipx; pipx ensurepath")


@task
def direnv_libs(c):
    """
    Install direnv customization libs
    """
    c.run(f"mkdir -p -m 755 {direnv_target_lib_dir}")
    c.run(f"cp {direnv_source_lib_dir}/* {direnv_target_lib_dir}")
    c.run(f"chmod -R 755 {direnv_target_lib_dir}")


@task
def cargo(c):
    """
    Install cargo to enable installing checkexec and other rust packages
    """
    if not shutil.which("cargo"):
        print("ERROR: cargo not found. Installing Rust and thus Cargo")
        c.run("brew install rust")


@task(pre=[cargo])
def checkexec(c):
    """
    Install checkexec to allow commands to have make like file dependencies
    """
    if not shutil.which("checkexec"):
        c.run("cargo install checkexec")


@task(pre=[direnv_libs, checkexec, python_deps, poetry_dynamic_versioning_plugin])
def bootstrap_devx(c):
    """
    Top level recipe to call all the other recipies needed bootstrap the devx
    """
    print("Installing devx tooling")
