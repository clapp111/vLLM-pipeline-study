#!/usr/bin/env bash
# 인터넷 되는 머신에서 모델 가중치를 미리 받는다 (오프라인 배포용).
# 받은 뒤 결과 디렉토리를 AI 서버의 ${MODELS_DIR} 로 전송(scp/rsync)하고,
# .env 에 VLLM_MODEL=/models/<name> 설정 후 docker-compose.offline.yml 로 기동.
#
# 사용법:  scripts/download_model.sh [HF_REPO] [DEST_DIR]
# 예:      scripts/download_model.sh Qwen/Qwen2.5-1.5B-Instruct-AWQ ./models
#
# 사전: pip install -U "huggingface_hub[cli]"
set -euo pipefail

MODEL="${1:-Qwen/Qwen2.5-1.5B-Instruct-AWQ}"
DEST_DIR="${2:-./models}"
NAME="$(basename "$MODEL")"
TARGET="${DEST_DIR}/${NAME}"

if ! command -v huggingface-cli >/dev/null 2>&1; then
  echo "huggingface-cli 가 없습니다. 먼저 설치하세요:" >&2
  echo "  pip install -U \"huggingface_hub[cli]\"" >&2
  exit 1
fi

echo "== 다운로드: ${MODEL} -> ${TARGET} =="
# 중복되는 PyTorch/original 가중치는 제외해 용량 절약 (AWQ/safetensors 만 사용)
huggingface-cli download "$MODEL" \
  --local-dir "$TARGET" \
  --exclude "*.pth" "*.pt" "original/*" "consolidated*"

echo
echo "== 완료 =="
echo "1) 이 디렉토리를 AI 서버로 전송:  rsync -av \"${TARGET}\" <server>:<MODELS_DIR>/"
echo "2) .env 설정:  VLLM_MODEL=/models/${NAME}   MODELS_DIR=<server의 host 경로>"
echo "3) 기동:  docker compose -f docker-compose.yml -f docker-compose.offline.yml up -d"
