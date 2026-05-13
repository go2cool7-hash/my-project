#!/usr/bin/env bash
# 훅: verify-setting-output.sh
# 트리거: PostToolUse — Write 또는 Edit 도구 실행 직후
# 목적: 변경된 파일이 세팅/설계 파일 패턴에 해당하면
#        analysis-verifier 호출을 안내한다. (v1: 안내만, 자동 호출은 v2)
# exit 0 : 항상 통과 (v1은 차단 안 함)

set -euo pipefail

# --- 환경 점검 ---
if ! command -v jq &>/dev/null; then
  echo "[검증 게이트] jq 미설치 — 세팅 파일 감지를 건너뜁니다." >&2
  exit 0
fi

# --- stdin에서 이벤트 JSON 읽기 ---
INPUT=$(cat)

set +e
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
set -e

# --- Write/Edit 도구만 처리 ---
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  exit 0
fi

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# --- 세팅 파일 패턴 판별 ---
IS_SETTING=0

# 패턴 1: .claude/agents/*.md
if [[ "$FILE_PATH" == */.claude/agents/*.md ]] || [[ "$FILE_PATH" == .claude/agents/*.md ]]; then
  IS_SETTING=1
fi

# 패턴 2: .claude/skills/*.md
if [[ "$FILE_PATH" == */.claude/skills/*.md ]] || [[ "$FILE_PATH" == .claude/skills/*.md ]]; then
  IS_SETTING=1
fi

# 패턴 3: 루트 CLAUDE.md (경로 끝이 /CLAUDE.md 이거나 정확히 CLAUDE.md)
if [[ "$FILE_PATH" == "CLAUDE.md" ]] || [[ "$FILE_PATH" == */CLAUDE.md ]]; then
  IS_SETTING=1
fi

# 패턴 4: **/plan-*.md
if [[ "$(basename "$FILE_PATH")" == plan-*.md ]]; then
  IS_SETTING=1
fi

# 패턴 5: **/strategy-*.md
if [[ "$(basename "$FILE_PATH")" == strategy-*.md ]]; then
  IS_SETTING=1
fi

# 패턴 6: **/spec-*.md
if [[ "$(basename "$FILE_PATH")" == spec-*.md ]]; then
  IS_SETTING=1
fi

# --- 세팅 파일이면 안내 출력 ---
if [[ $IS_SETTING -eq 1 ]]; then
  echo "[검증 게이트] ${FILE_PATH} 세팅 파일 변경됨."
  echo "→ analysis-verifier 서브에이전트로 검증 권장:"
  echo "  Task(subagent_type=\"analysis-verifier\", prompt=\"다음 세팅 파일을 검증: ${FILE_PATH}\")"
fi

exit 0
