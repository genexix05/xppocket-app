from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.auth.deps import entitlements_for, require_account
from app.config import settings
from app.db import delete_account

router = APIRouter(prefix="/v1/account", tags=["account"])


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


@router.get("/me", response_model=AccountResponse)
async def get_account_me(account: dict = Depends(require_account)) -> AccountResponse:
    entitlements = entitlements_for(account)
    return AccountResponse(
        id=account["id"],
        email=account.get("email"),
        entitlements=EntitlementsResponse(**entitlements),
    )


@router.delete("/me")
async def delete_account_me(account: dict = Depends(require_account)) -> dict[str, bool]:
    """Apple Guideline 5.1.1(v): account deletion from inside the app."""
    storage_paths = await delete_account(account["id"])
    for relative in storage_paths:
        path = settings.saves_dir / relative
        try:
            if path.is_file():
                path.unlink()
            # Remove empty per-account directories when possible.
            parent = path.parent
            if parent != settings.saves_dir and parent.is_dir():
                try:
                    next(parent.iterdir())
                except StopIteration:
                    parent.rmdir()
        except OSError:
            # Best-effort file cleanup; DB row is already gone.
            pass
    return {"deleted": True}
