from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import Depends, Header, HTTPException

from app.config import settings


def require_admin(x_admin_key: Annotated[str | None, Header()] = None) -> None:
    if not x_admin_key or x_admin_key != settings.admin_key:
        raise HTTPException(status_code=401, detail="Invalid or missing X-Admin-Key")
