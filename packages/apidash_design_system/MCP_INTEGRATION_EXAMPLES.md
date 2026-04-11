# 🤖 MCP Integration Examples: VS Code & CLI

**Complete configuration examples for connecting AI assistants to API Dash**  
**Author**: Pratap Singh Sisodiya  
**Date**: March 31, 2026

---

## 📋 Table of Contents

1. [VS Code Integration](#vs-code-integration)
2. [CLI MCP Command](#cli-mcp-command)
3. [Claude Desktop Integration](#claude-desktop-integration)
4. [Cursor IDE Integration](#cursor-ide-integration)
5. [Troubleshooting](#troubleshooting)

---

## 💻 VS Code Integration

### Method 1: Project-Level Configuration (`.vscode/mcp.json`)

**Best for**: Project-specific MCP setup

**Create file**: `.vscode/mcp.json` in your project root

```json
{
  "servers": {
    "apidash": {
      "type": "stdio",
      "command": "apidash",
      "args": [
        "mcp"
      ],
      "env": {
        "APIDASH_WORKSPACE_PATH": "d:\\apidash-workspace"
      }
    }
  }
}
```

**How it works**:
- VS Code reads `.vscode/mcp.json` on project open
- Automatically starts MCP server when you open Copilot Chat
- Uses `apidash` command (must be in PATH)
- Sets workspace path via environment variable

---

### Method 2: User-Level Configuration (All Projects)

**Best for**: Global MCP setup across all projects

**Windows**: `%APPDATA%\Code\User\settings.json`  
**macOS**: `~/Library/Application Support/Code/User/settings.json`  
**Linux**: `~/.config/Code/User/settings.json`

**Add to settings.json**:
```json
{
  "mcp.servers": {
    "apidash": {
      "type": "stdio",
      "command": "apidash",
      "args": ["mcp"],
      "env": {
        "APIDASH_WORKSPACE_PATH": "d:\\apidash-workspace"
      }
    }
  }
}
```

---

### Method 3: Using Dart Directly (No Global Install)

**Best for**: Development without global activation

**.vscode/mcp.json**:
```json
{
  "servers": {
    "apidash": {
      "type": "stdio",
      "command": "dart",
      "args": [
        "run",
        "packages/apidash_cli/bin/apidash_cli.dart",
        "mcp"
      ],
      "env": {
        "APIDASH_WORKSPACE_PATH": "d:\\apidash-workspace"
      }
    }
  }
}
```

**Note**: Requires opening VS Code from project root directory.

---

### Method 4: Using Compiled Executable (Fastest)

**Best for**: Production use, fastest startup

**.vscode/mcp.json**:
```json
{
  "servers": {
    "apidash": {
      "type": "stdio",
      "command": "C:\\Users\\YourName\\AppData\\Local\\Pub\\Cache\\bin\\apidash.exe",
      "args": ["mcp"],
      "env": {
        "APIDASH_WORKSPACE_PATH": "d:\\apidash-workspace"
      }
    }
  }
}
```

---

### VS Code Configuration Examples

#### Example 1: Basic Setup
```json
{
  "servers": {
    "apidash": {
      "type": "stdio",
      "command": "apidash",
      "args": ["mcp"],
      "env": {
        "APIDASH_WORKSPACE_PATH": "C:\\Users\\prata\\apidash-workspace"
      }
    }
  }
}
```

#### Example 2: Multiple Workspaces
```json
{
  "servers": {
    "apidash-dev": {
      "type": "stdio",
      "command": "apidash",
      "args": ["mcp"],
      "env": {
        "APIDASH_WORKSPACE_PATH": "C:\\Users\\prata\\dev-workspace"
      }
    },
    "apidash-prod": {
      "type": "stdio",
      "command": "apidash",
      "args": ["mcp"],
      "env": {
        "APIDASH_WORKSPACE_PATH": "C:\\Users\\prata\\prod-workspace"
      }
    }
  }
}
```

#### Example 3: With Debug Logging
```json
{
  "servers": {
    "apidash": {
      "type": "stdio",
      "command": "apidash",
      "args": ["mcp", "--verbose"],
      "env": {
        "APIDASH_WORKSPACE_PATH": "C:\\Users\\prata\\workspace",
        "DEBUG": "true"
      }
    }
  }
}
```

---

## 🖥️ CLI MCP Command

### Basic Usage

```bash
# Start MCP server with default workspace
apidash mcp

# Start with specific workspace
apidash mcp --workspace="d:\apidash-workspace"

# Start in headless mode (for scripting)
apidash mcp --workspace="d:\workspace" --headless
```

### CLI MCP Configuration Examples

#### Example 1: Direct CLI Usage
```bash
# Start server
apidash mcp --workspace="d:\apidash-workspace"

# Expected output:
# APIDash MCP server v0.0.1-dev started successfully
# Workspace: d:\apidash-workspace
# The MCP server is now running on stdio.
```

#### Example 2: Using with Environment Variable
```bash
# Set workspace via environment
$env:APIDASH_WORKSPACE_PATH="d:\apidash-workspace"

# Start without --workspace flag
apidash mcp
```

#### Example 3: In CI/CD Pipeline
```yaml
# GitHub Actions example
- name: Start MCP Server
  run: |
    dart pub global activate --source path packages/apidash_mcp
    apidash mcp --workspace="${{ github.workspace }}/test-workspace" &
    
- name: Run AI Tests
  run: |
    # Your AI agent tests here
    # MCP server runs in background
```

#### Example 4: Docker Container
```dockerfile
FROM dart:latest

WORKDIR /app
COPY . .

RUN dart pub get
RUN dart compile exe bin/apidash_mcp.dart -o apidash_mcp

EXPOSE 8080

CMD ["./apidash_mcp", "--workspace", "/data/workspace"]
```

---

## 🤖 Claude Desktop Integration

**Config file**: `%APPDATA%\Claude\claude_desktop_config.json` (Windows)

```json
{
  "mcpServers": {
    "apidash": {
      "command": "apidash",
      "args": ["mcp"],
      "env": {
        "APIDASH_WORKSPACE_PATH": "C:\\Users\\prata\\apidash-workspace"
      }
    }
  }
}
```

**With full path**:
```json
{
  "mcpServers": {
    "apidash": {
      "command": "C:\\Users\\prata\\AppData\\Local\\Pub\\Cache\\bin\\apidash.exe",
      "args": ["mcp"],
      "env": {
        "APIDASH_WORKSPACE_PATH": "C:\\Users\\prata\\apidash-workspace"
      }
    }
  }
}
```

---

## 🎯 Cursor IDE Integration

**Settings → MCP → Add Server**:

```json
{
  "name": "apidash",
  "type": "stdio",
  "command": "apidash",
  "args": ["mcp"],
  "env": {
    "APIDASH_WORKSPACE_PATH": "C:\\Users\\prata\\apidash-workspace"
  }
}
```

---

## 🔧 Complete Configuration Reference

### All Available Options

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `type` | string | Yes | Must be `"stdio"` |
| `command` | string | Yes | Executable path (`apidash`, `dart`, or full path) |
| `args` | array | No | Command arguments (e.g., `["mcp"]`) |
| `env` | object | No | Environment variables |

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `APIDASH_WORKSPACE_PATH` | Workspace directory | `d:\apidash-workspace` |
| `DEBUG` | Enable debug logging | `true` |

---

## 🐛 Troubleshooting

### Problem: "Command not found"

**Solution 1**: Add to PATH
```bash
# Windows
setx PATH "%PATH%;%USERPROFILE%\AppData\Local\Pub\Cache\bin"
```

**Solution 2**: Use full path
```json
{
  "command": "C:\\Users\\YourName\\AppData\\Local\\Pub\\Cache\\bin\\apidash.exe"
}
```

---

### Problem: "Workspace not found"

**Solution**: Verify workspace exists
```bash
# Check if workspace exists
Test-Path "d:\apidash-workspace"

# Create if missing
mkdir d:\apidash-workspace
apidash init --path="d:\apidash-workspace"
```

---

### Problem: MCP server exits immediately

**Solution 1**: Check error logs
```bash
# Run with verbose output
apidash mcp --workspace="d:\workspace" --verbose
```

**Solution 2**: Check workspace permissions
```bash
# Ensure read/write access
icacls d:\apidash-workspace /grant Everyone:F
```

---

### Problem: VS Code doesn't detect MCP

**Solution 1**: Restart VS Code
```
1. Close all VS Code windows
2. Reopen VS Code
3. Open Command Palette (Ctrl+Shift+P)
4. Type: "MCP: List Servers"
```

**Solution 2**: Verify config location
```
# Windows
%APPDATA%\Code\User\settings.json

# Or project-level
.vscode/mcp.json
```

---

## 📊 Quick Copy-Paste Templates

### Template 1: Windows + Global Install
```json
{
  "servers": {
    "apidash": {
      "type": "stdio",
      "command": "apidash",
      "args": ["mcp"],
      "env": {
        "APIDASH_WORKSPACE_PATH": "C:\\Users\\YOUR_USERNAME\\apidash-workspace"
      }
    }
  }
}
```

### Template 2: Windows + Dart Direct
```json
{
  "servers": {
    "apidash": {
      "type": "stdio",
      "command": "dart",
      "args": [
        "run",
        "packages/apidash_cli/bin/apidash_cli.dart",
        "mcp"
      ],
      "env": {
        "APIDASH_WORKSPACE_PATH": "C:\\Users\\YOUR_USERNAME\\apidash-workspace"
      }
    }
  }
}
```

### Template 3: macOS/Linux
```json
{
  "servers": {
    "apidash": {
      "type": "stdio",
      "command": "apidash",
      "args": ["mcp"],
      "env": {
        "APIDASH_WORKSPACE_PATH": "/Users/YOUR_USERNAME/apidash-workspace"
      }
    }
  }
}
```

---

**Last Updated**: March 31, 2026  
**Status**: ✅ Production Ready  
**For**: GSoC 2026 - API Dash MCP Integration  
**Author**: Pratap Singh Sisodiya
