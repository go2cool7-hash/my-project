# 자비스 훅 설계 v1 — 최소 구현

> 훅(Hook)은 에이전트 행동 전후에 자동 실행되는 검증/차단 장치다.
> 이 문서는 v1에서 적용할 훅의 **개념과 트리거 지점**을 정의한다.
> 구체적 셸 스크립트 구현은 builder 에이전트가 담당.

훅 정의 위치: `.claude/settings.json` 또는 `.claude/settings.local.json`

---

## 훅 1 — 5축 시너지 체크 (SubagentStop 훅)

### 개념
서브에이전트가 완료될 때, 산출물에 "5축 연결" 섹션이 포함되어 있는지 검사. 없으면 stderr로 "5축 연결 섹션 누락 — 다시 작성하세요"를 반환하여 재작업 강제.

### 트리거
- 이벤트: `SubagentStop`
- 대상: 모든 서브에이전트 호출

### 검사 항목
산출물 텍스트에 다음 5축 키워드가 명시되어 있는가:
- 거시&전략
- 수익
- 리서치
- 자동화
- 시너지

"해당 없음" 표기도 허용 (빈칸 ≠ 해당 없음).

### 동작
- 누락 시: exit code 비정상 + stderr 메시지 → Claude Code가 재작업 강제
- 통과 시: exit code 0

### 구현 예시 (의사 코드)
```bash
#!/bin/bash
# .claude/hooks/check-5-axes.sh
SUBAGENT_OUTPUT="$1"
REQUIRED_AXES=("거시" "수익" "리서치" "자동화" "시너지")

for axis in "${REQUIRED_AXES[@]}"; do
  if ! grep -q "$axis" "$SUBAGENT_OUTPUT"; then
    echo "5축 연결 섹션 누락 ($axis) — 다시 작성하세요" >&2
    exit 1
  fi
done
exit 0
```

---

## 훅 2 — 세팅 산출물 검증 게이트 (PostToolUse 훅)

### 개념
파일 쓰기 도구 사용 후, 해당 파일이 "세팅/설계" 카테고리인 경우 analysis-verifier 서브에이전트를 자동 호출하여 검증.

### 트리거
- 이벤트: `PostToolUse`
- 도구 매칭: `Write`, `Edit`
- 파일 패턴 매칭:
  - `.claude/agents/*.md`
  - `.claude/skills/*.md`
  - `CLAUDE.md`
  - `**/plan-*.md`
  - `**/strategy-*.md`
  - `**/spec-*.md`

### 판별 기준
- **세팅/설계**: 이후 다른 작업의 규칙·구조·기준을 정의 → 검증 필수
- **반복 실행**: 기존 정의 안에서 실행 수행 → 자가검증으로 통과

### 동작
- 세팅 파일 감지 시: analysis-verifier 서브에이전트 자동 호출
- analysis-verifier 출력을 Claude에게 노출
- 검증 실패 시 사용자에게 경고

---

## 훅 3 — 출력 포맷 검증 (Stop 훅)

### 개념
에이전트 응답 완료 시, 대표님 대상 출력이면 "① 한 줄 요약 → ② 본론 → ③ 다음 단계" 형식인지 검사.

### 트리거
- 이벤트: `Stop`
- 대상: 메인 에이전트 응답 (서브에이전트는 제외)

### 검사 항목
대표님 대상 출력으로 판단되는 응답이면 다음 구조 확인:
- `① 한 줄 요약` 또는 동등 표현
- `② 본론` 또는 본문 섹션
- `③ 다음 단계` 또는 "다음 단계: 없음. 참고용입니다." 명시

### 동작
- 누락 시: 응답 종료 후 stderr 경고 (재실행 강제는 아님 — v1은 알림 수준)
- v2에서 재실행 강제 검토

---

## 훅 운영 원칙

1. **v1은 알림 + 차단 최소화** — 사용자 경험 우선
2. **로그 축적** — 훅 작동 기록을 분석하여 v2 개선
3. **점진적 강화** — 알림 → 경고 → 차단 순서

## 향후 추가 검토 훅

- 작업보드 등록 누락 검사 (Notion MCP 연동 후)
- 검증 게이트 통과 여부 추적
- 비용 한도 초과 경고 (API 사용량)
- 세션 시작 시 5축 원칙 리마인드

---

## settings.json 구조 예시

```json
{
  "hooks": {
    "SubagentStop": [
      {
        "command": "bash .claude/hooks/check-5-axes.sh"
      }
    ],
    "PostToolUse": [
      {
        "matcher": {
          "tools": ["Write", "Edit"],
          "filePatterns": [".claude/agents/*.md", ".claude/skills/*.md", "CLAUDE.md"]
        },
        "command": "bash .claude/hooks/verify-setting-output.sh"
      }
    ],
    "Stop": [
      {
        "command": "bash .claude/hooks/check-output-format.sh"
      }
    ]
  }
}
```

**참고**: 위 셸 스크립트의 구체적 구현은 builder 에이전트가 후속 작업으로 진행. 이 문서는 트리거 지점과 검사 로직 정의까지.
