$installDir = "$HOME\AI-Pro-Arch"
$targetFile = "$installDir\script.ps1"
$sourceUrl = "https://raw.githubusercontent.com/abduznik/ai-pro-arch/main/script.ps1"

Write-Host "Installing Abduznik's AI Project Architect..." -ForegroundColor Cyan

# 1. Create Directory
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

# 2. Download Tool
try {
    Invoke-WebRequest -Uri $sourceUrl -OutFile $targetFile -ErrorAction Stop
} catch {
    Write-Host "Failed to download script from GitHub. Check your internet or URL." -ForegroundColor Red
    exit 1
}

# 3. Add to Profile
if (-not (Test-Path $PROFILE)) {
    New-Item -Type File -Path $PROFILE -Force | Out-Null
}

$loadCmd = ". '$targetFile'"
$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue

if ($profileContent -notlike "*$targetFile*") {
    Add-Content -Force $PROFILE "`n$loadCmd"
    Write-Host "Added to PowerShell profile." -ForegroundColor Green
} else {
    Write-Host "Already in profile." -ForegroundColor Yellow
}

# 4. Load for current session
Invoke-Expression $loadCmd

Write-Host "Success! Type 'ai-pro-arch' to start." -ForegroundColor Magenta
