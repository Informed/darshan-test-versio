import app.schemas.basicAuth
import app.schemas.oAuth
from pydantic import BaseModel
from typing import (
    Optional, Union
)


class UiTheme(BaseModel):
    logoName: Optional[str]
    logoStyles: Optional[str]
    displayName: Optional[str]
    primaryColor: Optional[dict]
    secondaryColor: Optional[dict]
    quicksightEnabled: Optional[bool]


class VerifyIq(BaseModel):
    subdomain: Optional[str]
    viqSdkTokenSecret: Optional[str]
    uiTheme: Optional[UiTheme]
    providerType: Optional[str]
    userRoles: Optional[dict]
    rolePermissions: Optional[dict]
    ignoreVerifyiqApplicationLimit: Optional[bool]
    showFailDocs: Optional[bool]
    enableRequestDocuments: Optional[bool]
    webhookSetting: Optional[Union[app.schemas.basicAuth.BasicAuth, app.schemas.oAuth.OAuth]]
