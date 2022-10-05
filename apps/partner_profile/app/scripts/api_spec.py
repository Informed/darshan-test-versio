import app.schemas.partner_profile_request
from os import path


def start():
    basepath = path.dirname(__file__) + '/../../api-specs'

    filepath = path.abspath(path.join(basepath, 'partner-profile.json'))
    with open(filepath, 'w') as outfile:
        outfile.write(app.schemas.partner_profile_request.PartnerProfileRequest
                         .schema_json(indent=2))

    filepath = path.abspath(path.join(basepath, 'services/analyzeIq.json'))
    with open(filepath, 'w') as outfile:
        outfile.write(app.schemas.analyze_iq.AnalyzeIq.schema_json(indent=2))

    filepath = path.abspath(path.join(basepath, 'services/collectIq.json'))
    with open(filepath, 'w') as outfile:
        outfile.write(app.schemas.collect_iq.CollectIq.schema_json(indent=2))

    filepath = path.abspath(path.join(basepath, 'services/metadata.json'))
    with open(filepath, 'w') as outfile:
        outfile.write(app.schemas.metadata.Metadata.schema_json(indent=2))

    filepath = path.abspath(path.join(basepath, 'services/monitoringAlerting.json'))
    with open(filepath, 'w') as outfile:
        outfile.write(app.schemas.monitoring_alerting.MonitoringAlerting
                         .schema_json(indent=2))

    filepath = path.abspath(path.join(basepath, 'services/redaction.json'))
    with open(filepath, 'w') as outfile:
        outfile.write(app.schemas.redaction.Redaction.schema_json(indent=2))

    filepath = path.abspath(path.join(basepath, 'services/serialization.json'))
    with open(filepath, 'w') as outfile:
        outfile.write(app.schemas.serialization.Serialization.schema_json(indent=2))

    filepath = path.abspath(path.join(basepath, 'services/stipulationCreationRules.json'))
    with open(filepath, 'w') as outfile:
        outfile.write(app.schemas.stipulation_creation_rules.StipulationCreationRules.schema_json(indent=2))

    filepath = path.abspath(path.join(basepath, 'services/stipulationVerificationConfig.json'))
    with open(filepath, 'w') as outfile:
        outfile.write(app.schemas.stipulation_verification_config.StipulationVerificationConfig.schema_json(indent=2))

    filepath = path.abspath(path.join(basepath, 'services/verifyIq.json'))
    with open(filepath, 'w') as outfile:
        outfile.write(app.schemas.verify_iq.VerifyIq.schema_json(indent=2))

    print('Api Spec generation completed!')
