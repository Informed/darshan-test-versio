from pydantic import BaseModel
from typing import (
    List, Optional
)


class Serialization(BaseModel):
    apiVersion: Optional[str]
    withBeta: Optional[bool]
    useSecureUrls: Optional[bool]
    secureUrlExpiration: Optional[dict]
    disableSerializedUrls: Optional[bool]
    downloadsIpWhitelist: Optional[List[str]]
