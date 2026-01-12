from typing import Optional

from pydantic import BaseModel


class TeamResponse(BaseModel):
    id: int
    division: int
    name: str
    manager_id: Optional[int] = None
    short_name: Optional[str] = None
    color_primary: Optional[str] = None
    color_secondary: Optional[str] = None


class TeamAddRequest(BaseModel):
    division: int
    name: str
    short_name: Optional[str] = None
    color_primary: Optional[str] = None
    color_secondary: Optional[str] = None

