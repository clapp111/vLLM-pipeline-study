# vLLM-pipeline-study

외부 요청이 **FastAPI → litellm → vLLM** 으로 흐르는 파이프라인을 검증하는 스터디 프로젝트.
한국어 뉴스 기사를 6개 라벨(`정치·경제·사회·IT과학·스포츠·없음`) 중 하나로 분류하는 작업을 LLM 에 위임하고,
vLLM `guided_choice` 로 출력이 라벨 집합을 벗어나지 않도록 강제한다.
vLLM·litellm 은 Docker 로, FastAPI 앱은 호스트에서 실행한다.

## Architecture

```
클라이언트
  │  POST /v1/classify  {title, content?}
  ▼
FastAPI 앱 (호스트, :8080)
  │  OpenAI 호환 호출  model="dongmin-study"
  ▼
litellm proxy (Docker, :4000)      ← 공개 별칭 dongmin-study
  │  openai/qwen3-4b-awq 로 라우팅
  ▼
vLLM (Docker, :8000)               ← 백엔드 실체명 qwen3-4b-awq
  │  guided_choice 로 6개 라벨 중 하나만 생성
  ▼
{ "label": "..." }
```

- **모델명 2계층**: 앱→litellm 은 공개 별칭 `dongmin-study`, litellm→vLLM 은 백엔드 실체명 `qwen3-4b-awq`.
  매핑은 `configs/litellm-config.yaml` 에 있다.
- **서빙 모델**: `Qwen/Qwen3-4B-AWQ` (INT4 AWQ, ~2.5GB). 6GB 노트북 GPU 기준으로 세팅.

## Project Structure

```
app/
├── main.py                        # FastAPI 진입점 (/health + classify 라우터)
├── api/v1/classify.py             # POST /v1/classify
├── service/classify/
│   ├── service.py                 # 프롬프트 구성 → LLM 호출 → 라벨 파싱
│   ├── schema.py                  # 요청(title, content) / 응답(label) 스키마
│   └── prompts/classify_prompt.py # 시스템 프롬프트 + Label 정의
├── llm/
│   ├── client.py                  # litellm(OpenAI 호환) 호출 클라이언트
│   └── config.py                  # 호출 파라미터 (temperature=0, max_tokens=20 등)
└── core/config.py                 # 앱 env 설정 (LLM_BASE_URL 등, 기본값 내장)

configs/litellm-config.yaml        # litellm proxy 설정 (모델명 매핑, master_key)
scripts/
├── download_model.sh              # 모델을 ./models 에 다운로드 (기동 전 1회)
├── healthcheck.sh                 # vLLM / litellm 헬스체크
└── request.sh                     # 분류 요청 테스트
docker-compose.yml                 # vLLM + litellm 서비스
Dockerfile                         # (현재 비어있음 — 앱은 호스트 uvicorn 으로 실행)
```

## Quickstart

> WSL Ubuntu 터미널에서 실행. Windows 셸에서 돌리면 bind mount 경로가 깨진다.
> 사전 준비: NVIDIA GPU + 드라이버, Docker(+nvidia runtime), `pip install -U huggingface_hub`, 앱용 `.venv`.

```bash
# 1) 모델 다운로드 → ./models/Qwen3-4B-AWQ (최초 1회. 이미 있으면 건너뜀)
scripts/download_model.sh

# 2) vLLM + litellm 기동 (HF 접속 없이 ./models 에서 로드)
docker compose up -d
bash scripts/healthcheck.sh            # vLLM/litellm 초록불 확인

# 3) FastAPI 분류 앱 실행 (호스트. vLLM 이 8000 을 쓰므로 반드시 --port 8080 지정)
uvicorn app.main:app --reload --port 8080

# 4) 분류 요청 (curl 또는 Swagger UI http://localhost:8080/docs)
curl -s -X POST http://localhost:8080/v1/classify \
  -H "Content-Type: application/json" \
  -d '{"title": "손흥민이 결승골을 넣었다"}'
# -> {"label":"스포츠"}
```

**포트**: vLLM `8000` · litellm `4000` · FastAPI 앱 `8080`.

**API 문서 (Swagger UI)**: 앱 실행 후 <http://localhost:8080/docs> 에서 `POST /v1/classify` 를 브라우저로 바로 테스트할 수 있다 (**Try it out** → `{"title": "..."}` 입력 → **Execute**). 그 밖에 ReDoc `/redoc`, OpenAPI JSON `/openapi.json`, 헬스체크 `/health`.

## Configuration

대부분의 값은 **`docker-compose.yml` 에 하드코딩**되어 있고, `.env` 로 바꾸는 값은 하나뿐이다.

**`.env`** (docker compose 가 자동으로 읽음):

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `LITELLM_MASTER_KEY` | `sk-1234` | litellm 프록시 인증 키. 앱이 보내는 키(`LLM_API_KEY`)와 일치해야 함 |

**`docker-compose.yml` (vLLM 서비스, 하드코딩):**

| 항목 | 값 | 비고 |
|------|-----|------|
| image | `vllm/vllm-openai:v0.8.5.post1` | CUDA 12.4 기반. `latest` 는 CUDA 13 요구 |
| `--model` | `/models/Qwen3-4B-AWQ` | `./models` 마운트의 로컬 경로 |
| `--served-model-name` | `qwen3-4b-awq` | litellm 백엔드명과 일치 |
| `--quantization` | `awq` | AWQ 모델 |
| `--gpu-memory-utilization` | `0.85` | 6GB 노트북 기준. 12GB 서버면 낮춰도 됨 |
| `--max-model-len` | `2048` | 분류는 짧아도 충분 |
| `--enforce-eager` | (설정) | 저VRAM cudagraph 오버헤드 제거 |
| `HF_HUB_OFFLINE` / `TRANSFORMERS_OFFLINE` | `1` | 런타임 HF 접속 차단 |

> 모델을 바꾸려면 `docker-compose.yml` 의 `--model`·`--served-model-name`·`--quantization` 과
> `download_model.sh` 인자를 함께 맞춘다.

**앱 설정** (`app/core/config.py`, 기본값 내장 — 필요 시 동명 env 로 override):

| 설정 | 기본값 | 설명 |
|------|--------|------|
| `LLM_BASE_URL` | `http://localhost:4000/v1` | litellm 게이트웨이 |
| `LLM_API_KEY` | `sk-1234` | `LITELLM_MASTER_KEY` 와 동일해야 함 |
| `LLM_MODEL` | `dongmin-study` | litellm 공개 별칭 |
| `LLM_TIMEOUT` | `30.0` | 호출 타임아웃(초) |

## Model Provisioning

로컬/AI 서버 모두 **HF 런타임 접속 없이** `./models` 의 로컬 가중치에서 로드한다.
`--model /models/...` + `HF_HUB_OFFLINE=1` 조합이라, 기동 전 반드시 모델이 `./models` 에 있어야 한다.

```bash
scripts/download_model.sh                    # 기본 Qwen/Qwen3-4B-AWQ
scripts/download_model.sh Qwen/Qwen3-0.6B    # 다른 모델은 인자로
```

- `./models` 는 호스트 디렉토리(bind mount)라 **컨테이너를 재시작해도 다시 받지 않는다.** 최초 1회만.
- AI 서버 배포 시 `./models` 를 서버로 전송하는 절차는 별도로 처리한다.

## Labels

`정치` · `경제` · `사회` · `IT과학` · `스포츠` · `없음` (6종).
라벨 정의와 분류 원칙은 `app/service/classify/prompts/classify_prompt.py` 참고.
