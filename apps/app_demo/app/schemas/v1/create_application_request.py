import app.schemas.v1.applicants
import app.schemas.v1.asset
import app.schemas.v1.dealer_info
import app.schemas.v1.stipulations
import app.schemas.v1.vehicle_info

import app.schemas.v1.enums.application_status

from pydantic import BaseModel
from typing import (
    List, Optional
)


class CreateApplicationRequest(BaseModel):
    partnerApplicationId: str
    applicationDate: str
    contractDate: Optional[str]
    applicationStatus: app.schemas.v1.enums.application_status.ApplicationStatus
    applicationType: Optional[str]
    applicants: Optional[app.schemas.v1.applicants.Applicants]
    stipulations: Optional[app.schemas.v1.stipulations.Stipulations]
    vehicleInfo: Optional[app.schemas.v1.vehicle_info.VehicleInfo]
    dealerInfo: Optional[app.schemas.v1.dealer_info.DealerInfo]
    assets: Optional[List[app.schemas.v1.asset.Asset]]
    documentWebhook: Optional[str]
    stipulationWebhook: Optional[str]
    smsSentWebhook: Optional[str]
    smsOptOutWebhook: Optional[str]
    verifyIqActionWebhook: Optional[str]

    class Config:
        use_enum_values = True
