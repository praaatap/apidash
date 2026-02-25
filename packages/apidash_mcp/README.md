# API Dash MCP Server

An MCP (Model Context Protocol) server that exposes [API Dash](https://github.com/foss42/apidash)'s core HTTP capabilities to AI agents. Built in Dart using the official [`dart_mcp`](https://pub.dev/packages/dart_mcp) package and [`better_networking`](../better_networking/) for HTTP.

## What is MCP?

The [Model Context Protocol](https://modelcontextprotocol.io/) is a standard that allows AI applications (Claude Desktop, Cursor, VS Code, etc.) to connect to external tools and data sources. This package turns API Dash into an MCP server that AI agents can use to send and test API requests.

## Tools

| Tool | Description |
|------|-------------|
| `send_request` | Send an HTTP request (GET, POST, PUT, PATCH, DELETE, HEAD) and return the full response including status code, headers, body, and elapsed time. |
| `inspect_response` | Send a request and deeply inspect the response — returns content type, response size, headers, and a body preview (truncated to 500 chars). |
| `generate_curl` | Generate a cURL command string from the given request parameters. |

## Setup

### Prerequisites

- Dart SDK >= 3.0.0

### Install Dependencies

```bash
cd packages/apidash_mcp
dart pub get
```

### Run the Server

```bash
dart run bin/apidash_mcp.dart
```

The server starts using **stdio transport** (standard for local MCP servers).

## MCP Client Configuration

### Claude Desktop / Cursor / VS Code

Add the following to your MCP settings configuration:

```json
{
  "mcpServers": {
    "apidash": {
      "command": "dart",
      "args": ["run", "bin/apidash_mcp.dart"],
      "cwd": "<path-to-apidash>/packages/apidash_mcp"
    }
  }
}
```

## Tool Usage Examples

### send_request

```json
{
  "tool": "send_request",
  "arguments": {
    "url": "https://api.apidash.dev/",
    "method": "GET"
  }
}
```

**Response:**
```json
{
  "status_code": 200,
  "headers": { "content-type": "application/json" },
  "body": "{\"message\": \"Hello from API Dash!\"}",
  "elapsed_ms": 142
}
```

### inspect_response

```json
{
  "tool": "inspect_response",
  "arguments": {
    "url": "https://api.apidash.dev/",
    "method": "GET"
  }
}
```

**Response:**
```json
{
  "status_code": 200,
  "content_type": "application/json",
  "response_size_bytes": 1234,
  "elapsed_ms": 142,
  "headers": { "content-type": "application/json" },
  "body_preview": "{\"message\": \"Hello from API Dash!\"}"
}
```

### generate_curl

```json
{
  "tool": "generate_curl",
  "arguments": {
    "url": "https://api.apidash.dev/",
    "method": "POST",
    "headers": "{\"Content-Type\": \"application/json\"}",
    "body": "{\"key\": \"value\"}"
  }
}
```

**Response:**
```
curl -X POST 'https://api.apidash.dev/' -H 'Content-Type: application/json' -d '{"key": "value"}'
```

## Architecture

```
apidash_mcp/
├── bin/
│   └── apidash_mcp.dart     # Entry point (stdio transport)
├── lib/
│   ├── apidash_mcp.dart      # Library barrel file
│   └── src/
│       └── server.dart        # MCP server with tool implementations
├── pubspec.yaml
└── README.md
```

- **`dart_mcp`** — Official Dart MCP package for server/client implementation
- **`better_networking`** — API Dash's HTTP engine (`sendHttpRequest`, `HttpRequestModel`)
- **`seed`** — Shared types (`NameValueModel`, `HTTPVerb`, `ContentType`, etc.)

## License

This project is licensed under the [Apache License 2.0](../../LICENSE).
