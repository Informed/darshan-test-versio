## Instructions
# 1. Create an image using this Dockerfile (note the python version)
#     docker build --tag=open-cv-lambda-layer:latest .
# 2. Copy the open cv package into a folder
#     docker run --rm -it -v $(pwd):/data open-cv-lambda-layer cp -r /packages/opencv-python-3.7/ /data
# 3. cd into the folder created folder
#     cd opencv-python-3.7
# 4. Zip the contents of the folder
#     zip -r open-cv-python-3-7.zip python/
# 5. Upload the zip file to s3 bucket informed-techno-core-<env>-lambda-images/layers
#     a. Go to s3 console and navigate to informed-techno-core-<env>-lambda-images/layers/
#     b. Click on the Upload button -> Add files -> Select the zip file created in the above step -> Upload
# 6. Create a lambda layer
#     a. Go to lambda console and select Layers from the left menu
#     b. Click on Create Layer
#     c. Name the layer open-cv-python-3-7
#     d. Check Upload a file from Amazon S3
#     e. Paste the s3 uri from previous step
#     f. Select x86_64 for Compatible architectures
#     g. Select Python 3.7 for Compatible runtimes
#     h. Create the layer

FROM amazonlinux:1
WORKDIR /
RUN yum update -y
# Install Python 3.7
RUN yum install gcc openssl-devel wget tar -y
RUN wget https://www.python.org/ftp/python/3.7.9/Python-3.7.9.tgz
RUN tar -xzvf Python-3.7.9.tgz
WORKDIR /Python-3.7.9
RUN ./configure --enable-optimizations
RUN make install
# Install Python packages
RUN mkdir /packages
RUN echo "opencv-python" >> /packages/requirements.txt
RUN mkdir -p /packages/opencv-python-3.7/python/lib/python3.7/site-packages
RUN pip3.7 install -r /packages/requirements.txt -t /packages/opencv-python-3.7/python/lib/python3.7/site-packages
