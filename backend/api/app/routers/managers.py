from fastapi import APIRouter, Depends, HTTPException, status

from ..dependencies.auth import get_current_user
from ..schemas.auth import UserResponse
from ..schemas.teams import TeamRequest, TeamResponse
from shared.teams import create_team, get_team_by_manager_id

router = APIRouter(prefix="/manager", tags=["manager"])


@router.get("/team", response_model=TeamResponse)
async def get_team(current_user: UserResponse = Depends(get_current_user)):
    if "MANAGER" not in current_user["roles"]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Manager role required")
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

@router.post("/team", response_model=TeamResponse, status_code=status.HTTP_201_CREATED)
async def add_team(
    payload: TeamRequest,
    current_user: UserResponse = Depends(get_current_user),
):
    if "MANAGER" not in current_user["roles"]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Manager role required")
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
