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
ARG HANDLER
ARG BUILD_SITE_PACKAGES="/tmp/site-packages"
ARG PYTHON_VERSION="3.8"

FROM amazonlinux:2 as build

ARG PYTHON_VERSION

RUN echo "PYTHON_VERSION ${PYTHON_VERSION} without dots: ${PYTHON_VERSION//.}"
RUN

## NOTE: This won't work with python 3.8 for now as the amazonlinux2 image requires
## a different mechanism to install 3.8 vs 3.7
## 3.8 require amazon-linux-extras enable python3.8 and python3.8-devel
##
RUN yum groupinstall -y "Development Tools" \
  && yum clean metadata \
  && yum install -y python${PYTHON_VERSION//.} python3-devel \
  && yum clean all -y

# We create an /app directory with a virtual environment in it to store our
# application in.
RUN set -x \
    && python${PYTHON_VERSION} -m venv /app

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
  # && find ${BUILD_SITE_PACKAGES} -name '*.so' -type f -exec strip "{}" \; \

COPY lib /app/lib/
COPY page_ocr /app/

###
### Start of the second stage Docker image
### This is based on the AWS official python3 lambda
### It pulls from the previous image so the pip installs above are taken into account
###

FROM public.ecr.aws/lambda/python:${PYTHON_VERSION}

ARG HANDLER
ARG PYTHON_VERSION
ARG BUILD_SITE_PACKAGES
ENV PYTHONUNBUFFERED 1
ARG SITE_PACKAGES=${LAMBDA_TASK_ROOT}/lib/python${PYTHON_VERSION}/site-packages
ENV PYTHONPATH ${SITE_PACKAGES}:${PYTHONPATH}
WORKDIR ${LAMBDA_TASK_ROOT}

RUN mkdir -p ${SITE_PACKAGES}

# We now copy all the wheels we created in the build phase
COPY --from=build /app ${LAMBDA_TASK_ROOT}
COPY --from=build ${BUILD_SITE_PACKAGES} ${SITE_PACKAGES}

RUN echo "HANDLER: ${HANDLER}" \
    && echo "PYTHON_VERSION: ${PYTHON_VERSION}" \
    && echo "BUILD_SITE_PACKAGES: ${BUILD_SITE_PACKAGES}" \
    && echo "SITE_PACKAGES: ${SITE_PACKAGES}" \
    && echo "LAMBDA_TASK_ROOT: ${LAMBDA_TASK_ROOT}" \
    && echo "PYTHONPATH: ${PYTHONPATH}"
# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "handler.handler" ]
