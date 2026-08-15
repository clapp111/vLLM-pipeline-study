"""분류 API 라우터."""
from fastapi import APIRouter, HTTPException

from app.service.classify import service
from app.service.classify.schema import ClassifyRequest, ClassifyResponse

router = APIRouter(prefix="/v1", tags=["classify"])


@router.post("/classify", response_model=ClassifyResponse)
async def classify(req: ClassifyRequest) -> ClassifyResponse:
    try:
        label = await service.classify(req.title, req.content)
    except ValueError as e:
        # 모델 응답을 라벨로 파싱하지 못한 경우
        raise HTTPException(status_code=502, detail=str(e))
    return ClassifyResponse(label=label)
