# 매핑 요약표 (mapping-summary.md)

자비스 멀티에이전트 시스템 — Claude Code 기반 v1.0 구축.

**핵심 원칙**: 프롬프트에는 정체성만(15%), 행동 강제는 코드·구조로(85%).

---

## 변경 이력

| 단계 | 작업 | 결과 |
|---|---|---|
| **1차** (이전) | 노션 10개 페이지 → `.claude/agents/` 10개 무거운 파일 (7~12KB 각) | "규칙 악순환" 발생 — 규칙을 프롬프트에 넣을수록 LLM이 지키지 않음 |
| **2차** (현재) | 10개 → 7개로 재편 + 도메인 지식 스킬 분리 + CLAUDE.md + 훅 v1 + MCP | 에이전트 파일 1~2KB, 행동 규칙은 코드·구조로 외부화 |

---

## 1. 10개 에이전트 → 7개 재편

| 기존 노션 (10) | 신규 Claude Code (7) | 변경 이유 |
|---|---|---|
| 플래너 + 디렉터 | **planner** (통합) | Claude Code의 TodoWrite + 서브에이전트 스포닝이 실행 관리를 흡수. 별도 디렉터 불필요 |
| 페르소나 아키텍트 | (삭제) | Claude Code에서 에이전트 설계는 `.md` 파일 수정. 별도 설계 에이전트 불필요 |
| 마케팅 + 크리에이티브 | **content-marketing** (통합) | 홈리빙 이커머스에서 마케팅 콘텐츠와 상품 콘텐츠 소재 겹침. 스킬 파일로 역할 분리 |
| 상품MD | **product-md** | 유지 |
| 커머스옵스 | **commerce-ops** | 유지 |
| 데이터분석 | **data-analytics** | 유지 |
| 빌더 | **builder** | 유지 |
| 분석검증 | **analysis-verifier** | 유지 |

---

## 2. 7개 에이전트 파일 (각 1~2KB)

각 파일에 담은 것: **정체성 + 핵심 원칙(최대 2개) + 출력 규격 + 라우팅**

각 파일에 넣지 않은 것:
- 공유 프로토콜 (CLAUDE.md로 이동)
- 메타사고 프로토콜 (불필요 — Claude 모델의 기본 추론)
- 작업보드 운영 규칙 (MCP + 훅)
- 자가검증 게이트 (훅 + analysis-verifier 호출)
- 대표님 출력 규칙 (CLAUDE.md)

| 파일 | 크기 | 참조 스킬 |
|---|---|---|
| `.claude/agents/planner.md` | 1.2KB | market-landscape, business-strategy |
| `.claude/agents/product-md.md` | 1.2KB | product-judgment, channel-fees, home-living-category |
| `.claude/agents/content-marketing.md` | 1.1KB | content-formats, sns-strategy, ad-operations, platform-specs |
| `.claude/agents/commerce-ops.md` | 1.2KB | channel-fees, channel-registration, inventory-management, cs-templates |
| `.claude/agents/data-analytics.md` | 1.1KB | kpi-framework, analytics-methods, market-research |
| `.claude/agents/builder.md` | 1.1KB | tech-stack, automation-patterns |
| `.claude/agents/analysis-verifier.md` | 1.1KB | verification-checklist |

---

## 3. 18개 스킬 파일 (`.claude/skills/`)

도메인 지식 추출. 규칙·행동지침은 넣지 않음. 순수 지식만.

### product-md 관련

| 스킬 | 추출 출처 |
|---|---|
| `product-judgment.md` | PB-1~PB-9 판단 기준 + C.0 두 갈래 게이트 + 트렌드 수명 + 마진 시뮬레이션 |
| `home-living-category.md` | 가구/인테리어 시장 특성, 카테고리별 특성, 시즌 캘린더 |

### commerce-ops 관련

| 스킬 | 추출 출처 |
|---|---|
| `channel-fees.md` | 4채널 수수료·정산 구조, 마진 계산 공식, BEP·ROAS 연쇄 |
| `channel-registration.md` | 채널별 등록 규격, STEP 2.5 채널 전략 Q1~Q4 |
| `inventory-management.md` | Cello 재고, 안전재고 계산, 발주 시점 역산 |
| `cs-templates.md` | 문의 유형 분류, 채널별 톤, 에스컬레이션 판단 |

### content-marketing 관련

| 스킬 | 추출 출처 |
|---|---|
| `content-formats.md` | 상세페이지 구조, 영상 기획(첫 30초 후킹), 블로그, SNS 캐러셀 |
| `platform-specs.md` | 채널·플랫폼별 콘텐츠 규격 (이미지/영상 비율, 카피 길이) |
| `sns-strategy.md` | 광고+콘텐츠 양축, STEP 2.0 Q1~Q6, 유튜브 우선, 마케팅-크리에이티브 분업 |
| `ad-operations.md` | 광고 집행 범위·승인, ROAS/CPA, 광고 진단 패턴 |

### data-analytics 관련

| 스킬 | 추출 출처 |
|---|---|
| `kpi-framework.md` | 채널별 KPI 역할, 선행/후행 지표, 사업 건강도 |
| `analytics-methods.md` | Phase B 분석 파이프라인, B.4 전략 해석, Phase G 진단 |
| `market-research.md` | 트렌드 식별, 확산 곡선, 경쟁사·고객 불만 분석 |

### builder 관련

| 스킬 | 추출 출처 |
|---|---|
| `tech-stack.md` | 자비스 기술 스택, Stage 로드맵, 도구 선택 규칙, 비용 가이드 |
| `automation-patterns.md` | 자동화 기회 탐지, AI 트렌드 스카우팅, 도입 4단계 |

### analysis-verifier 관련

| 스킬 | 추출 출처 |
|---|---|
| `verification-checklist.md` | 망원경 T1~T6, 현미경 M1~M10, 전략 질문 Q1~Q4, LLM 실행 가능성 점검 |

### planner 관련

| 스킬 | 추출 출처 |
|---|---|
| `market-landscape.md` | 메인홈 현재 위치, 4채널 환경, 콘텐츠 플랫폼 환경, 사업 흐름 |
| `business-strategy.md` | A4 1장 5항목, 작업 흐름, 라우팅 6경로, 검증 경로 |

---

## 4. CLAUDE.md (프로젝트 루트)

모든 에이전트가 공통 참조하는 프로젝트 설정. 다음을 포함:

- 프로젝트 정체성 (메인홈 4채널 자동화, 북극성)
- 5축 시너지 원칙 (거시&전략 / 수익 / 리서치 / 자동화 / 시너지)
- 행동 원칙 5개 (실행 전 생각 / 요청만 실행+의무 4개 / 근거 / 검증 / 정정)
- 출력 기본 형식 (① 한 줄 요약 → ② 본론 → ③ 다음 단계)
- 에이전트 간 연결 (서브에이전트 호출, 검증 경로)
- 7개 에이전트 구성 요약
- 4채널 빠른 참조 표

---

## 5. MCP 서버 (.claude/mcp_servers.json)

- **notion** — 노션 작업보드 + 문서 운영
- **gmail** — 이메일 자동화
- **google-drive** — 파일 저장·공유

---

## 6. 훅 v1 (.claude/hooks.md)

개념과 트리거 지점 정의. 구체적 셸 스크립트는 builder가 후속 구현.

| 훅 | 이벤트 | 검사 |
|---|---|---|
| **5축 시너지 체크** | SubagentStop | 산출물에 5축 키워드 명시 여부 |
| **세팅 산출물 검증 게이트** | PostToolUse | 세팅 파일 변경 시 analysis-verifier 자동 호출 |
| **출력 포맷 검증** | Stop | 대표님 대상 출력의 ① → ② → ③ 구조 확인 |

---

## 7. 버린 것 (옮기지 않은 것)

기존 노션 페이지에서 다음은 **완전 삭제** — CLAUDE.md 또는 훅이 대체:

- 공유 프로토콜 v3.1/v4.1/v4.3 반복 텍스트
- 메타사고 프로토콜 5단계
- SHARED-1~5, WB-1~5 작업보드 규칙
- 대표님 출력 규칙
- 기본 동작 모드 5개 (output_scope, next_step, notion_write, judgment_format, proposal_format)
- 자가검증 게이트 L1+L2+L3 (각 에이전트별 반복)
- CHANGE LOG / 버전 진화 프로토콜
- 인터페이스 계약 레지스트리 IC-XX-NN (Claude Code의 Task 도구로 대체)

---

## 8. 보존한 것

기존 노션 페이지의 **도메인 고유 판단 기준**은 반드시 보존:

- PB-1~9 (각 에이전트별), OB (운영 규칙), DC (드리프트 체크)
- 진단 패턴 P1~P10
- 채널 전략 질문 Q1~Q4 (상품MD C.0, 마케팅 STEP 2.0, 커머스옵스 STEP 2.5, 크리에이티브 전략 질문)
- 망원경 T1~T6, 현미경 M1~M10
- 8축 + Axis 0 프레임워크 (PA가 삭제되었으나 검증 체크리스트로 흡수)

모두 스킬 파일에 도메인 지식으로 보존됨.

---

## 9. 멀티에이전트 흐름

```
                 대표님
                   │
                   ▼
                planner ◄────────────────┐
              (사업 기획 + 라우팅)         │
                   │                      │
       ┌───────────┼────────────┐         │ 검증 결과
       ▼           ▼            ▼         │ 피드백
   product-md  content-mkt   commerce-ops │
   (상품 기획)  (콘텐츠+광고) (4채널 운영)  │
       │           │            │         │
       └───────────┼────────────┘         │
                   ▼                      │
              data-analytics              │
              (성과·방향 감지)             │
                   │                      │
                   ▼                      │
            analysis-verifier ────────────┘
            (망원경 + 현미경)

                 builder
            (시스템 자체 구현)
            — 모든 에이전트 인프라
            — AI 트렌드 스카우팅 → planner
```

---

## 10. 검증 — 완료 확인

- ✅ 에이전트 파일 7개, 각각 2KB 이하 (1.0~1.3KB)
- ✅ CLAUDE.md에 5축 시너지 원칙 포함
- ✅ 스킬 파일 18개, 도메인 지식 빠짐없이 (PB-1~9 등)
- ✅ 에이전트 파일에 공유 프로토콜 반복 텍스트 없음
- ✅ mapping-summary.md에 기존→신규 매핑 명확

---

*개정일: 2026-05-13 | 노션 10개 페이지 → 7개 에이전트 + 18개 스킬 + CLAUDE.md + MCP + 훅 v1*
