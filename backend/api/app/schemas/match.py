from typing import Optional

from pydantic import BaseModel


class Match(BaseModel):
    id: int
    division_id: int
    slot_id: int
    home_team_id: int
    away_team_id: int
    main_referee_id: int
    status: str
    home_score: Optional[int] = None
    away_score: Optional[int] = None
    notes: Optional[str] = None
