provider "aws" {
  region = var.region
}

######################
# COGNITO
######################

resource "aws_cognito_user_pool" "main" {
  name = "demo-pool"

  password_policy {
    minimum_length    = 6
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name                                 = "demo-client"
  user_pool_id                         = aws_cognito_user_pool.main.id
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = [var.callback_url]
  logout_urls                          = [var.logout_url]
  generate_secret                      = false
  explicit_auth_flows                  = ["ADMIN_NO_SRP_AUTH"]
}

resource "aws_cognito_user_group" "admin" {
  user_pool_id = aws_cognito_user_pool.main.id
  name         = "admin"
}

resource "aws_cognito_user_group" "ventas" {
  user_pool_id = aws_cognito_user_pool.main.id
  name         = "ventas"
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = "demo-app-jliza2025"
  user_pool_id = aws_cognito_user_pool.main.id
}

######################
# ROLES Y POLÍTICAS
######################

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

######################
# LAMBDA: auth-demo (Node.js)
######################

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda-handler.js"
  output_path = "${path.module}/lambda/lambda.zip"
}

resource "aws_lambda_function" "demo" {
  function_name    = "auth-demo"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler          = "lambda-handler.handler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_exec_role.arn
}

######################
# LAMBDA: ms-preventista (Java)
######################

resource "aws_lambda_function" "ms_preventista" {
  function_name = "ms-preventista"
  filename      = "${path.module}/java/ms-preventista-0.0.1.jar"
  handler       = "com.cursomicroservicios.config.PedidoLambdaHandler"
  runtime       = "java17"
  timeout       = 30
  memory_size   = 512
  role          = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      KAFKA_USERNAME              = "746OHGM35QZPOSDP"
      KAFKA_PASSWORD              = "qqAHwLCpTAW64Ea7kiAfNoJUl2tD51o5GFhPdmkOkAhA1aSYp1meLVGpnCa8L9nc"
      SCHEMA_REGISTRY_URL        = "https://psrc-4x67ewe.us-east1.gcp.confluent.cloud"
      SCHEMA_REGISTRY_USER_INFO  = "T4QAJ2EKOMP76LRO:MzQqkhC4+I1UfOju723DzfaNnmIT8GnCPd7EZYIr0RGFn70w8FMGHAWLkCPkcVuf"
      SPRING_PROFILES_ACTIVE     = "lambda"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_basic]
}

######################
# API GATEWAY
######################

resource "aws_api_gateway_rest_api" "api" {
  name = "demo-api"
}

resource "aws_api_gateway_resource" "admin_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "admin"
}

resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.admin_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id
}

resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.admin_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.admin_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.demo.invoke_arn
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.admin_resource.id
  http_method             = aws_api_gateway_method.options_method.http_method
  type                    = "MOCK"
  integration_http_method = "OPTIONS"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_resource" "pedido_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "pedido"
}

resource "aws_api_gateway_method" "pedido_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.pedido_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id
}

resource "aws_api_gateway_method" "pedido_options" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.pedido_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "pedido_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.pedido_resource.id
  http_method             = aws_api_gateway_method.pedido_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ms_preventista.invoke_arn
}

resource "aws_api_gateway_integration" "pedido_options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.pedido_resource.id
  http_method             = aws_api_gateway_method.pedido_options.http_method
  type                    = "MOCK"
  integration_http_method = "OPTIONS"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_authorizer" "cognito_auth" {
  name            = "cognito-auth"
  rest_api_id     = aws_api_gateway_rest_api.api.id
  identity_source = "method.request.header.Authorization"
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [aws_cognito_user_pool.main.arn]
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.demo.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_preventista" {
  statement_id  = "AllowExecutionFromAPIGatewayMsPreventista"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ms_preventista.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.options_integration,
    aws_api_gateway_integration.pedido_integration,
    aws_api_gateway_integration.pedido_options_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(filebase64("${path.module}/lambda/lambda-handler.js"))
  }
}

resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}
