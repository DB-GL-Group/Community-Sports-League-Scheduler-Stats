from pydantic import BaseModel


class PlayerAddRequest(BaseModel):
    first_name: str
    last_name: str
    number: int
    team_id: int

