from pydantic import BaseModel
from typing import (
    Optional
)


class ParentPartner(BaseModel):
    id: Optional[str]
    name: Optional[str]
