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

def documents_PII(json_object):
    addList = ["first_name","last_name","middle_name","suffix","email","ssn","driver_license_number","date_of_birth","dob","account_number","bank_account_number","vin","id_number", "policy_number","tin","itin","applicant_phone_number","trade_in_vin","zip","city","state","street_2","street_address","phone" ]
    removeList = ["analysis_document_payload"]
    for x in addList:
        parse_json_recursively(json_object,x)
    for x in removeList:
        remove_keys(json_object,x)
        
def app_request_PII(json_object):
    addList = ["first_name","last_name","middle_name","suffix","email","ssn","date_of_birth","dob","account_number","bank_account_number","vin","id_number", "policy_number","tin","itin","zip","city","state","street_2","street_address","phone" ]
    for x in addList:
        parse_json_recursively(json_object,x)
     
def application_PII(json_object):
    addList = ["first_name","last_name","middle_name","suffix","email","ssn","date_of_birth","dob","account_number","bank_account_number","vin","id_number", "policy_number","tin","itin","applicant_phone_number","zip","city","state","street_2","street_address","phone" ]
    for x in addList:
        parse_json_recursively(json_object,x)

def stip_verifications_PII(json_object):
    addList = ["matches_applicant_name", "matches_applicant2_name","matches_applicant1_name" "matches_applicant_address","matches_applicant_ssn","vin","policy_number","matches_applicant_vin", "matches_approval_vin","account_number","matches_contract_vin","matches_approval_vin","dob","is_ssi_deposit_referencing_applicant_name","matches_applicant_dob"]
    parse_json_recursively_stip(json_object,addList)

def lambda_handler(event, context):
    
    # Get incoming bucket and key
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    source_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])
    # Regex which will fetch all the documents which we want to anonymized. i.e. bucket-exchange/partnerId/applicationId/classifications/documentId.json
    x = re.search("^[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}/[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}/(?:documents|application|app_request|stip_verifications|classifications)/[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}.json$", source_key) 
    if x:
        json_object = s3_client.get_object(Bucket=source_bucket,Key=source_key)
        file_reader = json_object['Body'].read().decode("utf-8")
        pii_data = json.loads(file_reader)
        if "documents" in source_key:
            print("INFO: Scrapping DOCUMENTS fields")
            documents_PII(pii_data)
        elif "application" in source_key:
            print("INFO: Scrapping APPLICATION fields")
            application_PII(pii_data)
        elif "app_request" in source_key:
            print("INFO: Scrapping APP_REQUEST fields")
            app_request_PII(pii_data)
        elif "stip_verifications" in source_key:
            print("INFO: Scrapping STIP_VERIFICATION fields")
            stip_verifications_PII(pii_data)
        uploadByteStream = bytes(json.dumps(pii_data).encode("utf-8"))
        target_key = source_key # Change if desired
        s3_client.put_object(Bucket=TARGET_BUCKET, Key=target_key, Body=uploadByteStream)
