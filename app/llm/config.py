"""분류용 LLM 호출 파라미터."""

# 분류는 결정적이어야 하므로 temperature 0
LLM_TEMPERATURE = 0.0
# 라벨 하나만 뱉으면 되므로 토큰 소량
LLM_MAX_TOKENS = 20
# Qwen3 하이브리드 추론 끔 (분류엔 reasoning 불필요)
CHAT_TEMPLATE_KWARGS = {"enable_thinking": False}
