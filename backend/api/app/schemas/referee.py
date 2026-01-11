from datetime import datetime

from pydantic import BaseModel


class RefereeAvailabilityRequest(BaseModel):
    slot_id: int


class RefereeAvailabilityUpdateRequest(BaseModel):
    slot_ids: list[int]


class RefereeAvailabilityResponse(BaseModel):
    slot_id: int
    court_id: int
    start_time: datetime
    end_time: datetime
