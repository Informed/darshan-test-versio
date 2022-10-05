import app.schemas.parent_partner
from pydantic import BaseModel
from typing import (
    Optional
)


class Metadata(BaseModel):
    name: Optional[str]
    email: Optional[str]
    address: Optional[str]
    status: Optional[str]
    password: Optional[str]
    tollFreeNumber: Optional[str]
    lenderType: Optional[str]
    loanType: Optional[str]
    lenderless: Optional[bool]
    parentPartner: Optional[app.schemas.parent_partner.ParentPartner]
