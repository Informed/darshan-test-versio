import app.schemas.basicAuth
import app.schemas.oAuth
from pydantic import BaseModel
from typing import (
    List, Optional, Union
)


class AnalyzeIq(BaseModel):
    webhookReturnAllDocs: Optional[bool]
    forcedStipulations: Optional[List[str]]
    webhookSetting: Optional[Union[app.schemas.basicAuth.BasicAuth, app.schemas.oAuth.OAuth]]
