from enum import Enum


class IncomePeriodType(str, Enum):
    BI_WEEKLY = "BiWeekly"
    HOURLY = "Hourly"
    MONTHLY = "Monthly"
    SEMI_MONTHLY = "SemiMonthly"
    WEEKLY = "Weekly"
    YEARLY = "Yearly"
