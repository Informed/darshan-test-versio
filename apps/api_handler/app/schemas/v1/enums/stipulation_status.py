from enum import Enum


class StipulationStatus(str, Enum):
    FAIL = "Fail"
    MISSING = "Missing"
    PASS = "Pass"
    READY = "Ready"
    WAIVE = "Waive"
