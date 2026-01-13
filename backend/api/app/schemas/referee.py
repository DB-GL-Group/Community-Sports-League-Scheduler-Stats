from datetime import datetime

from pydantic import BaseModel


class RefereeAvailabilityRequest(BaseModel):
    slot_id: int


class RefereeAvailabilityUpdateRequest(BaseModel):
    slot_ids: list[int]


class RefereeAvailabilityResponse(BaseModel):
    id: int
    venue: str
    start_time: datetime
    end_time: datetime
    match: str


class RefereeAssignmentResponse(BaseModel):
    id: int
    division: int
    status: str
    home_team: str
    away_team: str
    start_time: datetime
    end_time: datetime
    venue: str


class RefereeHistoryResponse(BaseModel):
    id: int
    division: int
    status: str
    home_team: str
    away_team: str
    home_score: int
    away_score: int
    start_time: datetime
    end_time: datetime
    venue: str
