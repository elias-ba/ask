# ask installer for Windows
# REQUIRES PowerShell 7+

$ErrorActionPreference = 'Stop'

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -lt 7) {
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host "  ERROR: POWERSHELL 7+ REQUIRED" -ForegroundColor Red
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "You have PowerShell $($psVersion.ToString())" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ask requires PowerShell 7+ for:" -ForegroundColor White
    Write-Host "  • UTF-8 support" -ForegroundColor Gray
    Write-Host "  • Better performance" -ForegroundColor Gray
    Write-Host "  • Cross-platform compatibility" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Download PowerShell 7:" -ForegroundColor Cyan
    Write-Host "  https://aka.ms/powershell" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Or use Git Bash with the bash version:" -ForegroundColor Cyan
    Write-Host "  1. Install Git for Windows" -ForegroundColor Gray
    Write-Host "  2. Open Git Bash" -ForegroundColor Gray
    Write-Host "  3. Run: curl -fsSL https://raw.githubusercontent.com/MilkCoder26/ask/main/install.sh | bash" -ForegroundColor Blue
    exit 1
}

# Banner
Write-Host "            _    " -ForegroundColor Cyan
Write-Host "   __ _ ___| | __" -ForegroundColor Cyan
Write-Host "  / _` / __| |/ /" -ForegroundColor Cyan
Write-Host " | (_| \__ \   < " -ForegroundColor Cyan
Write-Host "  \__,_|___/_|\_\" -ForegroundColor Cyan
Write-Host ""
Write-Host "ask - ai powered shell assistant" -ForegroundColor Cyan
Write-Host "don't grep. don't awk. just ask" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ PowerShell $($psVersion.ToString()) detected" -ForegroundColor Green
Write-Host ""

# Get download URL
$askUrl = "https://raw.githubusercontent.com/MilkCoder26/ask/main/ask.ps1"

# Ask for installation directory
Write-Host "Where should ask be installed?" -ForegroundColor Yellow
Write-Host "  1) %USERPROFILE%\Scripts (recommended)" -ForegroundColor White
Write-Host "  2) Custom directory" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Choice [1-2] (default: 1)"
$installDir = if ($choice -eq "2") {
    $customDir = Read-Host "Enter full path (e.g., C:\Tools)"
    if (-not (Test-Path $customDir)) {
        New-Item -ItemType Directory -Path $customDir -Force | Out-Null
        Write-Host "Created directory: $customDir" -ForegroundColor Green
    }
    $customDir
} else {
    $userScripts = "$env:USERPROFILE\Scripts"
    if (-not (Test-Path $userScripts)) {
        New-Item -ItemType Directory -Path $userScripts -Force | Out-Null
        Write-Host "Created directory: $userScripts" -ForegroundColor Green
    }
    $userScripts
}

# Download ask.ps1
$askPath = Join-Path $installDir "ask.ps1"
Write-Host ""
Write-Host "📥 Downloading ask.ps1..." -ForegroundColor Yellow

try {
    Invoke-RestMethod -Uri $askUrl -OutFile $askPath
    Write-Host "✓ Downloaded: $askPath" -ForegroundColor Green
} catch {
    Write-Host "✗ Download failed: $_" -ForegroundColor Red
    exit 1
}

# Add to PATH
Write-Host ""
Write-Host "🛤️  Adding to PATH..." -ForegroundColor Yellow

$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notmatch [Regex]::Escape($installDir)) {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installDir", "User")
    Write-Host "✓ Added to PATH" -ForegroundColor Green
} else {
    Write-Host "✓ Already in PATH" -ForegroundColor Green
}

# Instructions
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "✅ INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "To use ask:" -ForegroundColor Yellow
Write-Host "  1. Open a NEW PowerShell window" -ForegroundColor White
Write-Host "  2. Run pwsh in the terminal" -ForegroundColor White
Write-Host "  3. Run: ask 'your question'" -ForegroundColor Cyan
Write-Host ""
Write-Host "First steps:" -ForegroundColor Yellow
Write-Host "  ask keys set anthropic    # Set API key" -ForegroundColor Cyan
Write-Host "  ask 'hello world'         # Test it" -ForegroundColor Cyan
Write-Host "  ask --help                # Show help" -ForegroundColor Cyan
Write-Host ""
Write-Host ""
Write-Host "Documentation: https://elias-ba.github.io/ask/" -ForegroundColor Blue
Write-Host "GitHub: https://github.com/elias-ba/ask" -ForegroundColor Blue

# # Optional: Create simple function in current session
# Write-Host ""
# $createAlias = Read-Host "Create temporary alias 'ask' for this session? [y/N]"
# if ($createAlias -match '^[Yy]') {
#     function global:ask {
#         & $askPath @args
#     }
#     Write-Host "✓ Alias created for this session: 'ask'" -ForegroundColor Green
#     Write-Host "  Test: ask 'hello'" -ForegroundColor Cyan
# }