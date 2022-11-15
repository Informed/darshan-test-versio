## This is a multistage Dockerfile
## It starts with a full unix image that gets the full build environment installed with the alias `build`
## It is used to do the pip install using requirements.txt file and builds any binaries using the build environment
## The first stage also copies in the app and all the files that are in the same directory as the Dockerfile
##
## The second stage copies from the first stage into the final Docker image based on the AWS official python lambda image
##

# ARG defined "globally" for the entire Dockerfile
# but the ARG statement without assignment has to be repeated in each build stage
#
ARG BUILD_SITE_PACKAGES="/tmp/site-packages"
ARG OTEL_LAYER_ARN="450112884190.dkr.ecr.us-west-2.amazonaws.com/aws-otel-python-amd64-ver-1-13-0:1"

FROM amazonlinux:2 as build

RUN yum groupinstall -y "Development Tools" \
  && amazon-linux-extras enable python3.8 \
  && yum clean metadata \
  && yum install -y python38 python38-devel \
  && yum clean all -y

# We create an /app directory with a virtual environment in it to store our
# application in.
RUN set -x \
    && python3.8 -m venv /app

# Setting the PATH ensures that our pip commands below use the pip inside the virtual environment,
# adding the compiled wheels to the collection we will later copy to the final image.
ENV PATH="/app/bin:${PATH}"
ARG BUILD_SITE_PACKAGES

RUN echo "BUILD_SITE_PACKAGES: ${BUILD_SITE_PACKAGES}" \
    && mkdir -p ${BUILD_SITE_PACKAGES}

# Next, we want to update pip, setuptools, and wheel inside of this virtual
# environment to ensure that we have the latest versions of them.

RUN --mount=type=cache,id=custom-pip,target=/root/.cache/pip pip3 --disable-pip-version-check install --upgrade pip setuptools wheel

# We now grab the requirements files (the specification of which packages we depend on)
COPY requirements.txt /app/requirements.txt

# This installs the packages into the venv we created above, but as a side effect
# it puts all of the wheel files into the /app/wheels directory, and this directory
# and its contents are what we will copy to the final image.
# Also cleans up the dependencies that are not needed in the final image
RUN --mount=type=cache,id=custom-pip,target=/root/.cache/pip pip3 install --disable-pip-version-check  \
    -r /app/requirements.txt -t ${BUILD_SITE_PACKAGES} \
  && find ${BUILD_SITE_PACKAGES} -wholename "*/tests/*" -type f -delete \
  && find ${BUILD_SITE_PACKAGES} -regex '^.*\(__pycache__\|\.py[co]\)$' -delete

COPY . /app

###
### Start of the second stage Docker image
### This is based on the AWS official python3 lambda
### and it also has a docker image for the otel layer
### It first installs the otel layer
###
### Then it pulls from the previous image so the pip installs above are taken into account
###

FROM ${OTEL_LAYER_ARN} as otel_layer
FROM public.ecr.aws/lambda/python:3.8
ARG OTEL_LAYER_ARN

# Otel Layer
WORKDIR /opt
COPY --from=otel_layer /opt/ .

## Function code
ARG BUILD_SITE_PACKAGES
ENV PYTHONUNBUFFERED 1
ARG SITE_PACKAGES=${LAMBDA_TASK_ROOT}/lib/python3.8/site-packages
ENV PYTHONPATH ${SITE_PACKAGES}:/opt/python:${PYTHONPATH}
WORKDIR ${LAMBDA_TASK_ROOT}

RUN mkdir -p ${SITE_PACKAGES}

# We now copy all the wheels we created in the build phase
COPY --from=build /app ${LAMBDA_TASK_ROOT}
COPY --from=build ${BUILD_SITE_PACKAGES} ${SITE_PACKAGES}

# Set the CMD to your handler
# TODO: Make this  a parameter override outside of the Dockerfile
CMD [ "app_demo.handler" ]
