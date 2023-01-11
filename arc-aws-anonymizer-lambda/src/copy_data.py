import boto3
import urllib
import re 
import json
import hashlib
import base64
import os
import datetime
from hash_config import hash_config

TARGET_BUCKET = os.environ['TARGET_BUCKET']

s3_client = boto3.client('s3')

# Requires target_key and json_object to parse key. Upon finding, value is encoded with `sha-256` then converting to `base64`. Base64 is just to avoid consecutive numbers that might do false alarm on PII data. 
def parse_json_recursively(json_object, target_key):
    if type(json_object) is dict and json_object:
        for key in json_object:
            if key == target_key:
                json_object[target_key] = str(base64.b64encode(hashlib.sha256(str(json_object[key]).encode('utf-8')).digest()),encoding='utf-8') if (json_object[key] and json_object[key] != 'None')  else json_object[key]
            parse_json_recursively(json_object[key], target_key)

    elif type(json_object) is list and json_object:
        for item in json_object:
            parse_json_recursively(item, target_key)
     
# Out of all documents, `stip_verification` has different requirement. Upon finding it wont need to change the value but need to change the value of `expected` and `answer` key.            
def parse_json_recursively_stip(json_object, target_list):
    if type(json_object) is dict and json_object:
        for key in json_object:
            if key in target_list and json_object[key] is not None:
                json_object[key]["expected"]=str(base64.b64encode(hashlib.sha256(str(json_object[key]["expected"]).encode('utf-8')).digest()),encoding='utf-8') if (json_object[key]["expected"] and json_object[key]["expected"] != 'None') else json_object[key]["expected"]
                json_object[key]["answer"]=str(base64.b64encode(hashlib.sha256(str(json_object[key]["answer"]).encode('utf-8')).digest()),encoding='utf-8') if (json_object[key]["answer"] and json_object[key]["answer"] != 'None') else json_object[key]["answer"]
            parse_json_recursively_stip(json_object[key], target_list)

    elif type(json_object) is list and json_object:
        for item in json_object:
            parse_json_recursively_stip(item,target_list)

# To remove keys from remove list. 
def remove_keys(json_object, target_key):
    if target_key in json_object: del json_object[target_key]

def stip_verifications_PII(json_object,addListPII,addList,removeList):
    parse_json_recursively_stip(json_object,addListPII)
    for key in addList:
        parse_json_recursively(json_object,key)
    for key in removeList:
        remove_keys(json_object,key)

def parse_PII(json_object,addList,removeList):
    for key in addList:
        parse_json_recursively(json_object,key)
    for key in removeList:
        remove_keys(json_object,key)

# Regex which will fetch all the documents which we want to anonymized. i.e. bucket-exchange/partnerId/applicationId/classifications/documentId.json
def pyrex(source_key):
    pyRex = re.search("^[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}/[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}/(?:documents|application|stip_verifications|classifications)/[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}.json$", source_key) 
    return pyRex
# Regex which will fetch all STS type documents. i.e. UUID/APPUUID.json
def pyrex_sts(source_key):
    pyRex = re.search("^[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}/[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}.json$", source_key) 
    return pyRex

def should_hash_partner(partner_id, current_date):
    for partner_config in hash_config.get("partner_configs",{}).get(os.environ["environment"],[]):
        if partner_config.get("partner_id") == partner_id and datetime.datetime.strptime(partner_config.get("end_date"), "%Y-%m-%d").date() > current_date:
            return False
    return True
    
def lambda_handler(event, context):
    
    # Get incoming bucket and key
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    source_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])
    today = datetime.date.today()

    if pyrex(source_key):
        partner_id = source_key.split("/")[0]
        json_object = s3_client.get_object(Bucket=source_bucket,Key=source_key)
        file_reader = json_object['Body'].read().decode("utf-8")
        pii_data = json.loads(file_reader)
        if should_hash_partner(partner_id, today):
            if "documents" in source_key:
                print("INFO: Scrapping DOCUMENTS fields")
                doc_config = hash_config.get("pii_field_hashing",{}).get("document",{})
                parse_PII(pii_data, doc_config.get("field_list"), doc_config.get("remove_list"))
            elif "application" in source_key:
                print("INFO: Scrapping APPLICATION fields")
                app_config = hash_config.get("pii_field_hashing",{}).get("application",{})
                parse_PII(pii_data, app_config.get("field_list"), app_config.get("remove_list"))
            elif "stip_verifications" in source_key:
                print("INFO: Scrapping STIP_VERIFICATION fields")
                ver_config = hash_config.get("pii_field_hashing",{}).get("verification",{})
                stip_verifications_PII(pii_data, ver_config.get("question_list"), ver_config.get("field_list") , ver_config.get("remove_list"))
        # Create byte stream and upload it to target bucket.
        uploadByteStream = bytes(json.dumps(pii_data).encode("utf-8"))
        target_key = source_key # Change if desired
        s3_client.put_object(Bucket=TARGET_BUCKET, Key=target_key, Body=uploadByteStream)
    
    if pyrex_sts(source_key):
        json_object = s3_client.get_object(Bucket=source_bucket,Key=source_key)
        file_reader = json_object['Body'].read().decode("utf-8")
        pii_data = json.loads(file_reader)
        print("INFO: Scrapping SKIP_THE_STIPS fields")
        sts_config = hash_config.get("pii_field_hashing",{}).get("skip_the_stip",{})
        parse_PII(pii_data, sts_config.get("field_list"), sts_config.get("remove_list"))
        uploadByteStream = bytes(json.dumps(pii_data).encode("utf-8"))
        target_key = source_key # Change if desired
        s3_client.put_object(Bucket=TARGET_BUCKET, Key=target_key, Body=uploadByteStream)
