from enum import Enum


class ResidenceType(str, Enum):
    FAMILY = "Family"
    MORTGAGE = "Mortgage"
    OTHER = "Other"
    OWN = "Own"
    RENT = "Rent"
