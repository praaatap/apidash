# API Dash CLI & MCP Setup Script for Windows PowerShell
# This script sets up both CLI and MCP for global use

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   API Dash CLI & MCP Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Navigate to project root
Write-Host "[1/6] Setting project directory..." -ForegroundColor Yellow
Set-Location -Path $PSScriptRoot
Write-Host "      Current directory: $(Get-Location)" -ForegroundColor Gray
Write-Host ""

# Step 2: Get all dependencies
Write-Host "[2/6] Installing dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to install dependencies" -ForegroundColor Red
    pause
    exit 1
}
Write-Host ""

# Step 3: Activate CLI globally
Write-Host "[3/6] Activating CLI globally..." -ForegroundColor Yellow
dart pub global activate --source path packages/apidash_cli
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: CLI activation failed, continuing..." -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Activate MCP globally
Write-Host "[4/6] Activating MCP globally..." -ForegroundColor Yellow
dart pub global activate --source path packages/apidash_mcp
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: MCP activation failed, continuing..." -ForegroundColor Yellow
}
Write-Host ""

# Step 5: Add pub cache to PATH (user-level)
Write-Host "[5/6] Configuring PATH..." -ForegroundColor Yellow
$pubCachePath = "$env:USERPROFILE\AppData\Local\Pub\Cache\bin"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($currentPath -notlike "*$pubCachePath*") {
    $newPath = $currentPath + ";$pubCachePath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "      PATH updated (requires terminal restart)" -ForegroundColor Green
} else {
    Write-Host "      PATH already configured" -ForegroundColor Green
}
Write-Host ""

# Step 6: Verify installation
Write-Host "[6/6] Verifying installation..." -ForegroundColor Yellow
Write-Host ""
Write-Host "CLI Version:" -ForegroundColor Gray
apidash --version
Write-Host ""
Write-Host "MCP Help (first line):" -ForegroundColor Gray
apidash_mcp --help 2>&1 | Select-String "apidash_mcp"
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now use:" -ForegroundColor White
Write-Host "  - apidash (from anywhere)" -ForegroundColor Cyan
Write-Host "  - apidash_mcp (from anywhere)" -ForegroundColor Cyan
Write-Host ""
Write-Host "If commands are not found:" -ForegroundColor Yellow
Write-Host "  1. Restart your terminal" -ForegroundColor White
Write-Host "  2. Or manually add to PATH:" -ForegroundColor White
Write-Host "     $env:USERPROFILE\AppData\Local\Pub\Cache\bin" -ForegroundColor Gray
Write-Host ""

# List available commands
Write-Host "Quick Start:" -ForegroundColor Green
Write-Host "  apidash --version" -ForegroundColor Cyan
Write-Host "  apidash exec https://httpbin.org/get" -ForegroundColor Cyan
Write-Host "  apidash list" -ForegroundColor Cyan
Write-Host "  apidash mcp --workspace=`"path`"" -ForegroundColor Cyan
Write-Host ""

pause
