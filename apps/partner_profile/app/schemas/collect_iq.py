import app.schemas.basicAuth
import app.schemas.oAuth
from pydantic import BaseModel
from typing import (
    Optional, Union
)


class UiTheme(BaseModel):
    color: Optional[dict]
    latLong: Optional[list]
    fullName: Optional[str]
    humanName: Optional[str]
    privacyLink: Optional[str]
    contactUsLink: Optional[str]
    termsOfServiceLink: Optional[str]


class PlaidConfig(BaseModel):
    env: Optional[str]
    secret: Optional[str]
    clientId: Optional[str]
    redirectUri: Optional[str]


class CollectIq(BaseModel):
    subdomain: Optional[str]
    uiTheme: Optional[UiTheme]
    siteType: Optional[str]
    plaidConfig: Optional[PlaidConfig]
    sendSmsImmediately: Optional[bool]
    loginLinkExpiration: Optional[dict]
    sendSmsReminder: Optional[bool]
    sdkPartner: Optional[bool]
    webhookSetting: Optional[Union[app.schemas.basicAuth.BasicAuth, app.schemas.oAuth.OAuth]]
