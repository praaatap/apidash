# API Dash MCP Server

Model Context Protocol (MCP) server for API Dash - enable AI agents to execute and manage API requests programmatically.

## Overview

The API Dash MCP server exposes your API Dash workspace to AI assistants like Claude Desktop, VS Code Copilot, and Cursor. This allows you to:

- Run API tests directly from your chat conversation
- Inspect request definitions without leaving your IDE
- Execute entire collections and get structured results
- Manage environment variables through natural language

## Installation

### From Source

```bash
cd packages/apidash_mcp
dart pub get
```

## Configuration

### Preferred command

Use the standalone executable entrypoint:

```bash
dart run apidash_mcp --workspace /absolute/path/to/your/ui/workspace
```

If `--workspace` is omitted, MCP resolves workspace in this order:
1. `APIDASH_WORKSPACE_PATH`
2. local `.apidash/config.json`
3. global `~/.apidash/config.json`
4. default `~/.apidash`

### Claude Desktop

Add the MCP server to your Claude Desktop configuration:

**macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "apidash": {
      "command": "dart",
      "args": ["run", "apidash_mcp", "--workspace", "C:/path/to/ui-workspace"],
      "cwd": "/path/to/apidash/packages/apidash_mcp",
      "env": {
        "APIDASH_WORKSPACE_PATH": "C:/path/to/ui-workspace"
      }
    }
  }
}
```

### VS Code Copilot

Create a `.vscode/mcp.json` file in your workspace:

```json
{
  "servers": {
    "apidash": {
      "type": "stdio",
      "command": "dart",
      "args": ["run", "apidash_mcp", "--workspace", "${workspaceFolder}/.apidash"],
      "cwd": "${workspaceFolder}/packages/apidash_mcp",
      "env": {
        "APIDASH_WORKSPACE_PATH": "${workspaceFolder}/.apidash"
      }
    }
  }
}
```

### Cursor

Add to your Cursor settings (`.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "apidash": {
      "command": "dart",
      "args": ["run", "apidash_mcp", "--workspace", "/path/to/ui-workspace"],
      "cwd": "/path/to/apidash/packages/apidash_mcp",
      "env": {
        "APIDASH_WORKSPACE_PATH": "/path/to/ui-workspace"
      }
    }
  }
}
```

## Available Tools

### `list_collections`

List all collections in the workspace with their request count and active environment.

**Parameters:** None

**Example Response:**
```json
[
  {
    "id": "col_001",
    "name": "User API Tests",
    "requestCount": 5,
    "activeEnv": "staging"
  },
  {
    "id": "col_002",
    "name": "Auth Suite",
    "requestCount": 3,
    "activeEnv": "production"
  }
]
```

### `list_requests`

List all requests and folders in a collection.

**Parameters:**
- `collection_id` (required) - The collection ID to list

**Example:**
```json
{
  "collection_id": "col_001"
}
```

### `list_folder_requests`

List all requests inside a specific folder.

**Parameters:**
- `collection_id` (required) - The collection ID
- `folder_id` (required) - The folder ID to list

**Example:**
```json
{
  "collection_id": "col_001",
  "folder_id": "fld_501"
}
```

### `get_request_detail`

Get the complete definition of a saved request including environment chain.

**Parameters:**
- `collection_id` (required) - The collection ID
- `request_id` (required) - The request ID
- `folder_id` (optional) - The folder ID (if inside a folder)

**Example:**
```json
{
  "collection_id": "col_001",
  "request_id": "req_101"
}
```

### `exec_request`

Execute a saved or ad-hoc HTTP request.

**Parameters:**
- `request_id` (optional) - ID of a saved request (omit for ad-hoc)
- `collection_id` (optional) - Collection ID (required for saved requests)
- `folder_id` (optional) - Folder ID (if inside a folder)
- `url` (optional) - Request URL (for ad-hoc requests)
- `method` (optional) - HTTP method (default: GET)
- `headers` (optional) - Request headers as key-value pairs
- `body` (optional) - Request body
- `environment` (optional) - Environment to use

**Example (Saved Request):**
```json
{
  "request_id": "req_101",
  "collection_id": "col_001"
}
```

**Example (Ad-hoc):**
```json
{
  "url": "https://api.example.com/users",
  "method": "POST",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"name\":\"John\"}"
}
```

### `exec_collection`

Execute all requests in a collection.

**Parameters:**
- `collection_id` (required) - The collection ID to execute
- `environment` (optional) - Environment to use

**Example:**
```json
{
  "collection_id": "col_001",
  "environment": "production"
}
```

### `exec_folder`

Execute all requests inside a folder.

**Parameters:**
- `collection_id` (required) - The collection ID
- `folder_id` (required) - The folder ID to execute
- `environment` (optional) - Environment to use

**Example:**
```json
{
  "collection_id": "col_001",
  "folder_id": "fld_501",
  "environment": "staging"
}
```

### `list_environments`

List all available environments in the workspace.

**Parameters:** None

**Example Response:**
```json
["global", "staging", "production"]
```

## Available Resources

### Request Resource

Access saved requests as MCP resources.

**URI Pattern:** `apidash://requests/{collection_id}/{request_id}`

**Example:**
```
apidash://requests/col_001/req_101
```

### Environment Resource

Access environment variables as MCP resources.

**URI Pattern:** `apidash://environments/{environment_name}`

**Example:**
```
apidash://environments/production
```

## Usage Examples

### Conversation with AI Assistant

**User:** "Run the User API Tests collection against production and tell me which requests are failing."

**AI:** (Calls `exec_collection` with `collection_id: col_001, environment: production`)

**AI:** "I've executed all 5 requests in the User API Tests collection. Here are the results:
- ✓ Get all users - 200 OK (145ms)
- ✓ Get user by ID - 200 OK (98ms)
- ✗ Create user - 400 Bad Request (52ms) - Missing required field: email
- ✓ Update user - 200 OK (134ms)
- ✓ Delete user - 204 No Content (87ms)

One request failed: 'Create user' returned a 400 error because the email field is missing."

### Debugging API Issues

**User:** "Show me the details of the Login request"

**AI:** (Calls `get_request_detail` with the request ID)

**AI:** "Here's the Login request definition:
- Method: POST
- URL: {{BASE_URL}}/auth/login
- Headers: Content-Type: application/json
- Body: {\"username\": \"{{USERNAME}}\", \"password\": \"{{PASSWORD}}\"}
- Active environment chain: folder → production, collection → staging, global

The request uses environment variables for BASE_URL, USERNAME, and PASSWORD."

### Ad-hoc Testing

**User:** "Test the new users endpoint with a sample user"

**AI:** (Calls `exec_request` with ad-hoc parameters)

**AI:** "I've sent a POST request to /users with the following data:
```json
{
  "name": "Test User",
  "email": "test@example.com"
}
```

Response: 201 Created (234ms)
The user was created successfully with ID: usr_12345"

## Security

### Header Redaction

The MCP server automatically redacts sensitive headers from responses:
- `Authorization`
- `x-api-key`
- `Cookie`
- `Set-Cookie`

These headers are replaced with `[REDACTED]` in the response to prevent credentials from leaking into the AI's context.

### Workspace Access

The MCP server only has access to the workspace specified by `APIDASH_WORKSPACE_PATH`. It cannot access files outside this directory.

## Environment Variables

### `APIDASH_WORKSPACE_PATH`

Required. Specifies the path to the API Dash workspace.

```bash
export APIDASH_WORKSPACE_PATH=~/.apidash
```

## Troubleshooting

### "No workspace found"

Ensure `APIDASH_WORKSPACE_PATH` is set correctly in your MCP configuration:

```json
{
  "env": {
    "APIDASH_WORKSPACE_PATH": "~/.apidash"
  }
}
```

### "Collection not found"

Verify the collection ID exists:

```bash
apidash list
```

Or ask the AI: "List all my API Dash collections"

### Server Not Starting

Check that:
1. Dart SDK is installed and in PATH
2. You're in the correct working directory
3. All dependencies are installed: `dart pub get`

### Connection Issues

Restart your AI client after updating the MCP configuration. Some clients require a restart to pick up configuration changes.

## Architecture

The MCP server follows a six-layer architecture:

1. **Transport Layer** - Manages stdio communication
2. **Protocol Layer** - Handles MCP handshake and lifecycle
3. **Capability Registry** - Registers tools and resources
4. **Application Layer** - Translates MCP calls to API Dash operations
5. **Execution Layer** - Performs HTTP requests via `better_networking`
6. **Response Processor** - Formats and redacts responses

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](../../LICENSE) file for details.

## Contributing

Contributions are welcome! Please read our [Contributing Guide](../../CONTRIBUTING.md) for details.

## See Also

- [API Dash CLI](../apidash_cli/README.md) - Command-line interface for API Dash
- [API Dash HIS](../apidash_his/README.md) - Hierarchical Indexed Storage
- [Better Networking](../better_networking/README.md) - HTTP execution engine
