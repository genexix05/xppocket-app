from typing import Annotated

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.auth.apple import verify_identity_token
from app.auth.jwt_tokens import create_access_token
from app.auth.deps import entitlements_for
from app.db import upsert_apple_account

router = APIRouter(prefix="/v1/auth", tags=["auth"])


class AppleSignInRequest(BaseModel):
    identity_token: str = Field(min_length=32)


class EntitlementsResponse(BaseModel):
    pro: bool
    cloud_save: bool
    cheats: bool
    fast_forward: bool
    community_premium: bool


class AccountResponse(BaseModel):
    id: str
    email: str | None = None
    entitlements: EntitlementsResponse


class AppleSignInResponse(BaseModel):
    access_token: str
    expires_at: str
    account: AccountResponse


class DevSignInRequest(BaseModel):
    device_label: str = Field(default="simulator", min_length=1, max_length=80)


@router.post("/dev", response_model=AppleSignInResponse)
async def sign_in_dev(body: DevSignInRequest) -> AppleSignInResponse:
    from app.config import settings

    if not settings.dev_auth:
        raise HTTPException(status_code=403, detail="Dev sign-in is disabled on this server")
    label = body.device_label.strip()
    apple_sub = f"dev:{label}"
    email = f"{label}@dev.xppocket.local"
    account = await upsert_apple_account(apple_sub=apple_sub, email=email)
    token, expires = create_access_token(account_id=account["id"], apple_sub=apple_sub)
    entitlements = entitlements_for(account)
    return AppleSignInResponse(
        access_token=token,
        expires_at=expires.isoformat(),
        account=AccountResponse(
            id=account["id"],
            email=account.get("email"),
            entitlements=EntitlementsResponse(**entitlements),
        ),
    )


@router.post("/apple", response_model=AppleSignInResponse)
async def sign_in_with_apple(body: AppleSignInRequest) -> AppleSignInResponse:
    try:
        claims = verify_identity_token(body.identity_token)
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Invalid Apple identity token") from exc
    apple_sub = claims.get("sub")
    if not apple_sub:
        raise HTTPException(status_code=401, detail="Apple token missing subject")
    email = claims.get("email")
    account = await upsert_apple_account(apple_sub=apple_sub, email=email)
    token, expires = create_access_token(
        account_id=account["id"], apple_sub=apple_sub
    )
    entitlements = entitlements_for(account)
    return AppleSignInResponse(
        access_token=token,
        expires_at=expires.isoformat(),
        account=AccountResponse(
            id=account["id"],
            email=account.get("email"),
            entitlements=EntitlementsResponse(**entitlements),
        ),
    )
