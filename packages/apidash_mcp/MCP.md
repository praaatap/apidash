# API Dash MCP Server - Implementation & Usage

This document explains the technical architecture, tool definitions, and resource schemas of the API Dash MCP server.

## Overview

The API Dash MCP server implements the Model Context Protocol (MCP) to bridge AI agents (like Claude, VS Code Copilot, or Cursor) with the API Dash workspace. It allows agents to perform complex API operations, inspect requests, and manage environments using natural language.

## Core Components

### 1. Transport Layer (`stdio`)
The server communicates over standard input/output. All logs intended for humans are redirected to `stderr` to prevent corruption of the JSON-RPC stream on `stdout`.

### 2. Workspace Resolution
The server resolves the workspace path in the following priority:
1. `--workspace` CLI argument.
2. `APIDASH_WORKSPACE_PATH` environment variable.
3. Automatic discovery via `StorageService`.

### 3. Storage Engine (`apidash_shared_storage`)
Uses a shared instance of `StorageService` (Hive-based) across all tool handlers to ensure performance and data consistency.

### 4. Networking Engine (`better_networking`)
Requests are executed using the same engine as the GUI and CLI, ensuring consistent behavior across all interfaces.

## Tool Definitions

The server exposes the following tools to the agent:

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `list_collections` | Lists all collections in the workspace. | None |
| `list_requests` | Lists requests within a collection. | `collection_id` |
| `get_request_detail`| Full definition of a saved request. | `collection_id`, `request_id` |
| `exec_request` | Executes a saved or ad-hoc request. | `request_id` OR `url`, `method`, `body`, etc. |
| `exec_collection` | Sequentially runs an entire collection. | `collection_id`, `environment` |
| `exec_folder` | Sequentially runs a specific folder. | `collection_id`, `folder_id` |
| `list_environments` | Lists available environments. | None |
| `get_environment_variables` | Retrieves variables for an env. | `environment_name` |

## Resource Schemas

Resources provide read-only context to the agent.

### Requests
**URI:** `apidash://requests/{collection_id}/{request_id}`
**Content:** JSON definition of the request including headers, body, and auth.

### Environments
**URI:** `apidash://environments/{environment_name}`
**Content:** Key-value pairs defined in the environment.

### Workspace Configuration
**URI:** `apidash://workspace/config`
**Content:** Global settings and versioning information.

### Collection Index
**URI:** `apidash://collections/{collection_id}/index`
**Content:** A flat list of all request metadata in a collection.

## Prompts (Workflows)

Prompts guide the AI through multi-step tasks:

- **Run Collection:** Helps execute and summarize results for a suite of tests.
- **Debug Request:** Assists in identifying why a request is failing.
- **Compare Environments:** Checks for discrepancies between `staging` and `production`.
- **Create Request:** Scaffolds a new API request from requirements.
- **Generate Test Plan:** Designs a comprehensive testing strategy for an API.
- **Security Audit:** Identifies common security pitfalls in a request.
- **Optimize Payload:** Suggests improvements for body formatting and headers.
- **Explain Collection:** Summarizes the overall purpose of a collection.

## Security & Privacy

### Header Redaction
Sensitive headers (`Authorization`, `Cookie`, `x-api-key`) are automatically redacted from the response body returned to the agent to prevent credential leakage.

### Read-Only Mode
If the API Dash GUI is currently open and holding a lock on the Hive boxes, the MCP server automatically falls back to a read-only mode using a temporary storage sync to avoid data corruption.
