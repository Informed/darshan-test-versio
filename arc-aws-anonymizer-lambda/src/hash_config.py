hash_config = {
    "pii_field_hashing": {
        "document": {
            "field_list": [
                "first_name",
                "last_name",
                "middle_name",
                "suffix",
                "email",
                "ssn",
                "driver_license_number",
                "date_of_birth",
                "dob",
                "account_number",
                "bank_account_number",
                "vin",
                "id_number",
                "policy_number",
                "tin",
                "itin",
                "applicant_phone_number",
                "trade_in_vin",
                "zip",
                "city",
                "state",
                "street_2",
                "street_address",
                "phone"
            ],
            "remove_list": [
                "analysis_document_payload"
            ]
        },
        "application": {
            "field_list": [
                "first_name",
                "last_name",
                "middle_name",
                "suffix",
                "email",
                "ssn",
                "date_of_birth",
                "dob",
                "account_number",
                "bank_account_number",
                "vin",
                "id_number",
                "policy_number",
                "tin",
                "itin",
                "zip",
                "city",
                "state",
                "street_2",
                "street_address",
                "phone"
            ],
            "remove_list": []
        },
        "verification": {
            "field_list": [
                "recommendations"
            ],
            "remove_list": [],
            "question_list": [
                "matches_applicant_name",
                "matches_applicant2_name",
                "matches_applicant1_name",
                "matches_applicant1_ssn",
                "matches_applicant1_address",
                "matches_applicant2_ssn",
                "matches_applicant2_address",
                "matches_applicant1_dob",
                "matches_applicant2_dob",
                "matches_applicant1_vin",
                "matches_applicant2_vin",
                "matches_applicant_address",
                "matches_applicant_ssn",
                "vin",
                "policy_number",
                "matches_applicant_vin",
                "matches_approval_vin",
                "account_number",
                "matches_contract_vin",
                "matches_approval_vin",
                "dob",
                "is_ssi_deposit_referencing_applicant_name",
                "matches_applicant_dob",
                "matches_cudl_driver_license_id"
            ]
        },
        "skip_the_stip": {
            "field_list": [],
            "remove_list": []
        }
    },
    "partner_configs": {
        "prod": [
            {
                "partner_id": "fe27893b-9b0e-4127-ac75-8111b05438ee",
                "end_date": "2023-01-31"
            },
            {
                "partner_id": "b069f106-c5a2-4700-8fff-57ace090a23e",
                "end_date": "2023-02-28"
            },
            {
                "partner_id": "d91882d7-bc77-48ad-a1d7-2cafaeaf0f61",
                "end_date": "2023-02-28"
            }
        ],
        "staging": [
            {
                "partner_id": "e24e3220-4099-4191-8d3b-f3e4f4d94432",
                "end_date": "2023-01-31"
            }
        ],
        "poc": []
    }
}
