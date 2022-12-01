# Build AWS Lambda Layer of OpenCV

Based on [AWS Lambda function for OpenCV](https://github.com/awslabs/lambda-opencv)

## USAGE:

### Preliminary AWS CLI Setup:
1. Install [Docker](https://docs.docker.com/), the [AWS CLI](https://aws.amazon.com/cli/), and [jq](https://stedolan.github.io/jq/) on your workstation.

### Build OpenCV library using Docker

AWS Lambda functions run in an [Amazon Linux environment](https://docs.aws.amazon.com/lambda/latest/dg/current-supported-versions.html), so libraries should be built for Amazon Linux. You can build Python-OpenCV libraries for Amazon Linux using the provided Dockerfile, like this:

```
docker build --tag=lambda-layer-factory:latest .
docker run --rm -it -v $(pwd):/data lambda-layer-factory cp /packages/cv2-python37.zip /data
```


### Deploy

2. Publish the OpenCV Python library as a Lambda layer.
```
ACCOUNT_ID=$(aws sts get-caller-identity | jq -r ".Account")
LAMBDA_LAYERS_BUCKET=lambda-layers-$ACCOUNT_ID
LAYER_NAME=cv2
aws s3 mb s3://$LAMBDA_LAYERS_BUCKET
aws s3 cp cv2-python37.zip s3://$LAMBDA_LAYERS_BUCKET
aws lambda publish-layer-version --layer-name $LAYER_NAME --description "Open CV" --content S3Bucket=$LAMBDA_LAYERS_BUCKET,S3Key=cv2-python37.zip --compatible-runtimes python3.7
```
