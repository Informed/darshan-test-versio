import app.schemas.v1.enums.address_state

from pydantic import BaseModel
from typing import (
    Optional
)


class Address(BaseModel):
    streetAddress: Optional[str]
    city: Optional[str]
    state: Optional[app.schemas.v1.enums.address_state.AddressState]
    zip: Optional[str]
