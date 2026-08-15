"""분류 API 요청/응답 스키마."""
from pydantic import BaseModel, Field

from app.service.classify.prompts.classify_prompt import Label


class ClassifyRequest(BaseModel):
    title: str = Field(..., min_length=1, description="뉴스 제목")
    content: str | None = Field(None, description="뉴스 본문 (없을 수 있음)")


class ClassifyResponse(BaseModel):
    label: Label = Field(..., description="분류 결과 라벨 (LABELS 중 하나)")
