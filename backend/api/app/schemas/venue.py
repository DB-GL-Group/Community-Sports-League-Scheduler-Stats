from typing import Optional

from pydantic import BaseModel, Field


class VenueCreateRequest(BaseModel):
    name: str
    address: Optional[str] = None
    courts_count: int = Field(1, ge=1)


class VenueResponse(BaseModel):
    id: int
    name: str
    address: Optional[str] = None
    courts_count: int
