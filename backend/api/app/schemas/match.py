from typing import Optional

from pydantic import BaseModel


class Match(BaseModel):
    id: int
    division: int
    home_team_id: int
    away_team_id: int
    main_referee_id: int
    status: str
    home_score: Optional[int] = None
    away_score: Optional[int] = None
    notes: Optional[str] = None
    slot_ids: Optional[list[int]] = None


class MatchPreviewResponse(BaseModel):
    id: int
    division: int
    status: str
    home_team: str
    away_team: str
    home_score: int
    away_score: int
    start_time: Optional[str] = None
    home_primary_color: str
    home_secondary_color: str
    away_primary_color: str
    away_secondary_color: str


class MatchResponse(BaseModel):
    id: int
    division: int
    status: str
    home_team: str
    away_team: str
    home_score: int
    away_score: int
    start_time: Optional[str] = None
    current_time: str
    main_referee: str
    notes: str

    # preview match
    # matchs/previews
    # match/id
