from typing import Optional

from pydantic import BaseModel

from .player import PlayerResponse


class TeamResponse(BaseModel):
    id: int
    division: int
    name: str
    manager_id: Optional[int] = None
    short_name: Optional[str] = None
    color_primary: Optional[str] = None
    color_secondary: Optional[str] = None
    players: list[PlayerResponse] = []


class TeamAddRequest(BaseModel):
    division: int
    name: str
    short_name: Optional[str] = None
    color_primary: Optional[str] = None
    color_secondary: Optional[str] = None


class TeamUpdateRequest(BaseModel):
    division: Optional[int] = None
    name: Optional[str] = None
    short_name: Optional[str] = None
    color_primary: Optional[str] = None
    color_secondary: Optional[str] = None
