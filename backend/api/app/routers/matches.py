from fastapi import APIRouter, Depends, HTTPException, status

from ..dependencies.auth import get_current_user
from ..schemas.auth import UserResponse
from ..schemas.match import MatchPreviewResponse, MatchResponse
from shared.matches import get_match_details as fetch_match_details
from shared.matches import get_match_previews

router = APIRouter(prefix="/matches", tags=["matches"])


@router.get("/previews", response_model=list[MatchPreviewResponse])
async def list_match_previews():
    rows = await get_match_previews()
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

@router.get("/id", response_model=MatchResponse)
async def get_match_details(match_id: int, current_user: UserResponse = Depends(get_current_user)):
    row = await fetch_match_details(match_id)
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    return {
        "id": row[0],
        "division": row[1],
        "status": row[2],
        "home_team": row[3],
        "away_team": row[4],
        "home_score": row[5],
        "away_score": row[6],
        "start_time": row[7].isoformat() if hasattr(row[7], "isoformat") else str(row[7]),
        "current_time": row[8].isoformat() if hasattr(row[8], "isoformat") else str(row[8]),
        "main_referee": row[9],
        "notes": row[10],
    }
