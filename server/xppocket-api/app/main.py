"""XP Pocket community API — layouts catalog + cloud saves (Pro)."""

from app.config import settings
from app.db import init_db
from app.routes import account, admin, auth, feedback, health, layouts, saves, subscription
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="XP Pocket API",
    description="Community layout marketplace and cloud save sync for XP Pocket.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins if origins != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(auth.router)
app.include_router(account.router)
app.include_router(admin.router)
app.include_router(layouts.router)
app.include_router(saves.router)
app.include_router(feedback.router)
app.include_router(subscription.router)


@app.on_event("startup")
async def on_startup() -> None:
    settings.ensure_dirs()
    await init_db()
    await layouts.seed_if_empty()
