"""App Store subscription verification for XP Pocket Pro."""

from __future__ import annotations

from datetime import datetime, timezone

from app.auth.deps import entitlements_for, require_account
from app.config import settings
from app.db import fetch_account_by_id, set_pro_until_iso
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

router = APIRouter(prefix="/v1/subscription", tags=["subscription"])


class SubscriptionVerifyRequest(BaseModel):
    product_id: str = Field(max_length=128)
    original_transaction_id: str = Field(max_length=64)
    expires_at: str = Field(max_length=64)
    signed_transaction: str | None = Field(default=None, max_length=32_768)


class SubscriptionVerifyResponse(BaseModel):
    account_id: str
    pro_until: str
    entitlements: dict[str, bool]


def _parse_expiry(raw: str) -> datetime:
    value = raw.strip()
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    parsed = datetime.fromisoformat(value)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


@router.post("/verify", response_model=SubscriptionVerifyResponse)
async def verify_subscription(
    body: SubscriptionVerifyRequest,
    account: dict = Depends(require_account),
) -> SubscriptionVerifyResponse:
    if body.product_id != settings.pro_product_id:
        raise HTTPException(status_code=400, detail="Unknown subscription product.")

    try:
        expiry = _parse_expiry(body.expires_at)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid expires_at timestamp.") from exc

    if expiry <= datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Subscription already expired.")

    updated = await set_pro_until_iso(account["id"], pro_until=expiry.isoformat())
    if not updated:
        raise HTTPException(status_code=404, detail="Account not found.")

    refreshed = await fetch_account_by_id(account["id"]) or updated
    return SubscriptionVerifyResponse(
        account_id=refreshed["id"],
        pro_until=refreshed["pro_until"],
        entitlements=entitlements_for(refreshed),
    )
