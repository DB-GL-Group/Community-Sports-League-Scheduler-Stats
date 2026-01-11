from typing import Optional

from pydantic import BaseModel


class TeamIdRequest(BaseModel):
    team_id: int


class PlayerIdRequest(BaseModel):
    player_id: int


class NotificationSettingsRequest(BaseModel):
    email_enabled: Optional[bool] = None
    push_enabled: Optional[bool] = None
    notify_match_start: Optional[bool] = None
    notify_match_result: Optional[bool] = None
    notify_team_news: Optional[bool] = None


class NotificationSettingsResponse(BaseModel):
    email_enabled: bool
    push_enabled: bool
    notify_match_start: bool
    notify_match_result: bool
    notify_team_news: bool
