#!/usr/bin/env bash
# 훅: check-5-axes.sh
# 트리거: SubagentStop — 서브에이전트 완료 직후
# 목적: 산출물에 5축 시너지 키워드(거시, 수익, 리서치, 자동화, 시너지)가
#        모두 명시되어 있는지 검사. 누락 시 재작업 강제.
# exit 0 : 검사 통과 또는 환경 오류(작업 차단 안 함)
# exit 2 : 5축 키워드 누락 → Claude에게 stderr 노출, 재작업 유도

set -euo pipefail

REQUIRED_AXES=("거시" "수익" "리서치" "자동화" "시너지")

# --- 환경 점검 ---
if ! command -v jq &>/dev/null; then
  echo "[5축 체크] jq 미설치 — 검사를 건너뜁니다. (jq 설치 권장)" >&2
  exit 0
fi

# --- stdin에서 이벤트 JSON 읽기 ---
INPUT=$(cat)

TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)

if [[ -z "$TRANSCRIPT_PATH" ]]; then
  echo "[5축 체크] transcript_path를 읽을 수 없습니다 — 검사를 건너뜁니다." >&2
  exit 0
fi

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "[5축 체크] transcript 파일을 찾을 수 없습니다: $TRANSCRIPT_PATH — 검사를 건너뜁니다." >&2
  exit 0
fi

# --- 마지막 assistant 메시지 텍스트 추출 ---
# transcript는 JSONL 형식. 각 줄이 하나의 메시지 객체.
# slurp(-s)으로 전체를 배열로 읽고, role == "assistant" 인 마지막 항목 선택.
# Claude Code transcript는 메시지가 top-level role/content 형태이거나
# {type, message: {role, content}} nested 형태일 수 있어 둘 다 지원.
# content는 string 또는 [{type:"text", text:"..."}] 배열 양쪽 모두 처리.
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
  echo "[5축 체크] 마지막 assistant 메시지를 파싱할 수 없습니다 — 검사를 건너뜁니다." >&2
  exit 0
fi

# --- 5축 키워드 검사 ---
MISSING=()

for AXIS in "${REQUIRED_AXES[@]}"; do
  if ! echo "$LAST_ASSISTANT_TEXT" | grep -q "$AXIS"; then
    MISSING+=("$AXIS")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  MISSING_STR=$(IFS='/'; echo "${MISSING[*]}")
  echo "[5축 시너지 누락] 다음 키워드가 보이지 않습니다: ${MISSING_STR} — 산출물에 명시적으로 표기하세요 (\"해당 없음\"도 허용)." >&2
  exit 2
fi

exit 0
