# 유지보수 가이드 (Maintainers)

## 파일 구조와 절대 깨면 안 되는 인코딩 불변식

| 파일 | 불변식 | 깨지면 생기는 일 |
|---|---|---|
| `install-windows.ps1` (부트스트랩) | **순수 ASCII 전용 — 한글 절대 금지** | PS 5.1 `irm`이 charset 없는 응답을 ISO-8859-1로 디코딩 → 한글 전부 깨짐 |
| `install-windows-main.ps1` (본편) | **UTF-8 with BOM 유지** | 로컬/-File 실행 시 한글 깨짐 |
| `claude-install.bat` | **ASCII + CRLF 유지, 한글 금지** | cmd는 CP949라 한글 깨짐 |
| `install-mac.sh` | UTF-8 (BOM 없음) + LF | — |

편집 후 확인 명령 (macOS):

```bash
LC_ALL=C grep -q '[^ -~\t\r]' install-windows.ps1 && echo "FAIL: non-ASCII" || echo OK
head -c 3 install-windows-main.ps1 | xxd | head -1   # efbbbf 이어야 함
file claude-install.bat                                # CRLF 이어야 함
bash -n install-mac.sh && shellcheck install-mac.sh
```

## Windows가 2단 구조인 이유

Windows PowerShell 5.1의 `irm`은 서버가 charset을 명시하지 않으면 ISO-8859-1로 디코딩하고, `iex`는 선행 BOM 문자를 토큰으로 취급한다. 그래서 ASCII 부트스트랩이 본편을 **바이트로 받아 UTF-8로 강제 디코딩 + BOM 제거** 후 실행한다. raw.githubusercontent.com은 `charset=utf-8`을 보내주지만, 이 구조 덕에 어떤 미러/프록시 뒤에서도 안전하다.

## 실기기 테스트 체크리스트 (Windows, 약 10분)

1. **한 줄 설치**: `irm https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-windows.ps1 | iex`
   - [ ] 한글 안 깨짐, `[1/7]`~`[7/7]` 진행
   - [ ] Git 없을 때 winget 자동 설치 시도, 실패해도 계속 진행
   - [ ] 성공 배너 → 3초 후 claude 실행 → 브라우저 로그인
   - [ ] 같은 창 + 새 창 모두에서 `claude --version` 동작
2. **멱등성**: 재실행 시 "이미 설치되어 있습니다" → 재설치 없음, User Path에 `.local\bin` 중복 없음
3. **레지스트리 보존**: `(Get-Item HKCU:\Environment).GetValueKind('Path')` 가 원래 타입(`ExpandString`) 유지
4. **bat 경로**: 다운로드 → 브라우저 Keep → SmartScreen "추가 정보→실행" → 정상 진행, 끝나고 창 유지
5. **손상 복구**: `Set-Content "$env:USERPROFILE\.local\bin\claude.exe" 'broken'` 후 재실행 → 손상 감지 → 재설치 → 성공

## 스크립트가 자동 처리하는 함정 목록

- PS 5.1 `EAP=Stop` + 네이티브 stderr(winget) 즉사 → `Continue` + 명시적 검사
- User PATH `[Environment]::Set...`의 REG_SZ 강등/`%VAR%` 파괴 → 레지스트리 직접 기록(타입 보존, 프리펜드)
- 32비트 PowerShell(x86/ARM64) → sysnative로 자동 재실행
- `ANTHROPIC_API_KEY`가 구독 OAuth를 덮어쓰는 400 에러 → 세션 제거 + 영구 변수 경고
- macOS: `.bash_profile` 신규 생성 시 `~/.profile` 차단 → 기존 파일에만 추가
- macOS: 공식 설치 프로그램이 손상된 `~/.local/bin/claude`를 덮어쓰지 못함 → 사전 제거 후 재설치
- macOS 13 미만 / 32비트 Windows 조기 차단
- 캡티브 포털/프록시가 반환한 HTML을 iex하지 않도록 부트스트랩에서 내용 검증
- Node.js 보너스 설치(Mac: nvm v0.40.6 고정 / Windows: winget OpenJS.NodeJS.LTS) — **실패해도 반드시 계속 진행** (경고만). nvm은 `set -u`와 비호환이라 소싱 전후로 `set +u`/`set -u` 전환 필수
