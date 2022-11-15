import yaml
from jsonpath_ng.ext import parse
import re


configs = {}


def get_config(file_path):
    # Use cached config if initialized
    if file_path in list(configs.keys()):
        return configs[file_path]
    with open(file_path) as stream:
        raw_config = yaml.safe_load(stream)
    # Reconstruct config to a more code-friendly Python dictionary
    # Reconstructed Python Dictionary Example:
    # {
    #     "reconstructed_validations": [
    #         {
    #             'prerequisite': 'jsonpath union',
    #             'requirements': 'jsonpath union'
    #         }
    #     ],
    #     "validations_by_service": {
    #         "classify": [1,2],
    #         "extract": [1,2,3,4]
    #     },
    #     "flows": {
    #         "classify": 'jsonpath union'
    #     }
    # }
    reconstructed_validations, validations_by_service = [], {}
    for validation_index, validation in enumerate(raw_config.get('validations', {})):
        # Build reconstructed_validations list for Reconstructed Python Dictionary
        reconstructed_validation = {}
        prereqs = validation.get('prerequisites')
        if prereqs:
            reconstructed_validation['prerequisites'] = ' | '.join(prereqs)
        reconstructed_validation['required_expressions'] = validation.get('required_expressions')  # noqa: B950
        reconstructed_validations.append(reconstructed_validation)
        # Build validations_by_service for Reconstructed Python dictionary
        for flow in validation.get('flows'):
            if flow in validations_by_service:
                validations_by_service[flow].append(validation_index)
            else:
                validations_by_service[flow] = [validation_index]
    # Build flows for Reconstructed Python Dictionary with JSONPath Union
    config_flows = raw_config.get('flows')
    for flow_name, paths in config_flows.items():
        config_flows[flow_name] = ' | '.join(paths)
    configs[file_path] = {"reconstructed_validations": reconstructed_validations, "validations_by_service": validations_by_service, "flows": config_flows}  # noqa: B950
    return configs[file_path]


def validate_request(config_file_path, request_body, partner_profile):  # noqa: C901
    config = get_config(config_file_path)
    errors, validation_indices = [], set()
    # Populate validation_indices with indices of all required validations   # noqa: B950
    for flow, condition in config.get('flows').items():
        if match(condition, request_body):
            validation_indices.update(set(config["validations_by_service"][flow]))
    # Check each validation_index, append to errors list if validation fails
    for index in validation_indices:
        selected_validation = config.get('reconstructed_validations')[index]
        prereqs = selected_validation.get('prerequisites')
        # If there are no prerequisites or prerequisites match, check if required_expressions match in the request body   # noqa: B950
        if not prereqs or match(prereqs, request_body):
            for required in selected_validation.get('required_expressions'):
                path, requirement_type = list(required.items())[0]
                # Presence Check
                if requirement_type == r"@{PRESENT}":
                    if not match(path, request_body):
                        errors.append(path)
                # PartnerConfig Check
                elif r"@{PARTNERCONFIG}" in requirement_type:
                    non_configured = validate_partner_profile(partner_profile, path, requirement_type, request_body)   # noqa: B950
                    if non_configured:
                        errors.append(f"{path}->{', '.join(non_configured)}")
                # Presence + Value equality check (for future use)
                else:
                    expression = parse(path)
                    if expression.find(request_body) and expression.find(request_body)[0].value != requirement_type:   # noqa: B950
                        errors.append(path)
    return generate_human_readable_response(errors) if errors else None


# Validate if the request body's services/verifications are configured in the partner_profile's services/verifications   # noqa: B950
def validate_partner_profile(partner_profile, key, value, body):
    profile_path = value.split(':')[1]
    partner_configured = build_services_or_verifications_set(profile_path, partner_profile)   # noqa: B950
    requested = build_services_or_verifications_set(key, body)
    return requested.difference(partner_configured)


def build_services_or_verifications_set(path, body):
    selected_list = []
    for match in parse(path).find(body):
        if type(match.value) is str:
            selected_list.append(match.value)
        else:
            selected_list.append(str(match.path))
    return set(selected_list)


# Check if JSONPath exists in the request_body
def match(condition, request_body):
    return bool(parse(condition).find(request_body))


def generate_human_readable_response(errors):
    node_group_regex = 'applicant1|applicant2|vehicle_info|dealer_info'
    partner_profile_checks_regex = 'verifications|services'
    json_error_message = 'The following node(s) are required: '
    partner_profile_error_message = 'The following values are not allowed: '
    error_message = ''
    json_errors, partner_errors = [], []
    for error in errors:
        if re.search(partner_profile_checks_regex, error):
            partner_errors.append(re.sub(r'[^A-Za-z0-9-> ]+', '', error))
        else:
            applicant = re.search(node_group_regex, error)
            json_errors.append(applicant.group(0) + '\'s ' + error.split('.')[-1] if applicant else error.split('.')[-1])  # noqa: B950
    if json_errors:
        error_message += json_error_message + ', '.join(json_errors) + '.'
    if partner_errors:
        error_message += partner_profile_error_message + ', '.join(partner_errors) + '.'
    return error_message
