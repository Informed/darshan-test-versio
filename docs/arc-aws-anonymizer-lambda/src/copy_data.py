import boto3
import urllib
import re 
import json
import hashlib
import base64
import os

TARGET_BUCKET = os.environ['TARGET_BUCKET']

s3_client = boto3.client('s3')

# Requires target_key and json_object to parse key. Upon finding, value is encoded with `sha-256` then converting to `base64`. Base64 is just to avoid consecutive numbers that might do false alarm on PII data. 
def parse_json_recursively(json_object, target_key):
    if type(json_object) is dict and json_object:
        for key in json_object:
            if key == target_key:
                json_object[target_key] = str(base64.b64encode(hashlib.sha256(str(json_object[key]).encode('utf-8')).digest()),encoding='utf-8')
            parse_json_recursively(json_object[key], target_key)

    elif type(json_object) is list and json_object:
        for item in json_object:
            parse_json_recursively(item, target_key)
     
# Out of all documents, `stip_verification` has different requirement. Upon finding it wont need to change the value but need to change the value of `expected` and `answer` key.            
def parse_json_recursively_stip(json_object, target_list):
    if type(json_object) is dict and json_object:
        for key in json_object:
            if key in target_list and json_object[key] is not None:
                json_object[key]["expected"]=str(base64.b64encode(hashlib.sha256(str(json_object[key]["expected"]).encode('utf-8')).digest()),encoding='utf-8')
                json_object[key]["answer"]=str(base64.b64encode(hashlib.sha256(str(json_object[key]["answer"]).encode('utf-8')).digest()),encoding='utf-8')
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

def load_data():
    global  addDocumentList, removeDocumentList , addApplicationList, removeApplicationList , addStipVerificationListStip , addStipVerificationList,  removeStipVerificationList
    # Document List 
    addDocumentList = os.environ['ADD_DOCUMENTS_PII'].split(',')
    removeDocumentList = os.environ['REMOVE_DOCUMENTS_PII'].split(',')
    # Application List
    addApplicationList = os.environ['ADD_APPLICATION_PII'].split(',')
    removeApplicationList = os.environ['REMOVE_APPLICATION_PII'].split(',') 
    # Stip Verification List
    addStipVerificationListStip = os.environ['ADD_STIP_VERIFICATION_PII'].split(',')
    addStipVerificationList = os.environ['ADD_STIP_VERIFICATION_LIST_PII'].split(',')
    removeStipVerificationList = os.environ['REMOVE_STIP_VERIFICATION_PII'].split(',')

def lambda_handler(event, context):
    
    # Get incoming bucket and key
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    source_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])

    if pyrex(source_key):
        json_object = s3_client.get_object(Bucket=source_bucket,Key=source_key)
        file_reader = json_object['Body'].read().decode("utf-8")
        pii_data = json.loads(file_reader)
        load_data()
        if "documents" in source_key:
            print("INFO: Scrapping DOCUMENTS fields")
            parse_PII(pii_data,addDocumentList,removeDocumentList)
        elif "application" in source_key:
            print("INFO: Scrapping APPLICATION fields")
            parse_PII(pii_data,addApplicationList,removeApplicationList)
        elif "stip_verifications" in source_key:
            print("INFO: Scrapping STIP_VERIFICATION fields")
            stip_verifications_PII(pii_data,addStipVerificationListStip,addStipVerificationList,removeStipVerificationList)
        # Create byte stream and upload it to target bucket.
        uploadByteStream = bytes(json.dumps(pii_data).encode("utf-8"))
        target_key = source_key # Change if desired
        s3_client.put_object(Bucket=TARGET_BUCKET, Key=target_key, Body=uploadByteStream)
