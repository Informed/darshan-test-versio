from enum import Enum


class VehicleConditionType(str, Enum):
    CERTIFIED_USED = "CertifiedUsed"
    NEW = "New"
    USED = "Used"
