from pydantic import BaseModel
from typing import (
    Optional
)


class OAuthSettings(BaseModel):
    username: Optional[str]
    password: Optional[str]
    endpoint: Optional[str]
    custom_attributes: Optional[dict]


class OAuth(BaseModel):
    authScheme: Optional[str]
    oauthSettings: Optional[OAuthSettings]
