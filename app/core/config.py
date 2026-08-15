"""앱 전역 설정 (.env 로딩)."""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # litellm 게이트웨이 (로컬: docker compose 의 litellm, 호스트 4000)
    llm_base_url: str = "http://localhost:4000/v1"
    # litellm 마스터 키 (.env 의 LITELLM_MASTER_KEY 와 동일 값)
    llm_api_key: str = "sk-1234"
    # litellm config.yaml 의 model_name 별칭
    llm_model: str = "dongmin-study"
    # 호출 타임아웃(초)
    llm_timeout: float = 30.0


@lru_cache
def get_settings() -> Settings:
    return Settings()
