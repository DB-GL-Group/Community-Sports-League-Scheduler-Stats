from pydantic import BaseModel
from typing import Optional


class VenueCreateRequest(BaseModel):
    name: str
    address: Optional[str] = None


class VenueResponse(BaseModel):
    id: int
    name: str
    address: Optional[str] = None
