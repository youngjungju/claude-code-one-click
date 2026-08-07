# =====================================================================
#  Claude Code One-Click Installer - Bootstrap (Windows)
#
#  Usage - paste this one line into PowerShell:
#    irm https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-windows.ps1 | iex
#
#  This bootstrap is intentionally ASCII-only. Windows PowerShell 5.1
#  decodes HTTP responses as ISO-8859-1 when the server omits a charset
#  header, which would corrupt Korean text. So this stage downloads the
#  real (Korean) installer as raw bytes and force-decodes it as UTF-8
#  before running it in the current session.
# =====================================================================

$mainUrl = 'https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-windows-main.ps1'

function Show-BootstrapHelp {
    Write-Host ""
    Write-Host "   1. Check your internet connection (or try a VPN - US/Japan)."
    Write-Host "   2. Copy this whole PowerShell window and paste it into a chat"
    Write-Host "      at https://claude.ai and ask for help."
    Write-Host "   3. Then run this command again:"
    Write-Host "      irm https://raw.githubusercontent.com/youngjungju/claude-code-one-click/main/install-windows.ps1 | iex" -ForegroundColor Cyan
    Write-Host ""
}

$text = $null
try {
    # Make sure TLS 1.2 is enabled (older Windows PowerShell defaults may lack it)
    try {
        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch { }

    # Corporate proxy support: send default credentials to the system proxy (fixes 407).
    # No-op when there is no proxy.
    try {
        if ([System.Net.WebRequest]::DefaultWebProxy) {
            [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
        }
    } catch { }

    $resp  = Invoke-WebRequest -UseBasicParsing -Uri $mainUrl -ErrorAction Stop
    $bytes = $resp.RawContentStream.ToArray()
    $text  = [System.Text.Encoding]::UTF8.GetString($bytes)
    # Strip the UTF-8 BOM character - iex treats it as part of the first token
    $text  = $text.TrimStart([char]0xFEFF)

    # Sanity check: captive portals / proxies / CDN error pages return HTML with HTTP 200.
    # Never feed that into Invoke-Expression.
    if ($text -notmatch 'Invoke-ClaudeOneClickInstall') {
        throw "Downloaded content is not the installer ($($bytes.Length) bytes). You may be behind a captive portal (hotel/cafe Wi-Fi login page) or a filtering proxy."
    }
} catch {
    Write-Host ""
    Write-Host "X  Download failed: $($_.Exception.Message)" -ForegroundColor Red
    Show-BootstrapHelp
    $text = $null
}

if ($text) {
    try {
        Invoke-Expression $text
    } catch {
        Write-Host ""
        Write-Host "X  The installer stopped unexpectedly: $($_.Exception.Message)" -ForegroundColor Red
        Show-BootstrapHelp
    }
}
Remove-Item Function:\Show-BootstrapHelp -ErrorAction SilentlyContinue
