from pydantic import BaseModel
from typing import (
    Optional
)


class MonitoringAlerting(BaseModel):
    failureRateThreshold: Optional[float]
    responseTimeThreshold: Optional[int]
    minimumRequestThreshold: Optional[int]
