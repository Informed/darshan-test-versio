import sys
import json
import pprint
from inspect import getmembers
from pathlib import Path
from invoke import Collection, task, main

## Import tasks package from the top_tasks directory from the project root
project_top_dir = Path(__file__).parents[3]
sys.path.append(str(project_top_dir))
import top_tasks

## Import tasks package from the apps directory
apps_dir = Path(__file__).parents[2]
print("asd",apps_dir)
sys.path.append(str(apps_dir))
import apps_tasks

from . import layers

ns = Collection()

ns.add_task(layers.build_and_push_otel_docker_layer)
ns.add_task(layers.show_defaults)
