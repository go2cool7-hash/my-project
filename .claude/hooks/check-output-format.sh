#!/usr/bin/env bash
# 훅: check-output-format.sh
# 트리거: Stop — 메인 에이전트 응답 완료 직후
# 목적: 대표님 대상 출력이 "① 한 줄 요약 → ② 본론 → ③ 다음 단계" 형식인지
#        확인하고, 누락 시 stderr 경고. (v1: 알림만, 차단 안 함)
# exit 0 : 항상 통과 (v1은 차단 안 함)

set -euo pipefail

MIN_LENGTH=300

# --- 환경 점검 ---
if ! command -v jq &>/dev/null; then
  echo "[출력 포맷] jq 미설치 — 포맷 검사를 건너뜁니다." >&2
  exit 0
fi

# --- stdin에서 이벤트 JSON 읽기 ---
INPUT=$(cat)

TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)

if [[ -z "$TRANSCRIPT_PATH" ]]; then
  echo "[출력 포맷] transcript_path를 읽을 수 없습니다 — 검사를 건너뜁니다." >&2
  exit 0
fi

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "[출력 포맷] transcript 파일을 찾을 수 없습니다: $TRANSCRIPT_PATH — 검사를 건너뜁니다." >&2
  exit 0
fi

# --- 마지막 assistant 메시지 텍스트 추출 ---
# slurp(-s)으로 전체를 배열로 읽고, 마지막 assistant 메시지 추출.
# content가 string 또는 [{type:"text", text:"..."}] 배열 양쪽 모두 처리.
set +e
LAST_ASSISTANT_TEXT=$(
  grep -v '^[[:space:]]*$' "$TRANSCRIPT_PATH" \
  | jq -rs '
      [.[] | select((.role // (.message.role? // "")) == "assistant")]
      | last
      | ((.content // .message.content?) // "")
      | if type == "array"
        then map(select(.type == "text") | .text) | join("\n")
        else .
        end
    ' 2>/dev/null
)
JQ_EXIT=$?
set -e

if [[ $JQ_EXIT -ne 0 ]] || [[ -z "$LAST_ASSISTANT_TEXT" ]] || [[ "$LAST_ASSISTANT_TEXT" == "null" ]]; then
  echo "[출력 포맷] 마지막 assistant 메시지를 파싱할 수 없습니다 — 검사를 건너뜁니다." >&2
  exit 0
fi

# --- 대표님 대상 출력 후보 판별 휴리스틱 ---
TEXT_LENGTH=${#LAST_ASSISTANT_TEXT}

# 길이 300자 미만이면 짧은 응답 — 포맷 체크 제외
if [[ $TEXT_LENGTH -le $MIN_LENGTH ]]; then
  exit 0
fi

# 코드 블록만 있는 경우 제외 (산문 줄이 거의 없으면 스킵)
# 백틱(```) 밖의 줄 수를 근사 계산: 전체 줄 - 코드 블록 내 줄
TOTAL_LINES=$(echo "$LAST_ASSISTANT_TEXT" | wc -l)
CODE_BLOCK_LINES=$(echo "$LAST_ASSISTANT_TEXT" | grep -c '^\s*```' 2>/dev/null || echo 0)
# 코드 블록 구분자가 전체의 절반 이상이면 코드 위주 응답으로 판단 — 스킵
if [[ $CODE_BLOCK_LINES -gt 0 ]]; then
  PROSE_RATIO=$(( (TOTAL_LINES - CODE_BLOCK_LINES * 2) * 100 / TOTAL_LINES ))
  if [[ $PROSE_RATIO -le 20 ]]; then
    exit 0
  fi
fi

# --- 포맷 패턴 점검 ---
MISSING_PARTS=()

# 항목 1: 한 줄 요약 (첫 200자 안에 "한 줄 요약" 키워드 또는 첫 줄이 단일 문장)
FIRST_200="${LAST_ASSISTANT_TEXT:0:200}"
if ! echo "$FIRST_200" | grep -q "한 줄 요약"; then
  # 첫 줄이 빈 줄 없이 하나의 완결 문장(마침표/.) 으로 끝나는지 근사 판단
  FIRST_LINE=$(echo "$LAST_ASSISTANT_TEXT" | head -1)
  FIRST_LINE_LEN=${#FIRST_LINE}
  # 첫 줄이 10자 이상 + 마침표나 다 (완결 표현) 로 끝나면 요약 존재로 인정
  if [[ $FIRST_LINE_LEN -lt 10 ]] || ! echo "$FIRST_LINE" | grep -qE '[.다요음다.]$'; then
    MISSING_PARTS+=("① 한 줄 요약")
  fi
fi

# 항목 2: 본문 섹션 (## 헤더 또는 충분한 단락 존재)
if ! echo "$LAST_ASSISTANT_TEXT" | grep -qE '^##? '; then
  # 헤더 없으면 단락 구분(빈 줄 2개 이상)으로 대체 판단
  PARAGRAPH_BREAKS=$(echo "$LAST_ASSISTANT_TEXT" | grep -c '^$' 2>/dev/null || echo 0)
  if [[ $PARAGRAPH_BREAKS -lt 2 ]]; then
    MISSING_PARTS+=("② 본론 섹션")
  fi
fi

# 항목 3: 다음 단계
if ! echo "$LAST_ASSISTANT_TEXT" | grep -q "다음 단계"; then
  MISSING_PARTS+=("③ 다음 단계")
fi

# --- 누락 항목 경고 ---
if [[ ${#MISSING_PARTS[@]} -gt 0 ]]; then
  MISSING_STR=$(IFS=', '; echo "${MISSING_PARTS[*]}")
  echo "[출력 포맷] 대표님 대상 출력 형식 ① 한 줄 요약 → ② 본론 → ③ 다음 단계 일부가 보이지 않습니다. (누락: ${MISSING_STR})" >&2
fi

# v1: 항상 exit 0 (알림만, 차단 안 함)
exit 0
