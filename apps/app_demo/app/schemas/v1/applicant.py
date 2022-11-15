import app.schemas.v1.current_address
import app.schemas.v1.employment_info

from pydantic import BaseModel
from typing import (
    Optional
)


class Applicant(BaseModel):
    firstName: Optional[str]
    lastName: Optional[str]
    email: Optional[str]
    phone: Optional[str]
    ssn: Optional[str]
    dateOfBirth: Optional[str]
    currentAddress: Optional[app.schemas.v1.current_address.CurrentAddress]
    employmentInfo: Optional[app.schemas.v1.employment_info.EmploymentInfo]
