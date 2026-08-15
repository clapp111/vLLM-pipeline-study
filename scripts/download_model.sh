#!/usr/bin/env bash
# 기동 전 항상 실행: 모델 가중치를 ./models 에 받아둔다.
# 로컬/AI 서버 공통 — vLLM 은 HF 런타임 접속 없이 ./models 의 로컬 가중치를 로드한다.
#
# 사용법:  scripts/download_model.sh [HF_REPO] [DEST_DIR]
# 예:      scripts/download_model.sh Qwen/Qwen3-4B-AWQ ./models

set -euo pipefail

MODEL="${1:-Qwen/Qwen3-4B-AWQ}"
DEST_DIR="${2:-./models}"
NAME="$(basename "$MODEL")"
TARGET="${DEST_DIR}/${NAME}"

# hf(신규 CLI) 우선, 없으면 huggingface-cli(구버전) 로 폴백
if command -v hf >/dev/null 2>&1; then
  HF=hf
elif command -v huggingface-cli >/dev/null 2>&1; then
  HF=huggingface-cli
else
  echo "hf CLI 가 없습니다. venv 활성화 후 설치하세요:" >&2
  echo "  pip install -U huggingface_hub" >&2
  exit 1
fi

echo "== 다운로드: ${MODEL} -> ${TARGET} =="
# 중복되는 PyTorch/original 가중치는 제외해 용량 절약 (AWQ/safetensors 만 사용)
# hf CLI(Typer) 는 리스트 옵션을 패턴마다 --exclude 를 반복해서 줘야 한다
"$HF" download "$MODEL" \
  --local-dir "$TARGET" \
  --exclude "*.pth" --exclude "*.pt" --exclude "original/*" --exclude "consolidated*"

echo
echo "== 완료: ${TARGET} =="
echo "기동:  docker compose up -d"
# AI 서버 배포 시 ./models 전송은 별도 절차로 처리 (참고용, 필요 시 주석 해제)
# rsync -av "${TARGET}" <server>:<프로젝트 경로>/models/
