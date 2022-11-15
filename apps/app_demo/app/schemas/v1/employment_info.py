import app.schemas.v1.enums.employment_type
import app.schemas.v1.enums.income_period_type

from pydantic import BaseModel
from typing import (
    Optional
)


class Income(BaseModel):
    period: app.schemas.v1.enums.income_period_type.IncomePeriodType
    amount: float


class EmploymentInfo(BaseModel):
    employmentType: Optional[app.schemas.v1.enums.employment_type.EmploymentType]
    employerName: Optional[str]
    isCurrent: Optional[bool]
    occupation: Optional[str]
    income: Optional[Income]
    hireDate: Optional[str]
    businessPhone: Optional[str]
