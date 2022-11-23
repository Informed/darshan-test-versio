from invoke import Collection
from . import install, utils

ns = Collection()
ns.add_collection(install)
ns.add_collection(utils)
