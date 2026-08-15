#!/usr/bin/env bash
# 로컬 FastAPI 분류 엔드포인트로 테스트 요청.
# 사용법:  scripts/request.sh ["제목"] ["본문(선택)"]
set -euo pipefail

URL="${APP_URL:-http://localhost:8080}"
TITLE="${1:-삼성전자가 차세대 반도체 공정을 공개했다}"
CONTENT="${2:-}"

if [ -n "$CONTENT" ]; then
  BODY="{\"title\": \"${TITLE}\", \"content\": \"${CONTENT}\"}"
else
  BODY="{\"title\": \"${TITLE}\"}"
fi

curl -fsS -X POST "${URL}/v1/classify" \
  -H "Content-Type: application/json" \
  -d "${BODY}"
echo
