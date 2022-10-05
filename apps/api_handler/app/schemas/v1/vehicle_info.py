import app.schemas.v1.enums.vehicle_condition_type

from pydantic import BaseModel
from typing import (
    Optional
)


class VehicleInfo(BaseModel):
    vin: Optional[str]
    make: Optional[str]
    model: Optional[str]
    year: Optional[int]
    trim: Optional[str]
    color: Optional[str]
    odometer: Optional[int]
    condition: Optional[app.schemas.v1.enums.vehicle_condition_type.VehicleConditionType]
    equipments: Optional[str]
