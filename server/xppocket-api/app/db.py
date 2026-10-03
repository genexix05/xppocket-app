import uuid
from datetime import datetime, timedelta, timezone

import aiosqlite

from app.config import settings

_SCHEMA = """
CREATE TABLE IF NOT EXISTS layouts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    author TEXT NOT NULL DEFAULT '',
    tags TEXT NOT NULL DEFAULT '',
    pack_filename TEXT NOT NULL,
    preview_url TEXT,
    downloads INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS save_accounts (
    id TEXT PRIMARY KEY,
    apple_sub TEXT UNIQUE,
    email TEXT,
    pro_until TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS save_blobs (
    id TEXT PRIMARY KEY,
    account_id TEXT NOT NULL,
    game_key TEXT NOT NULL,
    game_title TEXT NOT NULL DEFAULT '',
    size_bytes INTEGER NOT NULL DEFAULT 0,
    checksum_sha256 TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    revision INTEGER NOT NULL DEFAULT 1,
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(account_id, game_key),
    FOREIGN KEY (account_id) REFERENCES save_accounts(id)
);
"""


async def init_db() -> None:
    async with aiosqlite.connect(settings.db_path) as db:
        await db.executescript(_SCHEMA)
        try:
            await db.execute("ALTER TABLE save_accounts ADD COLUMN pro_until TEXT")
        except aiosqlite.OperationalError:
            pass
        await db.commit()


async def fetch_account_by_id(account_id: str) -> dict | None:
    async with aiosqlite.connect(settings.db_path) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            "SELECT * FROM save_accounts WHERE id = ?", (account_id,)
        )
        row = await cursor.fetchone()
        return dict(row) if row else None


async def fetch_account_by_apple_sub(apple_sub: str) -> dict | None:
    async with aiosqlite.connect(settings.db_path) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            "SELECT * FROM save_accounts WHERE apple_sub = ?", (apple_sub,)
        )
        row = await cursor.fetchone()
        return dict(row) if row else None


async def upsert_apple_account(*, apple_sub: str, email: str | None) -> dict:
    existing = await fetch_account_by_apple_sub(apple_sub)
    now = datetime.now(timezone.utc).isoformat()
    async with aiosqlite.connect(settings.db_path) as db:
        if existing:
            await db.execute(
                "UPDATE save_accounts SET email = COALESCE(?, email) WHERE apple_sub = ?",
                (email, apple_sub),
            )
            await db.commit()
            return (await fetch_account_by_apple_sub(apple_sub)) or existing
        account_id = str(uuid.uuid4())
        await db.execute(
            """
            INSERT INTO save_accounts (id, apple_sub, email, created_at)
            VALUES (?, ?, ?, ?)
            """,
            (account_id, apple_sub, email, now),
        )
        await db.commit()
    account = await fetch_account_by_id(account_id)
    assert account
    return account


async def fetch_save_blob(account_id: str, game_key: str) -> dict | None:
    async with aiosqlite.connect(settings.db_path) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            """
            SELECT * FROM save_blobs
            WHERE account_id = ? AND game_key = ?
            """,
            (account_id, game_key),
        )
        row = await cursor.fetchone()
        return dict(row) if row else None


async def list_save_blobs(account_id: str) -> list[dict]:
    async with aiosqlite.connect(settings.db_path) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            """
            SELECT game_key, game_title, revision, size_bytes, updated_at, checksum_sha256
            FROM save_blobs
            WHERE account_id = ?
            ORDER BY updated_at DESC
            """,
            (account_id,),
        )
        rows = await cursor.fetchall()
        return [dict(row) for row in rows]


async def upsert_save_blob(
    *,
    account_id: str,
    game_key: str,
    game_title: str,
    size_bytes: int,
    checksum_sha256: str,
    storage_path: str,
) -> dict:
    existing = await fetch_save_blob(account_id, game_key)
    now = datetime.now(timezone.utc).isoformat()
    async with aiosqlite.connect(settings.db_path) as db:
        if existing:
            revision = int(existing["revision"]) + 1
            await db.execute(
                """
                UPDATE save_blobs
                SET game_title = ?, size_bytes = ?, checksum_sha256 = ?,
                    storage_path = ?, revision = ?, updated_at = ?
                WHERE account_id = ? AND game_key = ?
                """,
                (
                    game_title,
                    size_bytes,
                    checksum_sha256,
                    storage_path,
                    revision,
                    now,
                    account_id,
                    game_key,
                ),
            )
        else:
            revision = 1
            blob_id = str(uuid.uuid4())
            await db.execute(
                """
                INSERT INTO save_blobs
                (id, account_id, game_key, game_title, size_bytes, checksum_sha256,
                 storage_path, revision, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    blob_id,
                    account_id,
                    game_key,
                    game_title,
                    size_bytes,
                    checksum_sha256,
                    storage_path,
                    revision,
                    now,
                ),
            )
        await db.commit()
    blob = await fetch_save_blob(account_id, game_key)
    assert blob
    return blob


async def delete_save_blob(account_id: str, game_key: str) -> bool:
    async with aiosqlite.connect(settings.db_path) as db:
        cursor = await db.execute(
            "DELETE FROM save_blobs WHERE account_id = ? AND game_key = ?",
            (account_id, game_key),
        )
        await db.commit()
        return cursor.rowcount > 0


async def delete_account(account_id: str) -> list[str]:
    """Remove the account and all cloud-save rows.

    Returns relative storage paths so the caller can delete files on disk.
    """
    blobs = await list_save_blobs_full(account_id)
    paths = [str(blob["storage_path"]) for blob in blobs if blob.get("storage_path")]
    async with aiosqlite.connect(settings.db_path) as db:
        await db.execute("DELETE FROM save_blobs WHERE account_id = ?", (account_id,))
        await db.execute("DELETE FROM save_accounts WHERE id = ?", (account_id,))
        await db.commit()
    return paths


async def list_save_blobs_full(account_id: str) -> list[dict]:
    async with aiosqlite.connect(settings.db_path) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            "SELECT * FROM save_blobs WHERE account_id = ?",
            (account_id,),
        )
        rows = await cursor.fetchall()
        return [dict(row) for row in rows]


async def set_pro_until(account_id: str, *, days: int) -> dict | None:
    expiry = datetime.now(timezone.utc) + timedelta(days=max(1, days))
    pro_until = expiry.isoformat()
    async with aiosqlite.connect(settings.db_path) as db:
        cursor = await db.execute(
            "UPDATE save_accounts SET pro_until = ? WHERE id = ?",
            (pro_until, account_id),
        )
        await db.commit()
        if cursor.rowcount == 0:
            return None
    return await fetch_account_by_id(account_id)


async def set_pro_until_iso(account_id: str, *, pro_until: str) -> dict | None:
    async with aiosqlite.connect(settings.db_path) as db:
        cursor = await db.execute(
            "UPDATE save_accounts SET pro_until = ? WHERE id = ?",
            (pro_until, account_id),
        )
        await db.commit()
        if cursor.rowcount == 0:
            return None
    return await fetch_account_by_id(account_id)


async def list_accounts(limit: int = 50) -> list[dict]:
    async with aiosqlite.connect(settings.db_path) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            """
            SELECT id, apple_sub, email, pro_until, created_at
            FROM save_accounts
            ORDER BY created_at DESC
            LIMIT ?
            """,
            (max(1, min(limit, 200)),),
        )
        rows = await cursor.fetchall()
        return [dict(row) for row in rows]

