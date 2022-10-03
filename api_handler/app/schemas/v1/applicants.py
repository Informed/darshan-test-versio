from pydantic import BaseModel
from typing import (
    Optional
)


class Applicants(BaseModel):
    applicant1: Optional[bool]
    applicant2: Optional[bool]
