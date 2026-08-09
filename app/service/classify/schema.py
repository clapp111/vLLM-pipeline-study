"""분류 API 요청/응답 스키마."""
from pydantic import BaseModel, Field


class ClassifyRequest(BaseModel):
    text: str = Field(..., min_length=1, description="분류할 뉴스 텍스트")


class ClassifyResponse(BaseModel):
    label: str = Field(..., description="분류 결과 라벨 (LABELS 중 하나)")
