from datetime import datetime, timezone
from typing import Annotated

import jwt
from fastapi import Depends, Header, HTTPException

from app.auth.jwt_tokens import decode_access_token
from app.db import fetch_account_by_id


def _parse_iso(raw: str) -> datetime:
    if raw.endswith("Z"):
        raw = raw[:-1] + "+00:00"
    return datetime.fromisoformat(raw)


async def require_account(
    authorization: Annotated[str | None, Header()] = None,
) -> dict:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing Bearer token")
    raw = authorization.removeprefix("Bearer ").strip()
    if not raw:
        raise HTTPException(status_code=401, detail="Missing Bearer token")
    try:
        payload = decode_access_token(raw)
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired session") from None
    account_id = payload.get("sub")
    if not account_id:
        raise HTTPException(status_code=401, detail="Invalid session payload")
    account = await fetch_account_by_id(account_id)
    if not account:
        raise HTTPException(status_code=401, detail="Account not found")
    return account


def account_has_pro(account: dict) -> bool:
    pro_until = account.get("pro_until")
    if not pro_until:
        return False
    try:
        expiry = _parse_iso(pro_until)
    except ValueError:
        return False
    return expiry > datetime.now(timezone.utc)


def entitlements_for(account: dict) -> dict[str, bool]:
    pro = account_has_pro(account)
    return {
        "pro": pro,
        "cloud_save": pro,
        "cheats": pro,
        "fast_forward": pro,
        "community_premium": pro,
    }


async def require_pro(account: dict = Depends(require_account)) -> dict:
    if not account_has_pro(account):
        raise HTTPException(
            status_code=402,
            detail="XP Pocket Pro required for this feature.",
        )
    return account
