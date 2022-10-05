import app.schemas.v1.enums.asset_type
import app.schemas.v1.enums.belongs_to

from pydantic import BaseModel
from typing import (
    Optional
)


class Asset(BaseModel):
    assetType: Optional[app.schemas.v1.enums.asset_type.AssetType]
    assetHolder: Optional[app.schemas.v1.enums.belongs_to.BelongsTo]
    assetCashOrMarketValueAmount: float
    assetAccountIdentifier: Optional[str]
