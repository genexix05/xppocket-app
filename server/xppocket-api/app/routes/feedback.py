"""Anonymous crash and feedback reports from the iOS app."""

from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from pathlib import Path

from app.config import settings
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

router = APIRouter(prefix="/v1", tags=["feedback"])


class FeedbackRequest(BaseModel):
    app_name: str = Field(max_length=64)
    app_version: str = Field(max_length=32)
    build: str = Field(max_length=32)
    commit: str = Field(max_length=64)
    dirty: bool = False
    game_title: str | None = Field(default=None, max_length=256)
    error_summary: str | None = Field(default=None, max_length=4000)
    log_excerpt: str | None = Field(default=None, max_length=120_000)


class FeedbackResponse(BaseModel):
    id: str
    received_at: str


@router.post("/feedback", response_model=FeedbackResponse)
async def submit_feedback(body: FeedbackRequest) -> FeedbackResponse:
    feedback_dir = settings.feedback_dir
    feedback_dir.mkdir(parents=True, exist_ok=True)

    report_id = uuid.uuid4().hex
    received_at = datetime.now(timezone.utc).isoformat()
    record = {
        "id": report_id,
        "received_at": received_at,
        **body.model_dump(),
    }

    path: Path = feedback_dir / f"{report_id}.json"
    try:
        path.write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding="utf-8")
    except OSError as exc:
        raise HTTPException(status_code=500, detail="Could not store feedback report.") from exc

    return FeedbackResponse(id=report_id, received_at=received_at)
