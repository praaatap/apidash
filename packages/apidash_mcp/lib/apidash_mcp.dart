/// MCP Server for API Dash
///
/// This library provides the Model Context Protocol (MCP) server for API Dash,
/// enabling AI agents to interact with API collections and execute requests.
/// 
/// The server exposes:
/// - **Tools**: Functions for executing requests, listing collections, etc.
/// - **Resources**: Access to saved requests and environments via URIs
/// - **Prompts**: Pre-defined prompts for common API testing workflows
library apidash_mcp;

// Runner
export 'src/runner.dart' show runServer;

// Tools
export 'src/tools/list_collections_tool.dart'
    show listCollectionsFromWorkspace, CollectionSummary, registerListCollectionsTool;
export 'src/tools/list_requests_tool.dart'
    show listRequestsFromCollection, RequestSummary, registerListRequestsTool;
export 'src/tools/get_request_detail_tool.dart'
    show getRequestDetail, RequestDetail, registerGetRequestDetailTool;
export 'src/tools/exec_request_tool.dart'
    show executeRequest, registerExecRequestTool;
export 'src/tools/exec_collection_tool.dart'
    show executeCollection, RequestExecutionResult, registerExecCollectionTool;
export 'src/tools/exec_folder_tool.dart'
    show executeFolder, FolderRequestResult, registerExecFolderTool;
export 'src/tools/list_environments_tool.dart'
    show listEnvironments, getEnvironmentVariables,
         registerListEnvironmentsTool, registerGetEnvironmentVariablesTool;

// Resources
export 'src/resources/request_resources.dart'
    show parseRequestUri, parseEnvironmentUri,
         getRequestResource, getEnvironmentResource, registerResources;

// Prompts
export 'src/prompts/api_prompts.dart'
    show RunCollectionPrompt, DebugRequestPrompt,
         CompareEnvironmentsPrompt, CreateRequestPrompt, registerPrompts;
