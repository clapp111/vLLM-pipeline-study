"""FastAPI 앱 진입점 (로컬 분류 파이프라인 검증용)."""
from fastapi import FastAPI

from app.api.v1.classify import router as classify_router

app = FastAPI(title="news-classifier (study)")
app.include_router(classify_router)


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
