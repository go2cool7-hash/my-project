# 자비스 MCP 토큰 발급 가이드

> 이 문서는 자비스가 사용하는 MCP 서버의 토큰·자격증명 발급 절차를 단계별로 안내한다.
> Claude Code는 `.mcp.json`을 읽어 MCP 서버를 자동 연결한다.

---

## 1. Notion MCP — hosted, OAuth (별도 발급 불필요)

자비스의 Notion 작업보드·문서 허브 운영용.

### 동작 방식

- 서버 주소: `https://mcp.notion.com/mcp`
- 인증: OAuth 2.0 (브라우저 흐름)
- 토큰 환경변수: **불필요** — Claude Code가 자동 처리

### 첫 사용 절차

1. Claude Code 실행 후 노션 MCP 도구를 처음 호출하면 자동으로 브라우저 OAuth 창이 열린다.
2. 노션 계정 로그인 → "자비스" 워크스페이스 선택 → 권한 승인.
3. Claude Code가 토큰을 안전하게 보관 (사용자가 직접 다룰 필요 없음).

### 권한 범위 확인

자비스가 접근해야 하는 페이지·DB:
- 문서 허브 (에이전트 프롬프트, 설계서, SOP)
- 작업보드 DB (태스크/산출물/백로그)

OAuth 승인 시 위 페이지·DB가 포함된 워크스페이스를 명시적으로 선택해야 한다.

---

## 2. Google Drive MCP — 로컬 stdio, OAuth Desktop app

자비스의 자료 저장·공유·자동 백업용. npm 패키지 `@modelcontextprotocol/server-gdrive`로 실행.

### 전체 흐름 요약

```
1. Google Cloud Console에서 프로젝트 생성
2. Google Drive API 활성화
3. OAuth 클라이언트(Desktop app) 만들고 시크릿 JSON 다운로드
4. JSON을 ~/.gdrive-mcp/gcp-oauth.keys.json 으로 저장
5. .env에 경로 두 개 채우기 (GDRIVE_OAUTH_PATH, GDRIVE_CREDENTIALS_PATH)
6. Claude Code 첫 실행 시 브라우저 OAuth → refresh token 자동 저장
```

### 단계별 절차

#### Step 1. Google Cloud Console 프로젝트

1. https://console.cloud.google.com/ 접속.
2. 상단 프로젝트 선택기 → **새 프로젝트** → 이름: `jarvis-mcp` (자유) → 만들기.

#### Step 2. Drive API 활성화

1. 좌측 메뉴 → **API 및 서비스 → 라이브러리**.
2. "Google Drive API" 검색 → 클릭 → **사용** 버튼.

#### Step 3. OAuth 동의 화면 구성 (앱 최초 등록 시 1회)

1. **API 및 서비스 → OAuth 동의 화면**.
2. User Type: **외부(External)** 선택 → 만들기.
3. 필수 입력:
   - 앱 이름: `Jarvis MCP` (또는 자유)
   - 사용자 지원 이메일: 본인 이메일
   - 개발자 연락처: 본인 이메일
4. **범위(Scopes)** 단계 → "범위 추가" → `https://www.googleapis.com/auth/drive.readonly` (읽기 전용 우선 권장. 쓰기 권한이 필요하면 `drive.file` 또는 `drive` 추가).
5. **테스트 사용자** 단계 → 본인 Google 계정 이메일 추가.
6. 저장 후 게시 상태는 "테스트"로 둔다 (개인 용도면 충분).

#### Step 4. OAuth 클라이언트 ID 생성

1. **API 및 서비스 → 사용자 인증 정보 (Credentials)**.
2. 상단 **사용자 인증 정보 만들기 → OAuth 클라이언트 ID**.
3. 애플리케이션 유형: **데스크톱 앱(Desktop app)** 선택.
4. 이름: `Jarvis Desktop` (자유) → 만들기.
5. 생성 직후 표시되는 **JSON 다운로드** 버튼 클릭.

#### Step 5. 시크릿 파일 배치

```bash
# 시크릿 파일을 보관할 디렉토리 생성 (홈 디렉토리 하위, git 추적 밖)
mkdir -p ~/.gdrive-mcp

# 다운로드한 JSON을 다음 경로로 이동·이름 변경
mv ~/Downloads/client_secret_*.json ~/.gdrive-mcp/gcp-oauth.keys.json

# 파일 권한 본인만 읽기 가능하게
chmod 600 ~/.gdrive-mcp/gcp-oauth.keys.json
```

#### Step 6. .env 채우기

```bash
# 프로젝트 루트에서
cp .env.example .env

# .env 파일 열어 두 경로 수정:
# GDRIVE_OAUTH_PATH=/home/<username>/.gdrive-mcp/gcp-oauth.keys.json
# GDRIVE_CREDENTIALS_PATH=/home/<username>/.gdrive-mcp/.gdrive-server-credentials.json
```

`.env`는 `.gitignore` 처리되어 git에 올라가지 않는다.

#### Step 7. 최초 인증 (refresh token 발급)

Claude Code 첫 실행 후 GDrive MCP 도구를 처음 호출하면:

1. 터미널에 OAuth URL이 표시되거나 브라우저가 자동으로 열린다.
2. 본인 Google 계정 로그인 → 권한 동의.
3. MCP 서버가 refresh token을 `GDRIVE_CREDENTIALS_PATH` 경로에 저장한다.
4. 이후에는 자동으로 토큰 갱신 (재인증 불필요).

> 첫 실행 시 "이 앱은 검증되지 않았습니다" 경고가 나오면, **고급 → 안전하지 않은 페이지로 이동** 클릭. 본인이 만든 앱이므로 안전.

---

## 3. 토큰 검증 — 연결 확인

Claude Code 세션에서 다음을 실행하여 MCP 연결 상태 확인:

```
/mcp
```

`notion` 및 `gdrive` 항목이 모두 ✅ 연결 상태로 표시되면 성공.

---

## 4. 토큰 회수·재발급

### Notion
- 노션 워크스페이스 설정 → 통합(Integrations) → "Claude" 또는 "MCP" 항목 → 권한 해제 또는 재승인.

### Google Drive
- Google 계정 보안 설정 → "내 계정에 액세스할 수 있는 앱" → "Jarvis MCP" 액세스 권한 삭제.
- 또는 `~/.gdrive-mcp/.gdrive-server-credentials.json` 삭제 후 재인증.

---

## 5. 보안 체크리스트

작업 완료 후 반드시 확인:

- [ ] `.env`가 `.gitignore`에 포함되어 있는가? (`git status`에 안 잡혀야 함)
- [ ] `gcp-oauth.keys.json`이 git에 추적되지 않는가?
- [ ] `.gdrive-mcp/` 디렉토리 권한이 `700` (본인만)인가?
- [ ] `gcp-oauth.keys.json` 파일 권한이 `600` (본인만 읽기)인가?
- [ ] OAuth 동의 화면에서 권한 범위가 필요한 최소한인가? (읽기만 필요하면 `drive.readonly`)

---

## 6. 향후 추가 검토 MCP

자비스 v2 또는 Stage 2 진입 시 검토:

- **Gmail MCP**: 채널 CS 이메일 자동 응대용. GDrive와 동일한 Google Cloud 프로젝트 + OAuth 클라이언트로 재사용 가능.
- **Slack MCP**: 알림·협업.
- **Composio/Zapier hosted MCP**: 다수 도구 한 번에. 가입·토큰은 외부 발급.
- **Cello/채널 API**: 4채널 등록·재고는 별도 빌더 작업으로 자체 MCP 구현 가능.

---

## 참조 링크

- Claude Code MCP 문서: https://docs.claude.com/en/docs/claude-code/mcp
- 모델컨텍스트프로토콜 공식: https://modelcontextprotocol.io
- `@modelcontextprotocol/server-gdrive`: https://github.com/modelcontextprotocol/servers/tree/main/src/gdrive
- Notion MCP: https://developers.notion.com/docs/mcp
- Google Cloud Console: https://console.cloud.google.com/
