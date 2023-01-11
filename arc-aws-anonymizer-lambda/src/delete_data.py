import boto3
import urllib
import re 
import os

TARGET_BUCKET = os.environ['TARGET_BUCKET']

s3_client = boto3.client('s3')

# Regex which will fetch all the documents which we want to anonymized. i.e. bucket-exchange/partnerId/applicationId/classifications/documentId.json
def pyrex(source_key):
    pyRex = re.search("^[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}/[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}/(?:documents|application|stip_verifications|classifications)/[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}.json$", source_key) 
    return pyRex

def lambda_handler(event, context):
    
    # Get incoming bucket and key
    source_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])
    # Regex which will fetch all the documents which we want to anonymized. i.e. bucket-exchange/partnerId/applicationId/classifications/documentId.json
    if pyrex(source_key):
        s3_client.delete_object(Bucket=TARGET_BUCKET, Key=source_key)
