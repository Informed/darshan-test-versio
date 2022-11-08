import boto3
import urllib
import re 

TARGET_BUCKET = os.environ['TARGET_BUCKET']

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    
    # Get incoming bucket and key
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    source_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])
    # Regex which will fetch all the documents which we want to anonymized. i.e. bucket-exchange/partnerId/applicationId/classifications/documentId.json
    x = re.search("^[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}/[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}/(?:documents|application|app_request|stip_verifications|classifications)/[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}.json$", source_key) 
    if x:
        s3_client.delete_object(Bucket=TARGET_BUCKET, Key=source_key)
