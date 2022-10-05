from pydantic import BaseModel
from typing import (
    List, Optional
)


class Redaction(BaseModel):
    expiryDays: Optional[str]
    documentTypes: Optional[List[str]]
