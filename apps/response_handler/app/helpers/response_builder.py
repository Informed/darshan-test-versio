class ResponseBuilder:
    def extraction_response(app_reference_id, document_datas_json, application_id, client):
        response = {}
        response['event_type'] = 'extractions'
        response['application_id'] = application_id
        response['application_reference_id'] = app_reference_id

        documents_hash = {}

        for doc in document_datas_json:
            document_payload = {}
            document_payload['document_id'] = doc['document_id']
            document_payload['files_ids'] = doc['file_ids']
            document_payload['file_reference_ids'] = doc['file_reference_ids']
            document_payload['url'] = client.generate_presigned_url(doc['uri'].replace("s3://", "").split('/', 1)[1], 3600)  # noqa: B950
            document_payload['extracted_data'] = doc['extracted_data']
            if doc['document_type'] in documents_hash.keys():
                documents_hash[doc['document_type']].append(document_payload)
            else:
                documents_hash[doc['document_type']] = [document_payload]

        response['documents'] = documents_hash
        return response

    def stipulation_response(stipulation_json, application_id, app_reference_id):
        response = {}
        response['event_type'] = 'verifications'
        response['application_id'] = application_id
        response['application_reference_id'] = app_reference_id
        # Add data_sources and access verifications layer if stipulation_json is in the new format  # noqa: B950
        if all(key in stipulation_json for key in ('data_sources', 'verifications')):
            response['data_sources'] = stipulation_json['data_sources']
            stipulation_json = stipulation_json['verifications']
        # Less elegant but more explicit way >:)
        # In-place cleanup, remove app/document level stips if serialize is false
        for stip_results in list(stipulation_json.values()):
            for stip_result in stip_results:
                for stip_question_k, stip_question_v in list(stip_result['verification_questions'].items()):  # noqa: B950
                    if stip_question_v['serialize'] is False:
                        del stip_result['verification_questions'][stip_question_k]
                    del stip_question_v['serialize']
                for document_array in list(stip_result['acceptable_documents'].values()):
                    for document in document_array:
                        for doc_question_k, doc_question_v in list(document['document_questions'].items()):  # noqa: B950
                            if doc_question_v['serialize'] is False:
                                del document['document_questions'][doc_question_k]
                            del doc_question_v['serialize']

        response['verifications'] = stipulation_json
        return response
