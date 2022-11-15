from enum import Enum


class EmploymentType(str, Enum):
    ACTIVE_MILITARY = "ActiveMilitary"
    EMPLOYED = "Employed"
    OTHER = "Other"
    RETIRED = "Retired"
    RETIRED_MILITARY = "RetiredMilitary"
    SELF_EMPLOYED = "SelfEmployed"
    STUDENT = "Student"
    UNEMPLOYED = "Unemployed"
