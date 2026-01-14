

from fastapi import APIRouter, Depends, HTTPException, status

from shared.players import (
    create_player,
    delete_player_if_orphaned,
    list_available_players,
)
from ..schemas.player import PlayerAddRequest
from ..dependencies.auth import require_role
from ..schemas.auth import RoleKeyRequest, RoleKeyResponse, UserResponse
from ..schemas.match import (
    CardEventRequest,
    GoalEventRequest,
    MatchAdminResponse,
    MatchPreviewResponse,
    SubstitutionEventRequest,
)
from ..schemas.referee import (
    RefereeAssignmentResponse,
    RefereeAvailabilityRequest,
    RefereeAvailabilityResponse,
    RefereeAvailabilityUpdateRequest,
    RefereeHistoryResponse,
)
from ..schemas.fan import (
    NotificationSettingsRequest,
    NotificationSettingsResponse,
    PlayerIdRequest,
    TeamIdRequest,
)
from ..schemas.teams import TeamAddRequest, TeamResponse, TeamUpdateRequest
from ..schemas.venue import VenueCreateRequest, VenueResponse
from shared.referees import (
    add_referee_availability,
    get_referee_availability,
    get_referee_matches,
    get_referee_history,
    remove_referee_availability,
    replace_referee_availability,
    get_match_slots_without_referee
)
from shared.matches import (
    add_card_event,
    add_goal_event,
    add_substitution_event,
    cancel_match,
    finalize_match,
    list_matches_in_progress,
    mark_match_postponed,
)
from shared.rankings import get_rankings_with_tiebreak
from shared.teams import (
    add_player,
    create_team,
    get_team_by_manager_id,
    list_team_players,
    remove_player_from_team,
    update_team,
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
from shared.venues import add_venue, list_venues, update_venue, delete_venue, list_venue_matches

from helper.players import populate_players

from worker.tasks.scheduler import run_scheduler_job
from worker.tasks.matchGeneretor import run_generate_matches_job
from helper.redis import MATCHES_GEN_JOB_ID, SCHEDULER_JOB_ID, _ACTIVE_STATUSES, _get_queue

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
        "players": team.get("players", []),
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
        "players": [],
    }


@router.put("/manager/team", response_model=TeamResponse)
async def update_team_info(
    payload: TeamUpdateRequest,
    current_user: UserResponse = Depends(require_role("MANAGER")),
):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Manager profile missing")
    team = await get_team_by_manager_id(current_user["person_id"])
    if not team:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    updated = await update_team(
        team["id"],
        payload.division if payload.division is not None else team["division"],
        payload.name if payload.name is not None else team["name"],
        payload.short_name if payload.short_name is not None else team["short_name"],
        payload.color_primary if payload.color_primary is not None else team["color_primary"],
        payload.color_secondary if payload.color_secondary is not None else team["color_secondary"],
    )
    if not updated:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Team update failed")
    players = await list_team_players(updated["id"])
    return {
        "id": updated["id"],
        "division": updated["division"],
        "name": updated["name"],
        "manager_id": updated["manager_id"],
        "short_name": updated["short_name"],
        "color_primary": updated["color_primary"],
        "color_secondary": updated["color_secondary"],
        "players": players,
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
    if payload.player_id:
        player_id = payload.player_id
    else:
        if not payload.first_name or not payload.last_name:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Missing player name")
        player = await create_player(payload.first_name, payload.last_name)
        player_id = player["id"]
    row = await add_player(player_id, team["id"], payload.number)
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


@router.get("/manager/team/players/available")
async def list_available_team_players_endpoint(
    current_user: UserResponse = Depends(require_role("MANAGER")),
):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Manager profile missing")
    team = await get_team_by_manager_id(current_user["person_id"])
    if not team:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    return await list_available_players(team["id"])

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
    if row.get("locked"):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Availability cannot be removed within 24 hours of the match",
        )
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Availability not found")
    return {"status": "deleted"}


@router.get("/referee/openslots")
async def list_referee_openslots(current_user: UserResponse = Depends(require_role("REFEREE"))):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Referee profile missing")
    rows = await get_match_slots_without_referee(current_user["person_id"])
    return rows


@router.get("/referee/matches", response_model=list[RefereeAssignmentResponse])
async def list_referee_matches(current_user: UserResponse = Depends(require_role("REFEREE"))):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Referee profile missing")
    rows = await get_referee_matches(current_user["person_id"])
    return rows


@router.get("/referee/history", response_model=list[RefereeHistoryResponse])
async def list_referee_history(current_user: UserResponse = Depends(require_role("REFEREE"))):
    if not current_user.get("person_id"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Referee profile missing")
    rows = await get_referee_history(current_user["person_id"])
    return rows


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


@router.get("/admin/console/matches", response_model=list[MatchAdminResponse])
async def list_admin_matches_in_progress(
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    rows = await list_matches_in_progress()
    return [
        {
            "id": row["id"],
            "division": row["division"],
            "status": row["status"],
            "home_team_id": row["home_team_id"],
            "away_team_id": row["away_team_id"],
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


@router.post("/admin/console/matches/{match_id}/goal")
async def admin_add_goal(
    match_id: int,
    payload: GoalEventRequest,
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    row = await add_goal_event(
        match_id,
        payload.team_id,
        payload.player_id,
        payload.minute,
        payload.is_own_goal,
    )
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    return row


@router.post("/admin/console/matches/{match_id}/card")
async def admin_add_card(
    match_id: int,
    payload: CardEventRequest,
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    row = await add_card_event(
        match_id,
        payload.team_id,
        payload.player_id,
        payload.minute,
        payload.card_type,
        payload.reason,
    )
    if not row:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Card not created")
    return row


@router.post("/admin/console/matches/{match_id}/substitution")
async def admin_add_substitution(
    match_id: int,
    payload: SubstitutionEventRequest,
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    row = await add_substitution_event(
        match_id,
        payload.team_id,
        payload.player_out_id,
        payload.player_in_id,
        payload.minute,
    )
    if not row:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Substitution not created")
    return row


@router.post("/admin/console/matches/{match_id}/finalize")
async def admin_finalize_match(
    match_id: int,
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    row = await finalize_match(match_id)
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    return row


@router.get("/admin/console/rankings/{division}")
async def admin_get_rankings(
    division: int,
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    return await get_rankings_with_tiebreak(division)


@router.get("/admin/console/teams/{team_id}/players")
async def admin_list_team_players(
    team_id: int,
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    return await list_team_players(team_id)

@router.get("/admin/venues", response_model=list[VenueResponse])
async def admin_list_venues(
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    return await list_venues()


@router.post("/admin/venues", response_model=VenueResponse, status_code=status.HTTP_201_CREATED)
async def admin_add_venue(
    payload: VenueCreateRequest,
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    venue = await add_venue(payload.name, payload.address, payload.courts_count)
    if not venue:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Venue creation failed")
    return venue


@router.put("/admin/venues/{venue_id}", response_model=VenueResponse)
async def admin_update_venue(
    venue_id: int,
    payload: VenueCreateRequest,
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    venue = await update_venue(venue_id, payload.name, payload.address, payload.courts_count)
    if not venue:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Venue not found")
    return venue


@router.delete("/admin/venues/{venue_id}")
async def admin_delete_venue(
    venue_id: int,
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    deleted = await delete_venue(venue_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Venue not found")
    return {"status": "deleted", "id": deleted["id"]}


@router.get("/admin/venues/{venue_id}/matches")
async def admin_list_venue_matches(
    venue_id: int,
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    return await list_venue_matches(venue_id)

@router.post("/admin/matches/generate")
async def admin_generate_matches(
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
                detail="Match generation already running",
            )
        existing_job.delete()

    job = queue.enqueue(run_generate_matches_job, job_id=MATCHES_GEN_JOB_ID)
    return {"job_id": job.id, "status": "queued"}

@router.get("/admin/matches/generate/status")
async def admin_generate_matches_status(
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    queue = _get_queue()
    try:
        job = Job.fetch(MATCHES_GEN_JOB_ID, connection=queue.connection)
    except Exception as exc:
        raise HTTPException(status_code=404, detail="Job not found") from exc
    return {
        "job_id": job.id,
        "status": job.get_status(),
        "enqueued_at": job.enqueued_at,
        "started_at": job.started_at,
        "ended_at": job.ended_at,
        "result": job.result,
    }


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

@router.post("/admin/scheduler/run")
async def scheduler_endpoint(
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    queue = _get_queue()
    try:
        existing_job = Job.fetch(SCHEDULER_JOB_ID, connection=queue.connection)
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

    job = queue.enqueue(run_scheduler_job, job_id=SCHEDULER_JOB_ID)
    return {"job_id": job.id, "status": "queued"}


@router.post("/admin/scheduler/matches/{match_id}/cancel")
async def admin_cancel_match(
    match_id: int,
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    row = await cancel_match(match_id)
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    return row


@router.post("/admin/scheduler/matches/{match_id}/postpone")
async def admin_postpone_match(
    match_id: int,
    current_user: UserResponse = Depends(require_role("ADMIN")),
):
    row = await mark_match_postponed(match_id)
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    return row
