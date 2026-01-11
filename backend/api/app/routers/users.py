from fastapi import APIRouter, Depends, HTTPException, status

from ..dependencies.auth import require_role
from ..schemas.auth import UserResponse
from ..schemas.match import MatchPreviewResponse
from ..schemas.referee import (
    RefereeAvailabilityRequest,
    RefereeAvailabilityResponse,
    RefereeAvailabilityUpdateRequest,
)
from ..schemas.fan import (
    NotificationSettingsRequest,
    NotificationSettingsResponse,
    PlayerIdRequest,
    TeamIdRequest,
)
from ..schemas.teams import TeamRequest, TeamResponse
from shared.referees import (
    add_referee_availability,
    get_referee_availability,
    get_referee_matches,
    remove_referee_availability,
    replace_referee_availability,
)
from shared.teams import add_player, create_team, get_team_by_manager_id, remove_player_from_team
from shared.fans import (
    add_favorite_team,
    add_player_subscription,
    add_team_subscription,
    get_notification_settings,
    list_favorite_teams,
    list_player_subscriptions,
    list_team_subscriptions,
    remove_favorite_team,
    remove_player_subscription,
    remove_team_subscription,
    update_notification_settings,
)

router = APIRouter(prefix="/user", tags=["user"])


#=========== MANAGER ===========#
@router.get("/manager/team", response_model=TeamResponse)
async def get_team(current_user: UserResponse = Depends(require_role("MANAGER"))):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Manager profile missing")
    team = await get_team_by_manager_id(current_user["person_id"])
    if not team:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    return {
        "id": team[0],
        "division": team[1],
        "name": team[2],
        "manager_id": team[3],
        "short_name": team[4],
        "color_primary": team[5],
        "color_secondary": team[6],
    }

@router.post("/manager/team", response_model=TeamResponse, status_code=status.HTTP_201_CREATED)
async def add_team(
    payload: TeamRequest,
    current_user: UserResponse = Depends(require_role("MANAGER")),
):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Manager profile missing")
    team = await create_team(
        payload.division,
        payload.name,
        current_user["person_id"],
        payload.short_name,
        payload.color_primary,
        payload.color_secondary,
    )
    return {
        "id": team[0],
        "division": team[1],
        "name": team[2],
        "manager_id": team[3],
        "short_name": team[4],
        "color_primary": team[5],
        "color_secondary": team[6],
    }

@router.post("/manager/team/players", status_code=status.HTTP_201_CREATED)
async def add_team_player(
    payload: PlayerIdRequest,
    current_user: UserResponse = Depends(require_role("MANAGER")),
):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Manager profile missing")
    team = await get_team_by_manager_id(current_user["person_id"])
    if not team:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    row = await add_player(payload.player_id, team[0])
    if not row:
        return {"status": "exists"}
    return {"status": "created"}


@router.delete("/manager/team/players/{player_id}")
async def remove_team_player(
    player_id: int,
    current_user: UserResponse = Depends(require_role("MANAGER")),
):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Manager profile missing")
    team = await get_team_by_manager_id(current_user["person_id"])
    if not team:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    row = await remove_player_from_team(player_id, team[0])
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Player not found in team")
    return {"status": "deleted"}

#=========== REFEREE ===========#
@router.get("/referee/availability", response_model=list[RefereeAvailabilityResponse])
async def list_referee_availability(current_user: UserResponse = Depends(require_role("REFEREE"))):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Referee profile missing")
    rows = await get_referee_availability(current_user["person_id"])
    return [
        {"slot_id": row[0], "court_id": row[1], "start_time": row[2], "end_time": row[3]}
        for row in rows
    ]

#============= FAN =============#
@router.get("/favorites/teams", response_model=list[int])
async def list_favorite_teams_endpoint(current_user: UserResponse = Depends(require_role("FAN"))):
    rows = await list_favorite_teams(current_user["id"])
    return [row[0] for row in rows]


@router.post("/favorites/teams", status_code=status.HTTP_201_CREATED)
async def add_favorite_team_endpoint(
    payload: TeamIdRequest,
    current_user: UserResponse = Depends(require_role("FAN")),
):
    row = await add_favorite_team(current_user["id"], payload.team_id)
    if not row:
        return {"status": "exists"}
    return {"status": "created"}


@router.delete("/favorites/teams/{team_id}")
async def remove_favorite_team_endpoint(
    team_id: int,
    current_user: UserResponse = Depends(require_role("FAN")),
):
    row = await remove_favorite_team(current_user["id"], team_id)
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Favorite not found")
    return {"status": "deleted"}


@router.get("/subscriptions/teams", response_model=list[int])
async def list_team_subscriptions_endpoint(current_user: UserResponse = Depends(require_role("FAN"))):
    rows = await list_team_subscriptions(current_user["id"])
    return [row[0] for row in rows]


@router.post("/subscriptions/teams", status_code=status.HTTP_201_CREATED)
async def add_team_subscription_endpoint(
    payload: TeamIdRequest,
    current_user: UserResponse = Depends(require_role("FAN")),
):
    row = await add_team_subscription(current_user["id"], payload.team_id)
    if not row:
        return {"status": "exists"}
    return {"status": "created"}


@router.delete("/subscriptions/teams/{team_id}")
async def remove_team_subscription_endpoint(
    team_id: int,
    current_user: UserResponse = Depends(require_role("FAN")),
):
    row = await remove_team_subscription(current_user["id"], team_id)
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")
    return {"status": "deleted"}


@router.get("/subscriptions/players", response_model=list[int])
async def list_player_subscriptions_endpoint(current_user: UserResponse = Depends(require_role("FAN"))):
    rows = await list_player_subscriptions(current_user["id"])
    return [row[0] for row in rows]


@router.post("/subscriptions/players", status_code=status.HTTP_201_CREATED)
async def add_player_subscription_endpoint(
    payload: PlayerIdRequest,
    current_user: UserResponse = Depends(require_role("FAN")),
):
    row = await add_player_subscription(current_user["id"], payload.player_id)
    if not row:
        return {"status": "exists"}
    return {"status": "created"}


@router.delete("/subscriptions/players/{player_id}")
async def remove_player_subscription_endpoint(
    player_id: int,
    current_user: UserResponse = Depends(require_role("FAN")),
):
    row = await remove_player_subscription(current_user["id"], player_id)
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")
    return {"status": "deleted"}


@router.get("/notifications", response_model=NotificationSettingsResponse)
async def get_notification_settings_endpoint(
    current_user: UserResponse = Depends(require_role("FAN")),
):
    row = await get_notification_settings(current_user["id"])
    return {
        "email_enabled": row[0],
        "push_enabled": row[1],
        "notify_match_start": row[2],
        "notify_match_result": row[3],
        "notify_team_news": row[4],
    }


@router.put("/notifications", response_model=NotificationSettingsResponse)
async def update_notification_settings_endpoint(
    payload: NotificationSettingsRequest,
    current_user: UserResponse = Depends(require_role("FAN")),
):
    row = await update_notification_settings(
        current_user["id"],
        email_enabled=payload.email_enabled,
        push_enabled=payload.push_enabled,
        notify_match_start=payload.notify_match_start,
        notify_match_result=payload.notify_match_result,
        notify_team_news=payload.notify_team_news,
    )
    return {
        "email_enabled": row[0],
        "push_enabled": row[1],
        "notify_match_start": row[2],
        "notify_match_result": row[3],
        "notify_team_news": row[4],
    }


@router.post("/referee/availability", status_code=status.HTTP_201_CREATED)
async def add_referee_availability_slot(
    payload: RefereeAvailabilityRequest,
    current_user: UserResponse = Depends(require_role("REFEREE")),
):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Referee profile missing")
    row = await add_referee_availability(current_user["person_id"], payload.slot_id)
    if not row:
        return {"status": "exists"}
    return {"status": "created"}


@router.put("/referee/availability")
async def replace_referee_availability_slots(
    payload: RefereeAvailabilityUpdateRequest,
    current_user: UserResponse = Depends(require_role("REFEREE")),
):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Referee profile missing")
    return await replace_referee_availability(current_user["person_id"], payload.slot_ids)


@router.delete("/referee/availability/{slot_id}")
async def remove_referee_availability_slot(
    slot_id: int,
    current_user: UserResponse = Depends(require_role("REFEREE")),
):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Referee profile missing")
    row = await remove_referee_availability(current_user["person_id"], slot_id)
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Availability not found")
    return {"status": "deleted"}


@router.get("/referee/matches", response_model=list[MatchPreviewResponse])
async def list_referee_matches(current_user: UserResponse = Depends(require_role("REFEREE"))):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Referee profile missing")
    rows = await get_referee_matches(current_user["person_id"])
    return [
        {
            "id": row[0],
            "division": row[1],
            "status": row[2],
            "home_team": row[3],
            "away_team": row[4],
            "home_score": row[5],
            "away_score": row[6],
            "start_time": row[7].isoformat() if hasattr(row[7], "isoformat") else str(row[7]),
        }
        for row in rows
    ]
