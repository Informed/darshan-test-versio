import app.schemas.v1.enums.belongs_to
import app.schemas.v1.enums.stipulation_status

from pydantic import BaseModel
from typing import (
    Optional
)


class Stipulation(BaseModel):
    belongTo: Optional[app.schemas.v1.enums.belongs_to.BelongsTo]
    status: Optional[app.schemas.v1.enums.stipulation_status.StipulationStatus]
    waived: Optional[bool]
