from typing import Optional

from pydantic import BaseModel


class PlayerAddRequest(BaseModel):
    player_id: Optional[int] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    number: int
    team_id: int


class PlayerResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    number: Optional[int] = None

