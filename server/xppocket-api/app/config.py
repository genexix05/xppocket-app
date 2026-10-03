from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="XPPOCKET_", extra="ignore")

    data_dir: Path = Path("/data")
    admin_key: str = "change-me-on-first-boot"
    cors_origins: str = "*"
    jwt_secret: str = "change-me-jwt-secret-on-first-boot"
    jwt_expire_days: int = 30
    apple_client_id: str = "app.xppocket.player"
    apple_client_id_dev: str = "app.xppocket.player.dev"
    dev_auth: bool = False
    pro_product_id: str = "app.xppocket.player.pro.monthly"

    @property
    def apple_client_audiences(self) -> list[str]:
        ids = [self.apple_client_id.strip(), self.apple_client_id_dev.strip()]
        return list(dict.fromkeys(i for i in ids if i))

    @property
    def db_path(self) -> Path:
        return self.data_dir / "xppocket.db"

    @property
    def packs_dir(self) -> Path:
        return self.data_dir / "packs"

    @property
    def saves_dir(self) -> Path:
        return self.data_dir / "saves"

    @property
    def feedback_dir(self) -> Path:
        return self.data_dir / "feedback"

    def ensure_dirs(self) -> None:
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.packs_dir.mkdir(parents=True, exist_ok=True)
        self.saves_dir.mkdir(parents=True, exist_ok=True)
        self.feedback_dir.mkdir(parents=True, exist_ok=True)


settings = Settings()
