@echo off
REM API Dash CLI & MCP Setup Script for Windows
REM This script sets up both CLI and MCP for global use

echo ============================================
echo    API Dash CLI & MCP Setup
echo ============================================
echo.

REM Step 1: Navigate to project root
echo [1/5] Setting project directory...
cd /d "%~dp0"
echo       Current directory: %CD%
echo.

REM Step 2: Get all dependencies
echo [2/5] Installing dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)
echo.

REM Step 3: Activate CLI globally
echo [3/5] Activating CLI globally...
call dart pub global activate --source path packages/apidash_cli
if %errorlevel% neq 0 (
    echo WARNING: CLI activation failed, continuing...
)
echo.

REM Step 4: Activate MCP globally
echo [4/5] Activating MCP globally...
call dart pub global activate --source path packages/apidash_mcp
if %errorlevel% neq 0 (
    echo WARNING: MCP activation failed, continuing...
)
echo.

REM Step 5: Verify installation
echo [5/5] Verifying installation...
echo.
echo CLI Version:
call apidash --version
echo.
echo MCP Help (first line):
call apidash_mcp --help 2>&1 | findstr /C:"apidash_mcp"
echo.

echo ============================================
echo    Setup Complete!
echo ============================================
echo.
echo You can now use:
echo   - apidash (from anywhere)
echo   - apidash_mcp (from anywhere)
echo.
echo If commands are not found, add this to your PATH:
echo   %%USERPROFILE%%\AppData\Local\Pub\Cache\bin
echo.
pause
