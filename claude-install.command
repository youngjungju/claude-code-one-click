#!/bin/bash
#
# Claude Code 원클릭 설치 실행기 (macOS)
# 더블클릭하면 터미널이 열리면서 설치가 자동으로 진행됩니다.
#
printf '\n  Claude Code 설치를 시작합니다. 잠시만 기다려주세요...\n'
if curl -fsSL https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-mac.sh | bash; then
  :
else
  printf '\n  설치가 정상적으로 끝나지 않았습니다. 위의 안내를 따라주세요.\n'
fi
printf '\n'
read -n 1 -s -r -p "  아무 키나 누르면 이 창을 닫아도 됩니다..."
printf '\n'
