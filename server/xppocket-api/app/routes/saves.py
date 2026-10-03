import hashlib
import re
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, Header, HTTPException, UploadFile
from fastapi.responses import FileResponse, Response
from pydantic import BaseModel, Field

from app.auth.deps import require_account, require_pro
from app.config import settings
from app.db import delete_save_blob, fetch_save_blob, list_save_blobs, upsert_save_blob

router = APIRouter(prefix="/v1/saves", tags=["saves"])

_GAME_KEY = re.compile(r"^[a-f0-9]{16,64}$")


class SaveStatusResponse(BaseModel):
    signed_in: bool
    cloud_save_enabled: bool
    message: str
    account_id: str | None = None


class SaveListItem(BaseModel):
    game_key: str
    game_title: str
    revision: int
    size_bytes: int
    checksum_sha256: str
    updated_at: str


class SaveListResponse(BaseModel):
    saves: list[SaveListItem]


class SaveUploadResponse(BaseModel):
    game_key: str
    revision: int
    size_bytes: int
    checksum_sha256: str
    updated_at: str


def _validate_game_key(game_key: str) -> str:
    if not _GAME_KEY.match(game_key):
        raise HTTPException(status_code=400, detail="Invalid game_key")
    return game_key


def _blob_path(account_id: str, game_key: str) -> str:
    return f"{account_id}/{game_key}.zip"


@router.get("/status", response_model=SaveStatusResponse)
async def save_status(
    authorization: Annotated[str | None, Header()] = None,
) -> SaveStatusResponse:
    from app.auth.deps import account_has_pro

    if not authorization or not authorization.startswith("Bearer "):
        return SaveStatusResponse(
            signed_in=False,
            cloud_save_enabled=False,
            message="Sign in with Apple to use cloud save.",
        )
    try:
        account = await require_account(authorization=authorization)
    except HTTPException:
        return SaveStatusResponse(
            signed_in=False,
            cloud_save_enabled=False,
            message="Session expired. Sign in again.",
        )
    pro = account_has_pro(account)
    return SaveStatusResponse(
        signed_in=True,
        cloud_save_enabled=pro,
        message="Cloud save is ready." if pro else "XP Pocket Pro unlocks cloud save.",
        account_id=account["id"],
    )


@router.get("", response_model=SaveListResponse)
async def list_saves(account: dict = Depends(require_pro)) -> SaveListResponse:
    rows = await list_save_blobs(account["id"])
    return SaveListResponse(
        saves=[
            SaveListItem(
                game_key=row["game_key"],
                game_title=row["game_title"],
                revision=row["revision"],
                size_bytes=row["size_bytes"],
                checksum_sha256=row["checksum_sha256"],
                updated_at=row["updated_at"],
            )
            for row in rows
        ]
    )


@router.get("/{game_key}")
async def download_save(
    game_key: str,
    account: dict = Depends(require_pro),
    if_none_match: Annotated[str | None, Header()] = None,
) -> Response:
    game_key = _validate_game_key(game_key)
    blob = await fetch_save_blob(account["id"], game_key)
    if not blob:
        raise HTTPException(status_code=404, detail="No cloud save for this game")
    etag = f"\"{blob['revision']}\""
    if if_none_match == etag:
        return Response(status_code=304)
    path = settings.saves_dir / blob["storage_path"]
    if not path.is_file():
        raise HTTPException(status_code=404, detail="Save file missing on server")
    return FileResponse(
        path,
        media_type="application/zip",
        filename=f"{game_key}.zip",
        headers={
            "ETag": etag,
            "X-Save-Revision": str(blob["revision"]),
            "X-Save-Checksum": blob["checksum_sha256"],
        },
    )


@router.put("/{game_key}", response_model=SaveUploadResponse)
async def upload_save(
    game_key: str,
    account: dict = Depends(require_pro),
    game_title: Annotated[str, Form(max_length=120)] = "",
    pack: UploadFile = File(...),
) -> SaveUploadResponse:
    game_key = _validate_game_key(game_key)
    data = await pack.read()
    if len(data) < 8:
        raise HTTPException(status_code=400, detail="Save pack too small")
    if len(data) > 64 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Save pack exceeds 64 MiB limit")
    checksum = hashlib.sha256(data).hexdigest()
    storage_path = _blob_path(account["id"], game_key)
    dest = settings.saves_dir / storage_path
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
    blob = await upsert_save_blob(
        account_id=account["id"],
        game_key=game_key,
        game_title=game_title.strip() or game_key,
        size_bytes=len(data),
        checksum_sha256=checksum,
        storage_path=storage_path,
    )
    return SaveUploadResponse(
        game_key=game_key,
        revision=int(blob["revision"]),
        size_bytes=int(blob["size_bytes"]),
        checksum_sha256=blob["checksum_sha256"],
        updated_at=blob["updated_at"],
    )


@router.delete("/{game_key}")
async def remove_save(
    game_key: str,
    account: dict = Depends(require_pro),
) -> dict[str, bool]:
    game_key = _validate_game_key(game_key)
    blob = await fetch_save_blob(account["id"], game_key)
    if not blob:
        raise HTTPException(status_code=404, detail="No cloud save for this game")
    path = settings.saves_dir / blob["storage_path"]
    if path.is_file():
        path.unlink()
    deleted = await delete_save_blob(account["id"], game_key)
    return {"deleted": deleted}
