# sumy-function-lambda

AWS Lambda port of [`sumy-function`](../sumy-function). It exposes the same `summarizer_mcp` MCP tool, which uses [sumy](https://github.com/miso-belica/sumy)'s LSA summarizer and `langdetect`. The tool runs as a stateless Streamable HTTP MCP server behind Amazon API Gateway.

The layout follows [stateless-mcp-on-lambda-python](https://github.com/aws-samples/sample-serverless-mcp-servers/tree/main/stateless-mcp-on-lambda-python). FastMCP is mounted on FastAPI, and the [Lambda Web Adapter](https://github.com/awslabs/aws-lambda-web-adapter) runs it with uvicorn inside Lambda.

## Azure to AWS mapping

| Azure Functions | AWS Lambda |
|---|---|
| `@app.mcp_tool()` in `function_app.py` | `@mcp.tool()` (FastMCP) in `src/mcpserver/summarizer.py` |
| `host.json` `extensions.mcp` (server name, instructions) | `FastMCP(name=..., instructions=...)` |
| `/runtime/webhooks/mcp` | `${outApiEndpoint}/summarizer/mcp` |
| System key (`x-functions-key` header) | API Gateway API key (`x-api-key` header) |
| `requirements.txt` | Lambda layer built from `src/dependencies/` |

## Project structure

```
sumy-function-lambda/
├── etc/environment.sh          # Deployment configuration
├── makefile                    # Build and deploy commands
├── sam/
│   ├── layer.yaml              # Dependencies layer (pip packages + NLTK punkt_tab data)
│   ├── template.yaml           # API Gateway, API key, Lambda function
│   └── openapi.yaml            # API Gateway route definition
└── src/
    ├── dependencies/
    │   ├── requirements.txt    # mcp, fastapi, uvicorn, sumy, numpy, langdetect
    │   └── Makefile            # Layer build used by `sam build`
    └── mcpserver/
        ├── summarizer.py       # MCP server + summarizer_mcp tool
        ├── server.py           # FastAPI app / local entry point
        └── run.sh              # Lambda Web Adapter startup script
```

The sumy tokenizer needs NLTK's `punkt_tab` data. The layer build downloads it into `/opt/nltk_data`, and the function sets `NLTK_DATA` to that path.

## Prerequisites

- AWS CLI with configured credentials
- AWS SAM CLI
- Docker Desktop or Podman (the layer is built in the `python3.12` build container)
- `make` and `bash`. On Windows, use WSL or Git Bash.
- Python 3.12 for local runs

## Configuration

Edit `etc/environment.sh`:

- `PROFILE`, `BUCKET` and `REGION`: AWS CLI profile, S3 bucket for artifacts (versioning must be enabled), and region.
- `O_LAYER_ARN`: fill this in after `make layer`.
- `P_API_STAGE`, `P_FN_MEMORY` (default 512 MB) and `P_FN_TIMEOUT` (default 30 s): API Gateway stage and Lambda settings.

`sam/template.yaml` references the Lambda Insights and Lambda Web Adapter layers in `us-east-1`. For other regions, update those ARNs.

## Deploy

1. Build and deploy the dependencies layer:
   ```bash
   make layer
   ```
   Copy the `outLayer` output into `O_LAYER_ARN` in `etc/environment.sh`.

2. Deploy the API Gateway and Lambda function:
   ```bash
   make apigw
   ```

3. Get the API key value. Use `outApiKeyId` from the stack outputs:
   ```bash
   aws apigateway get-api-key --api-key <outApiKeyId> --include-value --query value --output text
   ```

## Test

The MCP endpoint is `${outApiEndpoint}/summarizer/mcp`. Do not add a trailing `/`. The MCP SDK would redirect, the redirect drops the stage from the URL, and the client gets a 403. Send the key in the `x-api-key` header.

Example `.vscode/mcp.json` entry for the deployed server:

```json
{
  "servers": {
    "sumy-function-aws": {
      "type": "http",
      "url": "https://<api-id>.execute-api.us-east-1.amazonaws.com/dev/summarizer/mcp",
      "headers": { "x-api-key": "<api-key-value>" }
    }
  }
}
```

## Run locally

```bash
python -m venv .venv
source .venv/bin/activate            # Windows: .\.venv\Scripts\Activate.ps1
pip install -r src/dependencies/requirements.txt
python -m nltk.downloader punkt_tab

cd src/mcpserver
python server.py                     # FastAPI on http://localhost:8000/summarizer/mcp
python server.py --mode stdio        # STDIO transport
```

The checked-in `.vscode/mcp.json` points at the local FastAPI server.

## Cleanup

```bash
make apigw.delete
sam delete --stack-name sumy-mcp-lambda-layer
```
