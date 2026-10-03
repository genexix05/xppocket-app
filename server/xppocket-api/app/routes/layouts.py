from datetime import datetime, timezone
from pathlib import Path
from typing import Annotated

import aiosqlite
from fastapi import APIRouter, Depends, File, Form, HTTPException, Path, UploadFile
from fastapi.responses import FileResponse
from pydantic import BaseModel

from app.auth.admin import require_admin
from app.config import settings

router = APIRouter(prefix="/v1/layouts", tags=["layouts"])


class LayoutSummary(BaseModel):
    id: str
    name: str
    description: str
    author: str
    tags: list[str]
    preview_url: str | None = None
    downloads: int
    updated_at: str


class LayoutDetail(LayoutSummary):
    pack_url: str


class LayoutListResponse(BaseModel):
    layouts: list[LayoutSummary]
    total: int


def _split_tags(raw: str) -> list[str]:
    return [t.strip() for t in raw.split(",") if t.strip()]


async def _fetch_all() -> list[dict]:
    async with aiosqlite.connect(settings.db_path) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            "SELECT * FROM layouts ORDER BY updated_at DESC"
        )
        rows = await cursor.fetchall()
        return [dict(row) for row in rows]


async def _fetch_one(layout_id: str) -> dict | None:
    async with aiosqlite.connect(settings.db_path) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            "SELECT * FROM layouts WHERE id = ?", (layout_id,)
        )
        row = await cursor.fetchone()
        return dict(row) if row else None


def _to_summary(row: dict, base_url: str = "") -> LayoutSummary:
    preview = row.get("preview_url")
    if preview and preview.startswith("/"):
        preview = f"{base_url}{preview}"
    return LayoutSummary(
        id=row["id"],
        name=row["name"],
        description=row["description"],
        author=row["author"],
        tags=_split_tags(row["tags"]),
        preview_url=preview,
        downloads=row["downloads"],
        updated_at=row["updated_at"],
    )


def _pack_filename(layout_id: str) -> str:
    return f"{layout_id}.zip"


async def _read_pack_bytes(pack: UploadFile) -> bytes:
    if pack.content_type not in (
        "application/zip",
        "application/x-zip-compressed",
        "application/octet-stream",
    ):
        raise HTTPException(status_code=400, detail="Pack must be a ZIP file")
    data = await pack.read()
    if len(data) < 32:
        raise HTTPException(status_code=400, detail="Pack file too small")
    return data


async def _write_pack(layout_id: str, data: bytes) -> str:
    filename = _pack_filename(layout_id)
    dest = settings.packs_dir / filename
    dest.write_bytes(data)
    return filename


@router.get("", response_model=LayoutListResponse)
async def list_layouts() -> LayoutListResponse:
    rows = await _fetch_all()
    summaries = [_to_summary(row) for row in rows]
    return LayoutListResponse(layouts=summaries, total=len(summaries))


@router.get("/{layout_id}", response_model=LayoutDetail)
async def get_layout(layout_id: str) -> LayoutDetail:
    row = await _fetch_one(layout_id)
    if not row:
        raise HTTPException(status_code=404, detail="Layout not found")
    summary = _to_summary(row)
    return LayoutDetail(
        **summary.model_dump(),
        pack_url=f"/v1/layouts/{layout_id}/pack",
    )


@router.get("/{layout_id}/pack")
async def download_pack(layout_id: str) -> FileResponse:
    row = await _fetch_one(layout_id)
    if not row:
        raise HTTPException(status_code=404, detail="Layout not found")
    pack_path = settings.packs_dir / row["pack_filename"]
    if not pack_path.is_file():
        raise HTTPException(status_code=404, detail="Pack file missing on server")
    async with aiosqlite.connect(settings.db_path) as db:
        await db.execute(
            "UPDATE layouts SET downloads = downloads + 1 WHERE id = ?",
            (layout_id,),
        )
        await db.commit()
    return FileResponse(
        pack_path,
        media_type="application/zip",
        filename=f"{layout_id}.xppocket-pack.zip",
    )


@router.post("", response_model=LayoutDetail, dependencies=[Depends(require_admin)])
async def upload_layout(
    id: Annotated[str, Form(pattern=r"^[a-z0-9][a-z0-9-]{1,62}$")],
    name: Annotated[str, Form(min_length=1, max_length=80)],
    description: Annotated[str, Form(max_length=500)] = "",
    author: Annotated[str, Form(max_length=80)] = "",
    tags: Annotated[str, Form(max_length=200)] = "",
    pack: UploadFile = File(...),
) -> LayoutDetail:
    existing = await _fetch_one(id)
    if existing:
        raise HTTPException(status_code=409, detail="Layout id already exists")
    data = await _read_pack_bytes(pack)
    filename = await _write_pack(id, data)
    now = datetime.now(timezone.utc).isoformat()
    async with aiosqlite.connect(settings.db_path) as db:
        await db.execute(
            """
            INSERT INTO layouts (id, name, description, author, tags, pack_filename, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (id, name, description, author, tags, filename, now),
        )
        await db.commit()
    row = await _fetch_one(id)
    assert row
    summary = _to_summary(row)
    return LayoutDetail(**summary.model_dump(), pack_url=f"/v1/layouts/{id}/pack")


@router.put("/{layout_id}", response_model=LayoutDetail, dependencies=[Depends(require_admin)])
async def update_layout(
    layout_id: Annotated[str, Path(pattern=r"^[a-z0-9][a-z0-9-]{1,62}$")],
    name: Annotated[str, Form(min_length=1, max_length=80)],
    description: Annotated[str, Form(max_length=500)] = "",
    author: Annotated[str, Form(max_length=80)] = "",
    tags: Annotated[str, Form(max_length=200)] = "",
    pack: UploadFile = File(...),
) -> LayoutDetail:
    existing = await _fetch_one(layout_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Layout not found")
    data = await _read_pack_bytes(pack)
    filename = _pack_filename(layout_id)
    old_filename = existing["pack_filename"]
    if old_filename != filename:
        old_path = settings.packs_dir / old_filename
        if old_path.is_file():
            old_path.unlink()
    await _write_pack(layout_id, data)
    now = datetime.now(timezone.utc).isoformat()
    async with aiosqlite.connect(settings.db_path) as db:
        await db.execute(
            """
            UPDATE layouts
            SET name = ?, description = ?, author = ?, tags = ?,
                pack_filename = ?, updated_at = ?
            WHERE id = ?
            """,
            (name, description, author, tags, filename, now, layout_id),
        )
        await db.commit()
    row = await _fetch_one(layout_id)
    assert row
    summary = _to_summary(row)
    return LayoutDetail(
        **summary.model_dump(), pack_url=f"/v1/layouts/{layout_id}/pack"
    )


async def seed_if_empty() -> None:
    await _seed_layout(
        layout_id="classic-rpg",
        name="Classic RPG",
        description="D-pad izquierda, botones A/B a la derecha. Funciona bien en portrait y landscape.",
        author="XP Pocket",
        tags="default,portrait,landscape",
        seed_filename="classic-rpg.zip",
    )
    await _seed_layout(
        layout_id="gba-pocket",
        name="GBA Pocket",
        description="Marco inferior estilo handheld con sprites para D-pad y botones A/B.",
        author="XP Pocket",
        tags="skin,gba,portrait,landscape",
        seed_filename="gba-pocket.zip",
    )


async def _seed_layout(
    *,
    layout_id: str,
    name: str,
    description: str,
    author: str,
    tags: str,
    seed_filename: str,
) -> None:
    existing = await _fetch_one(layout_id)
    if existing:
        return
    seed_pack = settings.packs_dir.parent / "seed" / seed_filename
    image_seed = Path("/app/seed") / seed_filename
    source = image_seed if image_seed.is_file() else seed_pack
    if not source.is_file():
        return
    dest = settings.packs_dir / seed_filename
    if not dest.is_file():
        dest.write_bytes(source.read_bytes())
    now = datetime.now(timezone.utc).isoformat()
    async with aiosqlite.connect(settings.db_path) as db:
        await db.execute(
            """
            INSERT OR IGNORE INTO layouts
            (id, name, description, author, tags, pack_filename, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (layout_id, name, description, author, tags, seed_filename, now),
        )
        await db.commit()
