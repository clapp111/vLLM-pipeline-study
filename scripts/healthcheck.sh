#!/usr/bin/env bash
# vLLM / litellm 컨테이너 헬스체크
set -uo pipefail

VLLM_URL="${VLLM_URL:-http://localhost:8000}"
LITELLM_URL="${LITELLM_URL:-http://localhost:4000}"

echo "== vLLM health (${VLLM_URL}/health) =="
curl -fsS "${VLLM_URL}/health" >/dev/null && echo "  OK" || echo "  FAIL"

echo "== vLLM models (${VLLM_URL}/v1/models) =="
curl -fsS "${VLLM_URL}/v1/models" || echo "  FAIL"
echo

echo "== litellm liveliness (${LITELLM_URL}/health/liveliness) =="
curl -fsS "${LITELLM_URL}/health/liveliness" && echo "  OK" || echo "  FAIL"
echo
