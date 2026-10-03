"""Session tokens issued by XP Pocket API after Apple Sign-In."""

from datetime import datetime, timedelta, timezone

import jwt

from app.config import settings

TOKEN_TYPE = "xppocket_access"


def create_access_token(*, account_id: str, apple_sub: str) -> tuple[str, datetime]:
    expires = datetime.now(timezone.utc) + timedelta(days=settings.jwt_expire_days)
    payload = {
        "sub": account_id,
        "apple_sub": apple_sub,
        "typ": TOKEN_TYPE,
        "exp": expires,
    }
    token = jwt.encode(payload, settings.jwt_secret, algorithm="HS256")
    return token, expires


def decode_access_token(token: str) -> dict:
    payload = jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])
    if payload.get("typ") != TOKEN_TYPE:
        raise jwt.InvalidTokenError("Unexpected token type")
    return payload
