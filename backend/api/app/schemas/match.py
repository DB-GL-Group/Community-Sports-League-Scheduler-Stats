from typing import Optional

from pydantic import BaseModel


class Match(BaseModel):
    id: int
    division: int
    home_team_id: int
    away_team_id: int
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
    home_team: dict
    away_team: dict
    home_score: int
    away_score: int
    start_time: Optional[str] = None
    current_time: str
    main_referee: str
    venue: Optional[str] = None
    notes: str


class MatchAdminResponse(BaseModel):
    id: int
    division: int
    status: str
    home_team_id: int
    away_team_id: int
    home_team: str
    away_team: str
    home_score: int
    away_score: int
    start_time: Optional[str] = None


class GoalEventRequest(BaseModel):
    team_id: int
    player_id: int
    minute: Optional[int] = None
    is_own_goal: bool = False


class CardEventRequest(BaseModel):
    team_id: int
    player_id: int
    minute: Optional[int] = None
    card_type: str
    reason: Optional[str] = None


class SubstitutionEventRequest(BaseModel):
    team_id: int
    player_out_id: int
    player_in_id: int
    minute: Optional[int] = None

