import app.schemas.v1.address

from pydantic import BaseModel
from typing import (
    Optional
)


class DealerInfo(BaseModel):
    dealerId: str
    dealerName: str
    dealerPhone: Optional[str]
    address: Optional[app.schemas.v1.address.Address]
