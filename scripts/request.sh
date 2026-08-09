#!/usr/bin/env bash
# 로컬 FastAPI 분류 엔드포인트로 테스트 요청.
# 사용법:  scripts/request.sh ["분류할 뉴스 텍스트"]
set -euo pipefail

URL="${APP_URL:-http://localhost:8080}"
TEXT="${1:-삼성전자가 차세대 반도체 공정을 공개했다}"

curl -fsS -X POST "${URL}/v1/classify" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"${TEXT}\"}"
echo
