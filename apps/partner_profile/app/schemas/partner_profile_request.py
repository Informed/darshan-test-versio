import app.schemas.analyze_iq
import app.schemas.collect_iq
import app.schemas.metadata
import app.schemas.monitoring_alerting
import app.schemas.redaction
import app.schemas.serialization
import app.schemas.stipulation_creation_rules
import app.schemas.stipulation_verification_config
import app.schemas.verify_iq

from pydantic import BaseModel
from typing import (
    Optional
)


class PartnerProfileRequest(BaseModel):
    analyzeIq: Optional[app.schemas.analyze_iq.AnalyzeIq]
    collectIq: Optional[app.schemas.collect_iq.CollectIq]
    metadata: Optional[app.schemas.metadata.Metadata]
    monitoringAlerting: Optional[app.schemas.monitoring_alerting.MonitoringAlerting]
    redaction: Optional[app.schemas.redaction.Redaction]
    serialization: Optional[app.schemas.serialization.Serialization]
    stipulationCreationRules: Optional[app.schemas.stipulation_creation_rules.StipulationCreationRules]  # noqa: B950
    stipulationVerificationConfig: Optional[app.schemas.stipulation_verification_config.StipulationVerificationConfig]  # noqa: B950
    verifyIq: Optional[app.schemas.verify_iq.VerifyIq]
