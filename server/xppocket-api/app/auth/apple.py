"""Verify Sign in with Apple identity tokens."""

import jwt
from jwt import PyJWKClient

from app.config import settings

_jwks_client: PyJWKClient | None = None


def _client() -> PyJWKClient:
    global _jwks_client
    if _jwks_client is None:
        _jwks_client = PyJWKClient("https://appleid.apple.com/auth/keys")
    return _jwks_client


def verify_identity_token(token: str) -> dict:
    signing_key = _client().get_signing_key_from_jwt(token)
    return jwt.decode(
        token,
        signing_key.key,
        algorithms=["RS256"],
        audience=settings.apple_client_audiences,
        issuer="https://appleid.apple.com",
    )
