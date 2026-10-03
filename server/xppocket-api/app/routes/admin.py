from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel

from app.auth.admin import require_admin
from app.auth.deps import entitlements_for
from app.db import list_accounts, set_pro_until
from app.routes.account import AccountResponse, EntitlementsResponse

router = APIRouter(prefix="/v1/admin", tags=["admin"])


class AccountListItem(BaseModel):
    id: str
    email: str | None = None
    pro_until: str | None = None
    created_at: str


class AccountListResponse(BaseModel):
    accounts: list[AccountListItem]


class GrantProResponse(BaseModel):
    account: AccountResponse
    pro_until: str


@router.get("/accounts", response_model=AccountListResponse, dependencies=[Depends(require_admin)])
async def admin_list_accounts(
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
) -> AccountListResponse:
    rows = await list_accounts(limit=limit)
    return AccountListResponse(
        accounts=[
            AccountListItem(
                id=row["id"],
                email=row.get("email"),
                pro_until=row.get("pro_until"),
                created_at=row["created_at"],
            )
            for row in rows
        ]
    )


@router.post(
    "/accounts/{account_id}/grant-pro",
    response_model=GrantProResponse,
    dependencies=[Depends(require_admin)],
)
async def admin_grant_pro(
    account_id: str,
    days: Annotated[int, Query(ge=1, le=3650)] = 30,
) -> GrantProResponse:
    account = await set_pro_until(account_id, days=days)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    entitlements = entitlements_for(account)
    return GrantProResponse(
        account=AccountResponse(
            id=account["id"],
            email=account.get("email"),
            entitlements=EntitlementsResponse(**entitlements),
        ),
        pro_until=account["pro_until"],
    )
