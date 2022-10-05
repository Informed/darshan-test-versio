from enum import Enum


class ApplicationStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
