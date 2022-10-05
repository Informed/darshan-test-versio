from pydantic import BaseModel
from typing import (
    Optional
)


class StipulationCreationRules(BaseModel):
    rules: Optional[dict]
