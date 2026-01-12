

from fastapi import APIRouter, Depends, HTTPException, status

from shared.players import create_player, delete_player_if_orphaned
from ..schemas.player import PlayerAddRequest
from ..dependencies.auth import require_role
from ..schemas.auth import RoleKeyRequest, RoleKeyResponse, UserResponse
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
from ..schemas.teams import TeamAddRequest, TeamResponse
from shared.referees import (
    add_referee_availability,
    get_referee_availability,
    get_referee_matches,
    remove_referee_availability,
    replace_referee_availability,
    get_match_slots_without_referee
)
from shared.teams import (
    add_player,
    create_team,
    get_team_by_manager_id,
    list_team_players,
    remove_player_from_team,
)
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
from shared.role_keys import create_role_key

from helper.players import populate_players

from worker.tasks.matchGeneretor import generate_matches
from helper.redis import MATCHES_GEN_JOB_ID, _ACTIVE_STATUSES, _get_queue

from fastapi import APIRouter, HTTPException, status
from redis import Redis
from rq import Queue
from rq.job import Job


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
        "id": team["id"],
        "division": team["division"],
        "name": team["name"],
        "manager_id": team["manager_id"],
        "short_name": team["short_name"],
        "color_primary": team["color_primary"],
        "color_secondary": team["color_secondary"],
    }

@router.post("/manager/team", response_model=TeamResponse, status_code=status.HTTP_201_CREATED)
async def add_team(
    payload: TeamAddRequest,
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
        "id": team["id"],
        "division": team["division"],
        "name": team["name"],
        "manager_id": team["manager_id"],
        "short_name": team["short_name"],
        "color_primary": team["color_primary"],
        "color_secondary": team["color_secondary"],
    }

@router.post("/manager/team/players", status_code=status.HTTP_201_CREATED)
async def add_team_player(
    payload: PlayerAddRequest,
    current_user: UserResponse = Depends(require_role("MANAGER")),
):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Manager profile missing")
    team = await get_team_by_manager_id(current_user["person_id"])
    if not team:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    player = await create_player(payload.first_name, payload.last_name)
    row = await add_player(player["id"], team["id"], payload.number)
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
    row = await remove_player_from_team(player_id, team["id"])
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Player not found in team")
    await delete_player_if_orphaned(player_id)
    return {"status": "deleted"}


@router.get("/manager/team/players")
async def list_team_players_endpoint(
    current_user: UserResponse = Depends(require_role("MANAGER")),
):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Manager profile missing")
    team = await get_team_by_manager_id(current_user["person_id"])
    if not team:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    return await list_team_players(team["id"])

#=========== REFEREE ===========#
@router.get("/referee/availability", response_model=list[RefereeAvailabilityResponse])
async def list_referee_availability(current_user: UserResponse = Depends(require_role("REFEREE"))):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Referee profile missing")
    rows = await get_referee_availability(current_user["person_id"])
    return rows


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


@router.get("/referee/openslots")
async def list_referee_availability(current_user: UserResponse = Depends(require_role("REFEREE"))):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Referee profile missing")
    rows = await get_match_slots_without_referee()
    return rows


@router.get("/referee/matches", response_model=list[MatchPreviewResponse])
async def list_referee_matches(current_user: UserResponse = Depends(require_role("REFEREE"))):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Referee profile missing")
    rows = await get_referee_matches(current_user["person_id"])
    return [
        {
            "id": row["id"],
            "division": row["division"],
            "status": row["status"],
            "home_team": row["home_team"],
            "away_team": row["away_team"],
            "home_score": row["home_score"],
            "away_score": row["away_score"],
            "start_time": row["start_time"].isoformat()
            if row.get("start_time") and hasattr(row["start_time"], "isoformat")
            else None,
        }
        for row in rows
    ]


#============= FAN =============#
@router.get("/favorites/teams", response_model=list[int])
async def list_favorite_teams_endpoint(current_user: UserResponse = Depends(require_role("FAN"))):
    rows = await list_favorite_teams(current_user["id"])
    return [row["team_id"] for row in rows]


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
    return [row["team_id"] for row in rows]


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
    return [row["player_id"] for row in rows]


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
        "email_enabled": row["email_enabled"],
        "push_enabled": row["push_enabled"],
        "notify_match_start": row["notify_match_start"],
        "notify_match_result": row["notify_match_result"],
        "notify_team_news": row["notify_team_news"],
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
        "email_enabled": row["email_enabled"],
        "push_enabled": row["push_enabled"],
        "notify_match_start": row["notify_match_start"],
        "notify_match_result": row["notify_match_result"],
        "notify_team_news": row["notify_team_news"],
    }


#=========== ADMIN ===========#
@router.post("/admin/pop_players")
async def populate_players_endpoint(
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    created = await populate_players()
    return {"created": len(created)}


@router.post("/admin/role-keys", response_model=RoleKeyResponse)
async def create_role_key_endpoint(
    payload: RoleKeyRequest,
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    role = payload.role.upper()
    if role == "ADMIN":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Admin keys are not allowed")
    if role not in ("MANAGER", "REFEREE"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Role key only for MANAGER or REFEREE")
    created = await create_role_key(role, current_user["id"])
    if not created:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Key generation failed")
    return {"role": created["role_name"], "key": created["token"]}

@router.post("/admin/generate_matches/run")
async def generate_matches_endpoint(
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    queue = _get_queue()
    try:
        existing_job = Job.fetch(MATCHES_GEN_JOB_ID, connection=queue.connection)
    except Exception:
        existing_job = None

    if existing_job:
        status_name = existing_job.get_status()
        if status_name in _ACTIVE_STATUSES:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Scheduler already running",
            )
        existing_job.delete()

    job = queue.enqueue(generate_matches, job_id=MATCHES_GEN_JOB_ID)
    return {"job_id": job.id, "status": "queued"}
