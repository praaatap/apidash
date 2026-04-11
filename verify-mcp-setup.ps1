# API Dash MCP Setup Verification Script
# This script verifies your MCP setup is working correctly

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   API Dash MCP Setup Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$workspace = "d:\apidash-mcp-workspace"

# Test 1: Check CLI installation
Write-Host "[Test 1/5] Checking CLI installation..." -ForegroundColor Yellow
try {
    $cliVersion = apidash --version 2>&1
    if ($cliVersion -like "*apidash_cli*") {
        Write-Host "  ✅ CLI installed: $cliVersion" -ForegroundColor Green
    } else {
        Write-Host "  ❌ CLI not found" -ForegroundColor Red
        Write-Host "  Fix: dart pub global activate --source path packages/apidash_cli" -ForegroundColor Gray
        exit 1
    }
} catch {
    Write-Host "  ❌ Error checking CLI: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 2: Check/Create workspace
Write-Host "[Test 2/5] Checking workspace..." -ForegroundColor Yellow
if (Test-Path $workspace) {
    Write-Host "  ✅ Workspace exists: $workspace" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Workspace not found. Creating..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $workspace -Force | Out-Null
        apidash init --path=$workspace | Out-Null
        Write-Host "  ✅ Workspace created" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Error creating workspace: $_" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Test 3: Check workspace data
Write-Host "[Test 3/5] Checking workspace data..." -ForegroundColor Yellow
try {
    $listOutput = apidash --workspace=$workspace list 2>&1
    if ($listOutput -like "*Collections*") {
        Write-Host "  ✅ Workspace has data" -ForegroundColor Green
        Write-Host "  $listOutput" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠️  Workspace is empty" -ForegroundColor Yellow
        Write-Host "  Tip: apidash exec https://httpbin.org/get --save" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ❌ Error listing collections: $_" -ForegroundColor Red
}
Write-Host ""

# Test 4: Check VS Code configuration
Write-Host "[Test 4/5] Checking VS Code configuration..." -ForegroundColor Yellow
$vscodeConfigPath = "$env:APPDATA\Code\User\settings.json"
if (Test-Path $vscodeConfigPath) {
    try {
        $config = Get-Content $vscodeConfigPath -Raw | ConvertFrom-Json
        if ($config."mcp.servers".apidash) {
            Write-Host "  ✅ VS Code MCP config found" -ForegroundColor Green
            $workspacePath = $config."mcp.servers".apidash.env.APIDASH_WORKSPACE_PATH
            Write-Host "  Workspace: $workspacePath" -ForegroundColor Gray
        } else {
            Write-Host "  ⚠️  MCP config not found in VS Code settings" -ForegroundColor Yellow
            Write-Host "  Fix: Add configuration to settings.json" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ⚠️  Could not read VS Code settings: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  VS Code settings not found" -ForegroundColor Yellow
    Write-Host "  Fix: Open VS Code and configure MCP" -ForegroundColor Gray
}
Write-Host ""

# Test 5: Test MCP server startup
Write-Host "[Test 5/5] Testing MCP server startup..." -ForegroundColor Yellow
try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "apidash"
    $psi.Arguments = "mcp --workspace=`"$workspace`""
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $process = [System.Diagnostics.Process]::Start($psi)
    $process.WaitForExit(3000)

    if ($process.HasExited) {
        $output = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()
        if ($output -like "*started successfully*" -or $output -like "*MCP server*") {
            Write-Host "  ✅ MCP server starts correctly" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  MCP server exited" -ForegroundColor Yellow
            Write-Host "  Output: $output" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✅ MCP server running (stopping test)" -ForegroundColor Green
        $process.Kill()
        $process.WaitForExit()
    }
} catch {
    Write-Host "  ❌ Error testing MCP server: $_" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Verification Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Workspace: $workspace" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Open VS Code" -ForegroundColor Gray
Write-Host "2. Press Ctrl+Shift+P" -ForegroundColor Gray
Write-Host "3. Type 'MCP: List Servers'" -ForegroundColor Gray
Write-Host "4. Verify APIDash is connected" -ForegroundColor Gray
Write-Host ""
Write-Host "Test Prompts in VS Code Chat:" -ForegroundColor Yellow
Write-Host '  - "List my API collections"' -ForegroundColor Gray
Write-Host '  - "Show requests in default collection"' -ForegroundColor Gray
Write-Host '  - "Execute the Get Request request"' -ForegroundColor Gray
Write-Host ""
