"""분류 작업 오케스트레이션: 프롬프트 구성 → LLM 호출 → 라벨 파싱."""
import re

from app.llm import client
from app.service.classify.prompts.classify_prompt import LABELS, Label, build_messages

# Qwen3 가 추론 모드로 응답할 경우 <think>...</think> 블록 제거용
_THINK_RE = re.compile(r"<think>.*?</think>", re.DOTALL)


async def classify(title: str, content: str | None = None) -> Label:
    messages = build_messages(title, content)
    raw = await client.complete(messages, guided_choice=LABELS)
    return _parse_label(raw)


def _parse_label(raw: str) -> Label:
    cleaned = _THINK_RE.sub("", raw).strip()
    # 정확 일치 우선
    if cleaned in LABELS:
        return cleaned
    # 모델이 문장으로 답한 경우 라벨 포함 여부로 매칭 (guided_choice 미적용 대비)
    for label in LABELS:
        if label in cleaned:
            return label
    raise ValueError(f"라벨 파싱 실패: {raw!r}")
