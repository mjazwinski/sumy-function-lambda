# aws configuration
PROFILE=your-cli-profile
BUCKET=your-cli-bucket
REGION=us-east-1

# sumy + mcp dependencies
P_DESCRIPTION="sumy-numpy-langdetect-mcp"
LAYER_STACK=sumy-mcp-lambda-layer
LAYER_TEMPLATE=sam/layer.yaml
LAYER_OUTPUT=sam/layer_output.yaml
LAYER_PARAMS="ParameterKey=description,ParameterValue=${P_DESCRIPTION}"
O_LAYER_ARN=your-output-layer-arn

# api gateway and lambda stack
P_API_STAGE=dev
P_FN_MEMORY=512
P_FN_TIMEOUT=30
APIGW_STACK=sumy-mcp-apigw
APIGW_TEMPLATE=sam/template.yaml
APIGW_OUTPUT=sam/template_output.yaml
APIGW_PARAMS="ParameterKey=apiStage,ParameterValue=${P_API_STAGE} ParameterKey=fnMemory,ParameterValue=${P_FN_MEMORY} ParameterKey=fnTimeout,ParameterValue=${P_FN_TIMEOUT} ParameterKey=dependencies,ParameterValue=${O_LAYER_ARN}"
