"""litellm 게이트웨이(OpenAI 호환)로 채팅 완성을 호출하는 클라이언트."""

from openai import AsyncOpenAI

from app.core.config import get_settings
from app.llm import config as llm_config

_settings = get_settings()
_client = AsyncOpenAI(
    base_url=_settings.llm_base_url,
    api_key=_settings.llm_api_key,
    timeout=_settings.llm_timeout,
)


async def complete(messages: list[dict], guided_choice: list[str] | None = None) -> str:
    """messages 로 채팅 완성 요청 후 응답 텍스트를 반환.

    guided_choice 를 주면 vLLM guided decoding 으로 해당 값 중 하나만 생성하도록 강제한다.
    """
    extra_body: dict = {"chat_template_kwargs": llm_config.CHAT_TEMPLATE_KWARGS}
    if guided_choice:
        extra_body["guided_choice"] = guided_choice

    resp = await _client.chat.completions.create(
        model=_settings.llm_model,
        messages=messages,
        temperature=llm_config.LLM_TEMPERATURE,
        max_tokens=llm_config.LLM_MAX_TOKENS,
        extra_body=extra_body,
    )
    return resp.choices[0].message.content or ""
