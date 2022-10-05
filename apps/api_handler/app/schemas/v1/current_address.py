import app.schemas.v1.address

import app.schemas.v1.enums.residence_type

from pydantic import BaseModel
from typing import (
    Optional
)


class CurrentAddress(BaseModel):
    address: Optional[app.schemas.v1.address.Address]
    lengthOfResidenceInMonths: Optional[int]
    residenceType: Optional[app.schemas.v1.enums.residence_type.ResidenceType]
    monthlyHousingCost: Optional[int]
