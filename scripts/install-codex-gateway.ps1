param(
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

$startMarker = "# >>> codex gateway wrapper >>>"
$endMarker = "# <<< codex gateway wrapper <<<"
$profilePath = $PROFILE.CurrentUserCurrentHost

if ([string]::IsNullOrWhiteSpace($profilePath)) {
    throw "Cannot determine the current user's PowerShell profile path."
}

$profileDirectory = Split-Path -Parent $profilePath
if (-not (Test-Path -LiteralPath $profileDirectory)) {
    New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$content = [System.IO.File]::ReadAllText($profilePath)
$startCount = ([regex]::Matches($content, [regex]::Escape($startMarker))).Count
$endCount = ([regex]::Matches($content, [regex]::Escape($endMarker))).Count

if ($startCount -gt 1 -or $endCount -gt 1 -or $startCount -ne $endCount) {
    throw "The managed Codex gateway block in $profilePath is incomplete."
}

$managedPattern = "(?ms)^" + [regex]::Escape($startMarker) + ".*?^" + [regex]::Escape($endMarker) + "(?:\r?\n)?"
$contentWithoutBlock = [regex]::Replace($content, $managedPattern, "").TrimEnd()

function Backup-Profile {
    if ((Get-Item -LiteralPath $profilePath).Length -gt 0) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $backupPath = "$profilePath.codex-gateway.bak.$timestamp"
        Copy-Item -LiteralPath $profilePath -Destination $backupPath
        Write-Host "Backup created: $backupPath"
    }
}

if ($Uninstall) {
    if ($startCount -eq 0) {
        Write-Host "Codex gateway wrapper is not installed."
        return
    }

    Backup-Profile
    [System.IO.File]::WriteAllText($profilePath, $contentWithoutBlock + [Environment]::NewLine)
    Write-Host "Codex gateway wrapper removed from $profilePath."
    Write-Host "Restart PowerShell to apply the change."
    return
}

$managedBlock = @'
# >>> codex gateway wrapper >>>
# Override Codex with CODEX_MODEL / CODEX_BASE_URL / CODEX_API_KEY for this PowerShell session.
function global:codex {
    $gatewayArgs = @()

    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_MODEL)) {
        $gatewayArgs += @("-m", $env:CODEX_MODEL)
    }

    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_BASE_URL)) {
        $baseUrl = $env:CODEX_BASE_URL.Replace('"', '\"')
        $gatewayArgs += @("-c", "model_providers.gateway.base_url=`"$baseUrl`"")
    }

    $codexCommand = Get-Command codex -CommandType Application -ErrorAction Stop | Select-Object -First 1
    & $codexCommand.Source @gatewayArgs @args
}
# <<< codex gateway wrapper <<<
'@

$newContent = if ([string]::IsNullOrWhiteSpace($contentWithoutBlock)) {
    $managedBlock + [Environment]::NewLine
} else {
    $contentWithoutBlock + [Environment]::NewLine + [Environment]::NewLine + $managedBlock + [Environment]::NewLine
}

if ($newContent -ceq $content) {
    Write-Host "Codex gateway wrapper is already up to date: $profilePath"
    return
}

Backup-Profile
[System.IO.File]::WriteAllText($profilePath, $newContent)

Write-Host "Codex gateway wrapper installed in $profilePath."
Write-Host "Restart PowerShell, then run codex."

if (-not (Get-Command codex -CommandType Application -ErrorAction SilentlyContinue)) {
    Write-Host "Note: codex was not found. Install Codex CLI before using the wrapper."
}
