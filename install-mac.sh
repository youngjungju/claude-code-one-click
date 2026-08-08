#!/usr/bin/env bash
#
# Claude Code 원클릭 설치 스크립트 (macOS / Linux)
#
# 사용법 — 터미널에 아래 한 줄을 붙여넣고 Enter:
#   curl -fsSL https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-mac.sh | bash
#
# 이 스크립트가 자동으로 처리하는 것:
#   1. 이미 설치돼 있는지 확인 (설치돼 있으면 다시 설치하지 않음)
#   2. Claude Code 공식 설치
#   3. PATH 자동 등록 (~/.zshrc 또는 ~/.bashrc)
#   4. ANTHROPIC_API_KEY 충돌 함정 감지
#   5. Node.js 확인 (없으면 nvm으로 LTS 함께 설치 — 실패해도 계속 진행)
#   6. GitHub CLI, Vercel CLI 확인/설치 (선택 도구 — 실패해도 계속 진행)
#   7. 설치 검증 후 Claude 바로 실행 (로그인 화면까지 연결)
#
set -uo pipefail

# ── 출력 도우미 ──────────────────────────────────────────────
C_BOLD=$'\033[1m'
C_GREEN=$'\033[32m'
C_YELLOW=$'\033[33m'
C_RED=$'\033[31m'
C_CYAN=$'\033[36m'
C_RESET=$'\033[0m'

step()  { printf '\n%s[%s]%s %s\n' "$C_CYAN$C_BOLD" "$1" "$C_RESET" "$2"; }
ok()    { printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$1"; }
warn()  { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$1"; }

fail() {
  printf '\n%s✗ 설치가 중간에 멈췄습니다.%s\n' "$C_RED$C_BOLD" "$C_RESET"
  printf '  이유: %s\n\n' "$1"
  printf '%s이렇게 해결하세요:%s\n' "$C_BOLD" "$C_RESET"
  printf '  1. 인터넷 연결을 확인하세요. (해외 IP 차단 문제라면 VPN으로 미국/일본 접속 후 다시 시도)\n'
  printf '  2. 그래도 안 되면 — 이 터미널 화면 전체를 마우스로 드래그해 복사한 뒤,\n'
  printf '     claude.ai 웹 채팅에 붙여넣고 "설치하다 막혔어, 어떻게 해결해?"라고 물어보세요.\n'
  printf '  3. 해결 후 아래 명령을 다시 실행하면 처음부터 다시 진행됩니다:\n'
  printf '     %scurl -fsSL https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-mac.sh | bash%s\n\n' "$C_CYAN" "$C_RESET"
  exit 1
}

LOCAL_BIN="$HOME/.local/bin"
CLAUDE_BIN="$LOCAL_BIN/claude"
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

printf '\n%s══════════════════════════════════════════════%s\n' "$C_BOLD" "$C_RESET"
printf '%s   Claude Code 원클릭 설치를 시작합니다%s\n' "$C_BOLD" "$C_RESET"
printf '%s══════════════════════════════════════════════%s\n' "$C_BOLD" "$C_RESET"

# ── [1/5] 환경 확인 ─────────────────────────────────────────
step "1/7" "환경을 확인하는 중..."

OS_NAME="$(uname -s)"
case "$OS_NAME" in
  Darwin)
    # Claude Code는 macOS 13(Ventura) 이상 필요
    MAC_MAJOR="$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)"
    if [ -n "$MAC_MAJOR" ] && [ "$MAC_MAJOR" -lt 13 ] 2>/dev/null; then
      fail "이 Mac의 macOS 버전($(sw_vers -productVersion))이 너무 낮습니다. Claude Code는 macOS 13(Ventura) 이상이 필요합니다."
    fi
    ok "macOS 확인됨"
    ;;
  Linux)  ok "Linux 확인됨" ;;
  *)      fail "지원하지 않는 운영체제입니다 ($OS_NAME). Windows는 install-windows.ps1을 사용하세요." ;;
esac

command -v curl >/dev/null 2>&1 || fail "curl 명령을 찾을 수 없습니다."

# 이미 설치되어 있는지 확인 (+ 실제로 동작하는지 검증)
ALREADY_INSTALLED=""
BROKEN_INSTALL=""
if command -v claude >/dev/null 2>&1; then
  ALREADY_INSTALLED="$(command -v claude)"
elif [ -x "$CLAUDE_BIN" ]; then
  ALREADY_INSTALLED="$CLAUDE_BIN"
fi
# 바이너리는 있는데 실행이 안 되면(이전 설치 실패 잔재) 재설치 대상으로 전환
if [ -n "$ALREADY_INSTALLED" ] && ! "$ALREADY_INSTALLED" --version >/dev/null 2>&1; then
  BROKEN_INSTALL="$ALREADY_INSTALLED"
  ALREADY_INSTALLED=""
fi

# ── [2/5] Claude Code 설치 ──────────────────────────────────
if [ -n "$ALREADY_INSTALLED" ]; then
  step "2/7" "Claude Code가 이미 설치되어 있습니다 — 설치 단계를 건너뜁니다."
  ok "설치 위치: $ALREADY_INSTALLED"
  ok "버전: $("$ALREADY_INSTALLED" --version 2>/dev/null)"
else
  if [ -n "$BROKEN_INSTALL" ]; then
    step "2/7" "기존 설치가 손상되어 있어 다시 설치합니다... (30초~2분 정도 걸립니다)"
    warn "손상된 파일: $BROKEN_INSTALL"
    # 공식 설치 프로그램은 이 자리에 남은 손상된 파일을 덮어쓰지 못하므로 미리 제거.
    # 안전을 위해 $HOME/.local/bin 안에 있는 파일만 지운다.
    case "$BROKEN_INSTALL" in
      "$HOME/.local/bin/"*) rm -f "$BROKEN_INSTALL" ;;
    esac
  else
    step "2/7" "Claude Code를 설치하는 중... (30초~2분 정도 걸립니다)"
  fi
  if ! curl -fsSL https://claude.ai/install.sh | bash; then
    fail "공식 설치 프로그램 실행에 실패했습니다."
  fi
  ok "설치 완료"
fi

# ── [3/5] PATH 자동 등록 ────────────────────────────────────
step "3/7" "터미널에서 'claude' 명령을 바로 쓸 수 있게 설정하는 중..."

# 현재 세션에 즉시 적용
case ":$PATH:" in
  *":$LOCAL_BIN:"*) ;;
  *) export PATH="$LOCAL_BIN:$PATH" ;;
esac

# 셸 설정 파일에 영구 등록 (중복 추가 방지)
RC_FILES=()
case "${SHELL:-/bin/zsh}" in
  */zsh)  RC_FILES=("$HOME/.zshrc") ;;
  */bash)
    RC_FILES=("$HOME/.bashrc")
    # 주의: .bash_profile을 새로 만들면 기존 ~/.profile이 로그인 셸에서
    # 영원히 무시된다. 이미 있는 파일에만 쓰고, 없으면 ~/.profile 사용.
    if   [ -f "$HOME/.bash_profile" ]; then RC_FILES+=("$HOME/.bash_profile")
    elif [ -f "$HOME/.bash_login"   ]; then RC_FILES+=("$HOME/.bash_login")
    else                                    RC_FILES+=("$HOME/.profile")
    fi
    ;;
  *)      RC_FILES=("$HOME/.profile") ;;
esac

for rc in "${RC_FILES[@]}"; do
  # 주석 처리된 줄은 설정으로 치지 않음
  if [ -f "$rc" ] && grep -qsE '^[^#]*\.local/bin' "$rc"; then
    ok "$(basename "$rc") — 이미 설정되어 있음"
  elif printf '\n# Claude Code\n%s\n' "$PATH_LINE" >> "$rc" 2>/dev/null; then
    ok "$(basename "$rc") — PATH 설정 추가됨"
  else
    warn "$(basename "$rc") 에 쓸 수 없습니다 — 새 터미널에서 claude 명령이 안 될 수 있습니다."
  fi
done

# ── [4/5] 흔한 함정 점검 ────────────────────────────────────
step "4/7" "로그인을 방해하는 설정이 있는지 점검하는 중..."

if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  unset ANTHROPIC_API_KEY
  warn "ANTHROPIC_API_KEY 환경변수가 발견되어 이번 세션에서 껐습니다."
  warn "(이 변수가 켜져 있으면 구독 로그인이 막히고 'API Error 400' 이 뜰 수 있습니다)"
fi

for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
  if [ -f "$rc" ] && grep -qs 'ANTHROPIC_API_KEY' "$rc"; then
    warn "$(basename "$rc") 파일 안에 ANTHROPIC_API_KEY 설정이 있습니다."
    warn "로그인 시 'organization disabled' 에러가 뜨면 이 줄을 지워야 합니다."
  fi
done
ok "점검 완료"

# ── [5/7] Node.js 확인/설치 (보너스 — 실패해도 계속 진행) ────
step "5/7" "Node.js를 확인하는 중... (없으면 함께 설치합니다)"

if command -v node >/dev/null 2>&1; then
  ok "Node.js $(node --version 2>/dev/null) — 이미 설치되어 있음"
else
  printf '  Node.js LTS를 설치합니다... (1~3분 걸릴 수 있어요)\n'
  # nvm: 관리자 비밀번호 없이 사용자 폴더에 설치되는 표준 도구
  export NVM_DIR="$HOME/.nvm"
  if curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash >/dev/null 2>&1; then
    # nvm은 set -u 와 호환되지 않으므로 잠시 해제
    set +u
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install --lts >/dev/null 2>&1
    set -u
  fi
  if command -v node >/dev/null 2>&1; then
    ok "Node.js $(node --version 2>/dev/null) 설치 완료"
  else
    warn "Node.js 자동 설치에 실패했지만 Claude Code 사용에는 문제 없습니다."
    warn "필요해지면 https://nodejs.org 에서 직접 설치할 수 있습니다."
  fi
fi

# ── [6/7] GitHub CLI + Vercel CLI (보너스 — 실패해도 계속 진행) ──
step "6/7" "추가 개발 도구를 확인하는 중... (GitHub CLI, Vercel CLI)"

# GitHub CLI (gh)
install_gh_direct() {
  # Homebrew 없이 공식 바이너리를 ~/.local/bin에 설치 (관리자 비밀번호 불필요)
  GH_TAG="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null | grep -m1 '"tag_name"' | cut -d'"' -f4)"
  [ -n "$GH_TAG" ] || return 1
  case "$(uname -m)" in
    arm64|aarch64) GH_ARCH=arm64 ;;
    *)             GH_ARCH=amd64 ;;
  esac
  GH_TMP="$(mktemp -d)" || return 1
  if curl -fsSL -o "$GH_TMP/gh.zip" \
       "https://github.com/cli/cli/releases/download/${GH_TAG}/gh_${GH_TAG#v}_macOS_${GH_ARCH}.zip" \
     && unzip -q "$GH_TMP/gh.zip" -d "$GH_TMP" 2>/dev/null; then
    mkdir -p "$LOCAL_BIN"
    cp "$GH_TMP"/gh_*/bin/gh "$LOCAL_BIN/gh" 2>/dev/null && chmod +x "$LOCAL_BIN/gh"
  fi
  rm -rf "$GH_TMP"
  command -v gh >/dev/null 2>&1
}

if command -v gh >/dev/null 2>&1; then
  ok "GitHub CLI — 이미 설치되어 있음"
else
  printf '  GitHub CLI를 설치합니다...\n'
  GH_DONE=""
  if command -v brew >/dev/null 2>&1; then
    brew install gh >/dev/null 2>&1 && command -v gh >/dev/null 2>&1 && GH_DONE=1
  fi
  if [ -z "$GH_DONE" ] && [ "$OS_NAME" = "Darwin" ]; then
    install_gh_direct && GH_DONE=1
  fi
  if [ -n "$GH_DONE" ]; then
    ok "GitHub CLI 설치 완료"
  else
    warn "GitHub CLI 자동 설치에 실패했지만 계속 진행합니다. (https://cli.github.com)"
  fi
fi

# Vercel CLI (npm 필요 — Node.js 단계가 성공했을 때만 가능)
if command -v vercel >/dev/null 2>&1; then
  ok "Vercel CLI — 이미 설치되어 있음"
elif command -v npm >/dev/null 2>&1; then
  printf '  Vercel CLI를 설치합니다...\n'
  npm install -g vercel >/dev/null 2>&1
  if command -v vercel >/dev/null 2>&1; then
    ok "Vercel CLI 설치 완료"
  else
    warn "Vercel CLI 자동 설치에 실패했지만 계속 진행합니다. (https://vercel.com/docs/cli)"
  fi
else
  warn "Vercel CLI는 Node.js(npm)가 필요해서 건너뜁니다."
fi

# ── [7/7] 설치 검증 ─────────────────────────────────────────
step "7/7" "설치가 잘 됐는지 확인하는 중..."

CLAUDE_CMD=""
if command -v claude >/dev/null 2>&1; then
  CLAUDE_CMD="$(command -v claude)"
elif [ -x "$CLAUDE_BIN" ]; then
  CLAUDE_CMD="$CLAUDE_BIN"
fi
[ -n "$CLAUDE_CMD" ] || fail "설치는 끝났지만 claude 실행 파일을 찾을 수 없습니다."

VERSION="$("$CLAUDE_CMD" --version 2>/dev/null)" || fail "claude --version 실행에 실패했습니다."
ok "Claude Code $VERSION 설치 확인!"

printf '\n%s══════════════════════════════════════════════%s\n' "$C_GREEN$C_BOLD" "$C_RESET"
printf '%s   🎉 설치 성공! 모든 설정이 끝났습니다.%s\n' "$C_GREEN$C_BOLD" "$C_RESET"
printf '%s══════════════════════════════════════════════%s\n\n' "$C_GREEN$C_BOLD" "$C_RESET"
printf '  앞으로는 터미널에 %sclaude%s 라고만 입력하면 실행됩니다.\n' "$C_CYAN$C_BOLD" "$C_RESET"
printf '  ※ Pro / Max 등 유료 구독 계정이 필요합니다. (무료 계정 불가)\n'

# ── Claude 바로 실행 (로그인까지 연결) ──────────────────────
# CLAUDE_NO_LAUNCH=1 로 실행하면 자동 실행을 건너뜀 (테스트용)
if [ -z "${CLAUDE_NO_LAUNCH:-}" ] && [ -r /dev/tty ] && [ -w /dev/tty ]; then
  printf '\n  3초 후 Claude가 실행됩니다. 브라우저가 열리면 로그인하세요...\n\n'
  sleep 3
  # execfail: exec 실패 시 셸을 종료하지 않고 다음 줄로 진행하게 함
  shopt -s execfail 2>/dev/null || true
  exec "$CLAUDE_CMD" </dev/tty
  # exec가 실패한 경우에만 여기 도달함 — 설치 자체는 이미 성공한 상태
  warn "설치는 완료됐지만 자동 실행에 실패했습니다."
  printf '  터미널 창을 새로 연 다음 %sclaude%s 를 입력해 시작하세요.\n\n' "$C_CYAN$C_BOLD" "$C_RESET"
else
  printf '\n  터미널 창을 새로 연 다음 %sclaude%s 를 입력해 시작하세요.\n\n' "$C_CYAN$C_BOLD" "$C_RESET"
fi
