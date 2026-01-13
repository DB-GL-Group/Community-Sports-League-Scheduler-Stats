from fastapi import APIRouter, Depends, HTTPException, status

from ..dependencies.auth import get_current_user
from ..schemas.auth import UserResponse
from ..schemas.match import MatchPreviewResponse, MatchResponse
from shared.matches import get_match_details as fetch_match_details
from shared.matches import get_match_previews
from shared.rankings import get_rankings_view

router = APIRouter(prefix="/matches", tags=["matches"])


@router.get("/previews", response_model=list[MatchPreviewResponse])
async def list_match_previews():
    rows = await get_match_previews()
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
            "home_primary_color": row["home_primary_color"],
            "home_secondary_color": row["home_secondary_color"],
            "away_primary_color": row["away_primary_color"],
            "away_secondary_color": row["away_secondary_color"],
        }
        for row in rows
    ]

@router.get("/rankings")
async def list_rankings(division: int = 1):
    return await get_rankings_view(division)

@router.get("/{match_id}", response_model=MatchResponse)
async def get_match_details(match_id: int, current_user: UserResponse = Depends(get_current_user)):
    row = await fetch_match_details(match_id)
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    return {
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
        "current_time": row["current_time"].isoformat()
        if hasattr(row["current_time"], "isoformat")
        else str(row["current_time"]),
        "main_referee": row["main_referee"],
        "venue": row.get("venue"),
        "notes": row["notes"],
    }
