# API Dash CLI

Command-line interface for API Dash - execute and manage API requests from the terminal without opening the GUI.

## ⚡ Quick Setup (No Downloads Every Time!)

**Problem**: Running `dart run packages/apidash_cli/bin/apidash_cli.dart` downloads dependencies every time.

**Solution**: Use one of these methods:

### Method 1: Use Setup Script (Easiest)

```powershell
# Windows PowerShell
cd d:\apidash
.\setup-cli.ps1

# Windows CMD
cd d:\apidash
setup-cli.bat
```

### Method 2: Manual Global Activation

```bash
# From API Dash project root
cd d:\apidash

# Activate globally (one-time)
dart pub global activate --source path packages/apidash_cli

# Add to PATH (Windows)
%USERPROFILE%\AppData\Local\Pub\Cache\bin

# Now use from anywhere - no more downloads!
apidash exec https://httpbin.org/get
```

### Method 3: Native Compilation (Fastest)

```bash
cd packages/apidash_cli
dart compile exe bin/apidash_cli.dart -o apidash
# Move apidash.exe to a folder in your PATH
```

See [CLI_SETUP_GUIDE.md](../../CLI_SETUP_GUIDE.md) for complete instructions.

---

## Installation

### From Source

```bash
cd packages/apidash_cli
dart pub get
dart compile exe bin/apidash_cli.dart -o apidash
```

### Add to PATH

Move the compiled executable to a directory in your PATH:

```bash
# Linux/macOS
mv apidash /usr/local/bin/

# Windows (PowerShell)
mv apidash.exe C:\Users\<YourUser>\AppData\Local\bin\
```

## Quick Start

### 1. Initialize a Workspace

```bash
# Initialize with default path (~/.apidash)
apidash init

# Initialize with custom path
apidash init --path ~/my-api-tests
```

### 2. Set Environment Variable (Optional)

```bash
export APIDASH_WORKSPACE_PATH=~/.apidash
```

### 3. Run Your First Request

```bash
# Execute an ad-hoc request
apidash exec https://api.example.com/users

# Execute with POST method
apidash exec https://api.example.com/users --method=POST --body='{"name":"John"}'

# Execute a saved collection
apidash run col_001
```

## Commands

### Global options

- `-w, --workspace <path>`: force workspace path for any command (including `mcp`), and sync it to shared APIDash workspace config.

### `apidash init` - Initialize Workspace

Create a new API Dash workspace with the required directory structure.

```bash
apidash init [--path <path>]
```

**Options:**
- `-p, --path` - Path where the workspace should be created (default: ~/.apidash)

**Example:**
```bash
apidash init --path ~/my-api-tests
```

### `apidash mcp` - Run MCP stdio server

Start MCP over stdio for VS Code / Claude / Cursor.

```bash
apidash mcp [--workspace <path>]
```

**Examples:**
```bash
# Use workspace resolved from config/env
apidash mcp

# Force the same workspace path used by UI
apidash mcp --workspace "C:/Users/you/.apidash"
```

### `apidash run` - Execute Collection/Folder

Run all requests in a collection or folder sequentially.

```bash
apidash run --collection <collection-id> [options]
```

**Options:**
- `-c, --collection` - Collection ID to execute (required)
- `-f, --folder` - Folder ID to execute (optional)
- `-r, --request` - Request ID to execute (optional)
- `-e, --env` - Environment to use (default: global)
- `-f, --format` - Output format: table, json (default: table)
- `-v, --verbose` - Enable verbose output

**Examples:**
```bash
# Run entire collection
apidash run --collection col_001

# Run specific folder
apidash run --collection col_001 --folder fld_501

# Run specific request
apidash run --collection col_001 --request req_101

# Run with production environment
apidash run --collection col_001 --env production

# Run with JSON output
apidash run --collection col_001 --format=json
```

### `apidash exec` - Execute Ad-hoc Request

Send a single HTTP request constructed from command-line arguments.

```bash
apidash exec <url> [options]
```

**Options:**
- `-m, --method` - HTTP method: GET, POST, PUT, DELETE, PATCH (default: GET)
- `-u, --url` - Request URL (required)
- `-H, --header` - Request header (can be repeated)
- `-d, --body` - Request body
- `-e, --env` - Environment to use for variable resolution
- `-f, --format` - Output format: table, json (default: table)
- `--save` - Save this request to the default collection
- `-n, --name` - Name for the saved request
- `-v, --verbose` - Enable verbose output

**Examples:**
```bash
# Simple GET request
apidash exec https://api.example.com/users

# POST with JSON body
apidash exec https://api.example.com/users \
  --method=POST \
  --header="Content-Type: application/json" \
  --body='{"name":"John","email":"john@example.com"}'

# With custom headers
apidash exec https://api.example.com/protected \
  --header="Authorization: Bearer token123" \
  --header="Accept: application/json"

# Save request for later use
apidash exec https://api.example.com/users --save --name="Get all users"

# Use environment variables
apidash exec https://{{BASE_URL}}/users --env production
```

### `apidash list` - List Collections/Requests

Display saved requests without executing them.

```bash
apidash list [options]
```

**Options:**
- `-c, --collection` - Collection ID to list
- `-f, --folder` - Folder ID to list
- `-r, --request` - Request ID to show details
- `-f, --format` - Output format: table, json (default: table)

**Examples:**
```bash
# List all collections
apidash list

# List requests in a collection
apidash list --collection col_001

# List requests in a folder
apidash list --collection col_001 --folder fld_501

# Show request details
apidash list --collection col_001 --request req_101

# JSON output
apidash list --collection col_001 --format=json
```

### `apidash env` - Manage Environments

Create, list, edit, and delete environment variable sets.

```bash
apidash env <subcommand> [options]
```

**Subcommands:**
- `list [name]` - List all environments or variables in an environment
- `create <name>` - Create a new environment
- `delete <name>` - Delete an environment
- `set <name> <key> <value>` - Set a variable in an environment
- `unset <name> <key>` - Remove a variable from an environment
- `use <name>` - Set active environment in workspace

**Examples:**
```bash
# List all environments
apidash env list

# List variables in production environment
apidash env list production

# Create new environment
apidash env create staging

# Set environment variables
apidash env set staging BASE_URL https://api.staging.com
apidash env set staging API_KEY staging-secret-key

# Remove a variable
apidash env unset staging API_KEY

# Delete environment
apidash env delete staging
```

## Environment Variables

### `APIDASH_WORKSPACE_PATH`

Specify the workspace path without running `apidash init`:

```bash
export APIDASH_WORKSPACE_PATH=~/my-api-tests
```

## Workspace Structure

The CLI uses Hierarchical Indexed Storage (HIS) - a file-based JSON storage system:

```
<workspace_path>/
├── .apidash/
│   ├── workspace.json       # Workspace settings
│   ├── meta.json            # Schema version
│   └── config.json          # Configuration file
│
├── collections/
│   ├── col_001/
│   │   ├── collection.json  # Collection index
│   │   ├── req_101.json     # Request file
│   │   └── fld_501/
│   │       ├── folder.json  # Folder index
│   │       └── req_201.json
│   └── col_002/
│       └── collection.json
│
└── environments/
    ├── global.json          # Global variables
    ├── staging.json         # Staging environment
    └── production.json      # Production environment
```

## Environment Variable Resolution

The CLI uses a three-level resolution chain:

1. **Folder level** - Variables from folder's active environment
2. **Collection level** - Variables from collection's active environment  
3. **Global level** - Variables from global.json (always applied as fallback)

**Example:**
```json
// environments/production.json
{
  "name": "production",
  "variables": [
    {"name": "BASE_URL", "value": "https://api.example.com", "enabled": true},
    {"name": "API_KEY", "value": "prod-secret", "enabled": true}
  ]
}
```

Use in requests:
```bash
apidash exec https://{{BASE_URL}}/users --env production
```

## Output Formats

### Table Format (Default)

Human-readable table output:

```
┌─────────────────────────────────────────────────────────────┐
│  Status: 200  |  Time: 145ms    |  Type: application/json   │
└─────────────────────────────────────────────────────────────┘

Response Body:
─────────────────────────────────────────────────────────────────
{
  "users": [...]
}
─────────────────────────────────────────────────────────────────
```

### JSON Format

Machine-readable JSON output:

```bash
apidash exec https://api.example.com/users --format=json
```

```json
{
  "statusCode": 200,
  "time": 145,
  "headers": {...},
  "body": "..."
}
```

### Verbose Mode

Full request and response details:

```bash
apidash exec https://api.example.com/users --verbose
```

## Integration with GUI

The CLI shares the same workspace format as the API Dash GUI:

1. **Create requests in GUI** → Execute them from CLI
2. **Create requests in CLI** → View them in GUI
3. **Shared environments** → Same variables across both interfaces

## Examples

### CI/CD Pipeline

```yaml
# .github/workflows/api-tests.yml
name: API Tests
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      
      - name: Install API Dash CLI
        run: |
          cd packages/apidash_cli
          dart pub get
          dart compile exe bin/apidash_cli.dart -o apidash
          mv apidash /usr/local/bin/
      
      - name: Run API Tests
        run: apidash run --collection col_001 --env production
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
apidash run --collection col_001 --env staging
if [ $? -ne 0 ]; then
  echo "API tests failed!"
  exit 1
fi
```

### Shell Script Automation

```bash
#!/bin/bash
# deploy-and-test.sh

# Deploy to staging
./deploy.sh staging

# Run API tests
apidash run --collection col_001 --env staging

# If successful, deploy to production
if [ $? -eq 0 ]; then
  ./deploy.sh production
  apidash run --collection col_001 --env production
fi
```

## Troubleshooting

### "No workspace found"

Run `apidash init` or set the `APIDASH_WORKSPACE_PATH` environment variable:

```bash
apidash init
# or
export APIDASH_WORKSPACE_PATH=~/.apidash
```

### "Collection not found"

List available collections:

```bash
apidash list
```

### "Environment not found"

List available environments:

```bash
apidash env list
```

### Variable Not Resolved

Check that the variable is defined in the correct environment:

```bash
apidash env list production
```

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](../../LICENSE) file for details.

## Contributing

Contributions are welcome! Please read our [Contributing Guide](../../CONTRIBUTING.md) for details.
