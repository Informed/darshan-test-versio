from pydantic import BaseModel
from typing import (
    Optional
)


class BasicAuth(BaseModel):
    authScheme: Optional[str]
    username: Optional[str]
    password: Optional[str]
    specialHttpHeader: Optional[dict]
