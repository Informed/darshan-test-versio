from pydantic import BaseModel
from typing import (
    Optional
)


class StipulationVerificationConfig(BaseModel):
    f3Partner: Optional[str]
    lastUpdated: Optional[str]
    rules: Optional[dict]
