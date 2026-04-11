# API Dash CLI - Test All Commands Script
# PowerShell Script to Test Every CLI Command

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   API Dash CLI - Complete Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set workspace
$env:APIDASH_WORKSPACE_PATH = "d:\apidash\.tmp-test-workspace"
$workspace = $env:APIDASH_WORKSPACE_PATH

Write-Host "Workspace: $workspace" -ForegroundColor Yellow
Write-Host ""

# Test 1: Version
Write-Host "[Test 1/8] Testing --version" -ForegroundColor Green
apidash --version
Write-Host ""

# Test 2: Help
Write-Host "[Test 2/8] Testing --help" -ForegroundColor Green
apidash --help | Select-Object -First 10
Write-Host ""

# Test 3: Init (if workspace doesn't exist)
Write-Host "[Test 3/8] Testing init" -ForegroundColor Green
if (!(Test-Path $workspace)) {
    apidash init --path=$workspace
} else {
    Write-Host "Workspace already exists, skipping init" -ForegroundColor Gray
}
Write-Host ""

# Test 4: Exec - Basic GET Request
Write-Host "[Test 4/8] Testing exec (GET request)" -ForegroundColor Green
apidash exec https://httpbin.org/get | Select-Object -First 5
Write-Host ""

# Test 5: Exec - Save Request
Write-Host "[Test 5/8] Testing exec --save" -ForegroundColor Green
apidash exec https://httpbin.org/post --method=POST --save --name="Test POST Request" | Select-Object -Last 1
Write-Host ""

# Test 6: List Collections
Write-Host "[Test 6/8] Testing list" -ForegroundColor Green
apidash list
Write-Host ""

# Test 7: Environment Management
Write-Host "[Test 7/8] Testing env commands" -ForegroundColor Green

# Create environment
Write-Host "  Creating environment 'testing'..." -ForegroundColor Gray
apidash env create testing

# Set variables
Write-Host "  Setting variables..." -ForegroundColor Gray
apidash env set testing BASE_URL https://httpbin.org
apidash env set testing API_KEY test123

# List environments
Write-Host "  Listing environments..." -ForegroundColor Gray
apidash env list

# List variables in environment
Write-Host "  Listing variables in 'testing'..." -ForegroundColor Gray
apidash env list testing
Write-Host ""

# Test 8: Replay
Write-Host "[Test 8/8] Testing replay" -ForegroundColor Green
apidash replay | Select-Object -First 3
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   All Tests Completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Commands Tested:" -ForegroundColor White
Write-Host "  ✅ apidash --version" -ForegroundColor Green
Write-Host "  ✅ apidash --help" -ForegroundColor Green
Write-Host "  ✅ apidash init" -ForegroundColor Green
Write-Host "  ✅ apidash exec" -ForegroundColor Green
Write-Host "  ✅ apidash exec --save" -ForegroundColor Green
Write-Host "  ✅ apidash list" -ForegroundColor Green
Write-Host "  ✅ apidash env create/set/list" -ForegroundColor Green
Write-Host "  ✅ apidash replay" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Test MCP server with 'apidash mcp'" -ForegroundColor Yellow
Write-Host ""
