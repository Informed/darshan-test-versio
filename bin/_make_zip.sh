#!/usr/bin/env bash

set -e

# AWS Lambda Layer Zip Builder for Python Libraries
#   This script is ONLY executed inside a docker container by the "build-lambda-layer-python" script
#   IT IS NOT INTENDED TO BE EXECUTED DIRECTLY
#
#   The script itself is mapped from the calling script into the container as /var/task
#   Expects /var/task/requirements.txt to exist by mapping it in as a volume
#   Expects /var/task/layer to exist by mapping it in as a volume
#   It builds the zip file with files in lambda layers dir structure
#     /python/

# These are used for the -v option to running this script
scriptname=$(basename "$0")
scriptbuildnum="1.1.0"
scriptbuilddate="2022-10-10"

usage() {
    [[ "$1" ]] && echo -e "PRIVATE function to be run inside Docker triggered by build-lambda-layer-python t\n"
    echo -e "usage: ${scriptname} [-h] [-v]"
    echo -e "     -h\t\t\t: help"
    echo -e "     -v\t\t\t: display ${scriptname} version"
}

displayVer() {
    echo -e "${scriptname}  ver ${scriptbuildnum} - ${scriptbuilddate}"
}

while getopts ":n:hv" arg; do
    case "${arg}" in
        n) BASE_NAME=${OPTARG} ;;
        h)
            usage
            exit
            ;;
        v)
            displayVer
            exit
            ;;
        \?)
            echo -e "Error - Invalid option: $OPTARG"
            usage
            exit
            ;;
        :)
            echo "Error - $OPTARG requires an argument"
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

### VARS
CURRENT_DIR=$(
    reldir=$(
        dirname -- "$0"
        echo x
    )
    reldir=${reldir%?x}
    cd -- "$reldir" && pwd && echo x
)
CURRENT_DIR=${CURRENT_DIR%?x}

# VARS based on ENVIROMENT variables, not passed in as arguments
BASE_NAME=${BASE_NAME:-"base"}
echo "BASE_NAME: $BASE_NAME"

PYTHON="python${PYTHON_VER}"
ZIP_FILE="${BASE_NAME}_${PYTHON}.zip"

echo "BUILDING ZIP: ${ZIP_FILE} for ${PYTHON}"

# Create build dir
mkdir /tmp/build
mkdir -p /var/task/layer

# Create virtual environment and activate it
virtualenv -p $PYTHON /tmp/build
source /tmp/build/bin/activate

# Install requirements
pip install -r /temp/build/requirements.txt --no-cache-dir

# Create staging area in dir structure req for lambda layers
mkdir -p "/tmp/base/python/lib/${PYTHON}"

# Move dependancies to staging area
mv /tmp/build/lib/${PYTHON}/site-packages/* "/tmp/base/python"

# remove unused libraries
cd "/tmp/base/python"
rm -rf easy-install*
rm -rf wheel*
rm -rf setuptools*
rm -rf virtualenv*
rm -rf pip*

# Delete .pyc files from staging area
cd "/tmp/base/python"
find . -name '*.pyc' -delete

# Add files from staging area to zip
cd /tmp/base
rm -f "/var/task/layer/${ZIP_FILE}"
zip -r "/var/task/layer/${ZIP_FILE}" .

echo -e "\n${BASE_NAME} ZIP CREATION FINISHED"
