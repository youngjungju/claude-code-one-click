# =====================================================================
#  Claude Code 원클릭 설치 스크립트 - 본편 (Windows)
#
#  직접 실행하지 마세요 - install-windows.ps1(부트스트랩)이 UTF-8로
#  안전하게 받아서 실행합니다. 사용자 안내용 한 줄 명령:
#    irm https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-windows.ps1 | iex
#
#  자동으로 처리하는 것:
#    1. 32비트 PowerShell 함정 감지 (자동으로 64비트로 재실행)
#    2. 이미 설치돼 있는지 확인 (설치돼 있으면 다시 설치하지 않음)
#    3. Git for Windows 확인 (없으면 자동 설치 시도 - 선택사항)
#    4. Claude Code 공식 설치
#    5. PATH 자동 등록 (창을 새로 열 필요 없음)
#    6. ANTHROPIC_API_KEY 충돌 함정 감지
#    7. Node.js 확인 (없으면 winget으로 LTS 함께 설치 - 실패해도 계속 진행)
#    8. 설치 검증 후 Claude 바로 실행 (로그인 화면까지 연결)
# =====================================================================

# 한글이 깨지지 않도록 콘솔 출력 인코딩을 UTF-8로 전환
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Write-Step  ([string]$n, [string]$msg) { Write-Host ""; Write-Host "[$n] $msg" -ForegroundColor Cyan }
function Write-Ok    ([string]$msg) { Write-Host "  V $msg" -ForegroundColor Green }
function Write-Warn2 ([string]$msg) { Write-Host "  ! $msg" -ForegroundColor Yellow }

function Show-FailureGuide ([string]$reason) {
    Write-Host ""
    Write-Host "X 설치가 중간에 멈췄습니다." -ForegroundColor Red
    Write-Host "  이유: $reason" -ForegroundColor Red
    Write-Host ""
    Write-Host "이렇게 해결하세요:" -ForegroundColor White
    Write-Host "  1. 인터넷 연결을 확인하세요. (지역 차단 문제라면 VPN으로 미국/일본 접속 후 다시 시도)"
    Write-Host "  2. 그래도 안 되면 - 이 PowerShell 화면 전체를 마우스로 드래그해 복사한 뒤,"
    Write-Host "     claude.ai 웹 채팅에 붙여넣고 '설치하다 막혔어, 어떻게 해결해?' 라고 물어보세요."
    Write-Host "  3. 해결 후 아래 명령을 다시 실행하면 처음부터 다시 진행됩니다:"
    Write-Host "     irm https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-windows.ps1 | iex" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-ClaudeOneClickInstall {
    # 주의: 'Stop'을 쓰면 PS 5.1에서 winget 등 네이티브 명령이 stderr에 쓰는
    # 진행 메시지만으로 스크립트가 죽는다. 각 단계는 $LASTEXITCODE와
    # Test-Path로 명시적으로 검사하므로 'Continue'가 안전하다.
    $ErrorActionPreference = 'Continue'

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor White
    Write-Host "   Claude Code 원클릭 설치를 시작합니다" -ForegroundColor White
    Write-Host "==============================================" -ForegroundColor White

    # --- [1/6] 환경 확인 -------------------------------------------------
    Write-Step "1/7" "환경을 확인하는 중..."

    # 64비트 Windows인데 32비트(x86) PowerShell로 실행된 경우 → 64비트로 재실행
    if ($env:PROCESSOR_ARCHITEW6432) {
        # AMD64뿐 아니라 ARM64 Windows에서 x86 PowerShell을 연 경우도 포함
        Write-Warn2 "32비트 PowerShell(x86)이 감지되었습니다. 64비트 PowerShell로 자동 전환합니다..."
        $ps64 = Join-Path $env:WINDIR 'sysnative\WindowsPowerShell\v1.0\powershell.exe'
        & $ps64 -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-windows.ps1 | iex"
        return
    }
    if (-not [Environment]::Is64BitOperatingSystem) {
        Show-FailureGuide "Claude Code는 32비트 Windows를 지원하지 않습니다."
        return
    }
    Write-Ok "64비트 Windows 확인됨"

    $localBin   = Join-Path $env:USERPROFILE '.local\bin'
    $claudeExe  = Join-Path $localBin 'claude.exe'
    $retryCmd   = 'irm https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-windows.ps1 | iex'

    # --- [2/6] 이미 설치되어 있는지 확인 ---------------------------------
    Write-Step "2/7" "Claude Code가 이미 설치되어 있는지 확인하는 중..."
    $alreadyInstalled = $null
    $found = Get-Command claude -ErrorAction SilentlyContinue
    if ($found) { $alreadyInstalled = $found.Source }
    elseif (Test-Path $claudeExe) { $alreadyInstalled = $claudeExe }

    # 바이너리는 있는데 실행이 안 되면(이전 설치 실패 잔재) 재설치 대상으로 전환
    if ($alreadyInstalled) {
        $checkVer = $null
        try { $checkVer = & $alreadyInstalled --version 2>$null | Select-Object -First 1 } catch { }
        if (-not $checkVer) {
            Write-Warn2 "기존 설치($alreadyInstalled)가 손상되어 있어 다시 설치합니다."
            # 공식 설치 프로그램이 손상된 파일을 덮어쓰지 못할 수 있어 미리 제거.
            # 안전을 위해 사용자 .local\bin 안에 있는 파일만 지운다.
            if ($alreadyInstalled -like (Join-Path $localBin '*')) {
                Remove-Item $alreadyInstalled -Force -ErrorAction SilentlyContinue
            }
            $alreadyInstalled = $null
        }
    }

    if ($alreadyInstalled) {
        Write-Ok "이미 설치되어 있습니다: $alreadyInstalled"
        Write-Ok "설치 단계를 건너뜁니다."
    } else {
        Write-Ok "새로 설치를 진행합니다."
    }

    # --- [3/6] Git for Windows 확인 (선택사항) ----------------------------
    Write-Step "3/7" "Git for Windows를 확인하는 중... (없어도 설치는 계속됩니다)"
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Ok "Git 확인됨"
    } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Warn2 "Git이 없어 자동으로 설치합니다... (1~3분 걸립니다)"
        # stderr는 버림: PS 5.1에서 네이티브 stderr가 에러 레코드로 표시되는 노이즈 방지
        winget install --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements 2>$null
        if ($LASTEXITCODE -eq 0) {
            # 방금 설치된 Git을 현재 세션에서 바로 쓸 수 있게 PATH 반영
            $gitCmd = Join-Path $env:ProgramFiles 'Git\cmd'
            if (Test-Path $gitCmd) { $env:Path = "$env:Path;$gitCmd" }
            Write-Ok "Git 설치 완료"
        } else {
            Write-Warn2 "Git 자동 설치에 실패했지만 계속 진행합니다. (Git은 선택사항입니다)"
            Write-Warn2 "일부 기능을 위해 나중에 https://git-scm.com/downloads/win 에서 설치하는 것을 추천합니다."
        }
    } else {
        Write-Warn2 "Git이 설치되어 있지 않지만 계속 진행합니다. (Git은 선택사항입니다)"
        Write-Warn2 "일부 기능을 위해 나중에 https://git-scm.com/downloads/win 에서 설치하는 것을 추천합니다."
    }

    # --- [4/6] Claude Code 공식 설치 --------------------------------------
    if ($alreadyInstalled) {
        Write-Step "4/7" "설치 단계 건너뜀 (이미 설치됨)"
    } else {
        Write-Step "4/7" "Claude Code를 설치하는 중... (30초~2분 정도 걸립니다)"
        # 공식 설치 프로그램을 별도 프로세스에서 실행 (현재 창에 영향 없음)
        # 2>&1: 자식 프로세스의 stderr 출력이 에러 레코드로 튀지 않게 병합
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex" 2>&1 | ForEach-Object { "$_" }
        if ($LASTEXITCODE -ne 0) {
            Show-FailureGuide "공식 설치 프로그램 실행에 실패했습니다."
            return
        }
        Write-Ok "설치 완료"
    }

    # --- [5/6] PATH 자동 등록 + 함정 점검 ---------------------------------
    Write-Step "5/7" "PowerShell에서 'claude' 명령을 바로 쓸 수 있게 설정하는 중..."

    # 레지스트리를 직접 사용: [Environment]::Get/Set 방식은 %USERPROFILE% 같은
    # 참조를 실제 경로로 풀어버리고 값 타입을 REG_SZ로 강등시킴 (비가역 손상)
    try {
        $envKey  = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
        $rawPath = [string]$envKey.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        try { $pathKind = $envKey.GetValueKind('Path') }
        catch { $pathKind = [Microsoft.Win32.RegistryValueKind]::ExpandString }
        $pathParts = @($rawPath -split ';' | ForEach-Object { $_.TrimEnd('\') })
        if (($pathParts -notcontains $localBin.TrimEnd('\')) -and
            ($pathParts -notcontains '%USERPROFILE%\.local\bin')) {
            # 앞에 붙임: PATH 앞쪽에 깨진 claude가 남아있어도 새 설치가 우선되도록
            $newRawPath = if ($rawPath) { $localBin + ';' + $rawPath.TrimStart(';') } else { $localBin }
            $envKey.SetValue('Path', $newRawPath, $pathKind)
            Write-Ok "PATH에 영구 등록됨 (다음에 여는 모든 창에 적용)"
        } else {
            Write-Ok "PATH에 이미 등록되어 있음"
        }
        $envKey.Close()
    } catch {
        # 공식 설치 프로그램이 Windows에서는 스스로 User PATH를 등록하므로
        # 여기 실패해도 대부분 문제 없음 - 경고만 하고 계속 진행
        Write-Warn2 "PATH 영구 등록을 건너뜁니다 ($($_.Exception.Message))"
        Write-Warn2 "새 창에서 claude 명령이 안 되면 창을 닫고 다시 열어보세요."
    }
    if (-not (($env:Path -split ';' | ForEach-Object { $_.TrimEnd('\') }) -contains $localBin.TrimEnd('\'))) {
        $env:Path = "$localBin;$env:Path"
    }
    Write-Ok "이 창에서 바로 사용 가능하며, 새로 여는 창에도 자동 적용됩니다."

    # ANTHROPIC_API_KEY 함정: 구독 로그인을 덮어써서 'API Error 400'을 일으킴
    if ($env:ANTHROPIC_API_KEY) {
        Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
        Write-Warn2 "ANTHROPIC_API_KEY 환경변수가 발견되어 이번 세션에서 껐습니다."
    }
    foreach ($scope in 'User', 'Machine') {
        if ([Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY', $scope)) {
            Write-Warn2 "$scope 환경변수에 ANTHROPIC_API_KEY가 영구 저장되어 있습니다."
            Write-Warn2 "로그인 시 'organization disabled' 에러가 뜨면 이 변수를 삭제해야 합니다."
        }
    }

    # --- [6/7] Node.js 확인/설치 (보너스 - 실패해도 계속 진행) ------------
    Write-Step "6/7" "Node.js를 확인하는 중... (없으면 함께 설치합니다)"
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $nodeVer = $null
        try { $nodeVer = & node --version 2>$null } catch { }
        Write-Ok "Node.js $nodeVer - 이미 설치되어 있음"
    } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Warn2 "Node.js LTS를 설치합니다... (1~3분, 권한 확인 창이 뜨면 '예'를 누르세요)"
        winget install --id OpenJS.NodeJS.LTS -e --source winget --silent --accept-package-agreements --accept-source-agreements 2>$null
        if ($LASTEXITCODE -eq 0) {
            # 방금 설치된 Node를 현재 세션에서 바로 쓸 수 있게 PATH 반영
            $nodeDir = Join-Path $env:ProgramFiles 'nodejs'
            if ((Test-Path $nodeDir) -and -not (($env:Path -split ';') -contains $nodeDir)) {
                $env:Path = "$env:Path;$nodeDir"
            }
            $nodeVer = $null
            try { $nodeVer = & node --version 2>$null } catch { }
            if ($nodeVer) { Write-Ok "Node.js $nodeVer 설치 완료" }
            else { Write-Ok "Node.js 설치 완료 (새 창을 열면 node 명령을 쓸 수 있습니다)" }
        } else {
            Write-Warn2 "Node.js 자동 설치에 실패했지만 Claude Code 사용에는 문제 없습니다."
            Write-Warn2 "필요해지면 https://nodejs.org 에서 직접 설치할 수 있습니다."
        }
    } else {
        Write-Warn2 "자동 설치 도구(winget)가 없어 Node.js 설치를 건너뜁니다."
        Write-Warn2 "필요해지면 https://nodejs.org 에서 직접 설치할 수 있습니다."
    }

    # --- [7/7] 설치 검증 ---------------------------------------------------
    Write-Step "7/7" "설치가 잘 됐는지 확인하는 중..."

    # 방금 설치한 확실한 경로를 우선 사용 — PATH 어딘가의 다른(깨진) claude에 가려지지 않게
    $claudeCmd = $null
    if (Test-Path $claudeExe) { $claudeCmd = $claudeExe }
    else {
        $found = Get-Command claude -ErrorAction SilentlyContinue
        if ($found) { $claudeCmd = $found.Source }
    }

    if (-not $claudeCmd) {
        Show-FailureGuide "설치는 끝났지만 claude 실행 파일을 찾을 수 없습니다."
        return
    }

    $version = (& $claudeCmd --version 2>$null | Select-Object -First 1)
    if (-not $version) {
        Show-FailureGuide "claude --version 실행에 실패했습니다."
        return
    }
    Write-Ok "Claude Code $version 설치 확인!"

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "   설치 성공! 모든 설정이 끝났습니다." -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  앞으로는 PowerShell에 claude 라고만 입력하면 실행됩니다." -ForegroundColor White
    Write-Host "  * Pro / Max 등 유료 구독 계정이 필요합니다. (무료 계정 불가)"
    Write-Host ""

    # CLAUDE_NO_LAUNCH=1 로 실행하면 자동 실행을 건너뜀 (테스트용)
    if ($env:CLAUDE_NO_LAUNCH) {
        Write-Host "  PowerShell에 claude 를 입력해 시작하세요."
        return
    }
    Write-Host "  3초 후 Claude가 실행됩니다. 브라우저가 열리면 로그인하세요..."
    Write-Host ""
    Start-Sleep -Seconds 3

    # 실행 실패가 '설치 실패'로 오해되지 않도록 별도 try/catch로 처리
    try {
        & $claudeCmd
    } catch {
        Write-Warn2 "설치는 완료됐지만 자동 실행에 실패했습니다."
        Write-Warn2 "PowerShell 창을 새로 연 다음 claude 를 직접 입력해 시작하세요."
    }
}

try {
    Invoke-ClaudeOneClickInstall
} catch {
    Show-FailureGuide $_.Exception.Message
} finally {
    # iex로 실행되면 함수가 사용자 세션에 남으므로 뒷정리
    Remove-Item Function:\Invoke-ClaudeOneClickInstall, Function:\Show-FailureGuide, `
        Function:\Write-Step, Function:\Write-Ok, Function:\Write-Warn2 -ErrorAction SilentlyContinue
}
