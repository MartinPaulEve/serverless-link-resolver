resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "dynamodb-lambda-policy" {
  name = "dynamodb_lambda_policy"
  role = aws_iam_role.iam_for_lambda.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : ["dynamodb:*"],
        "Resource" : "${var.tables[0].arn}"
      }
    ]
  })
}

data "archive_file" "create-doi" {
  source_file = "lambdas/create-doi/create-doi.py"
  output_path = "lambdas/create-doi.zip"
  type        = "zip"
}

data "archive_file" "resolve-doi" {
  source_file = "lambdas/resolve-doi/resolve-doi.py"
  output_path = "lambdas/resolve-doi.zip"
  type        = "zip"
}

resource "aws_lambda_function" "create-doi" {
  environment {
    variables = {
      DOI_TABLE = var.tables[0].name
    }
  }
  memory_size   = "128"
  timeout       = 10
  runtime       = "python3.9"
  architectures = ["arm64"]
  handler       = "create-doi.lambda_handler"
  function_name = "put-doi"
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = "lambdas/create-doi.zip"
}

resource "aws_lambda_function" "resolve-doi" {
  environment {
    variables = {
      DOI_TABLE = var.tables[0].name
    }
  }
  memory_size   = "128"
  timeout       = 10
  runtime       = "python3.9"
  architectures = ["arm64"]
  handler       = "resolve-doi.lambda_handler"
  function_name = "resolve-doi"
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = "lambdas/resolve-doi.zip"
}

resource "aws_api_gateway_rest_api" "link-resolver" {
  name        = "LinkResolverTest"
  description = "A Test DOI Mockup Application"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.link-resolver.id}"
  parent_id   = "${aws_api_gateway_rest_api.link-resolver.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.link-resolver.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create-doi-lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.link-resolver.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.create-doi.invoke_arn}"
}

resource "aws_api_gateway_integration" "resolve-doi-lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.link-resolver.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.resolve-doi.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.link-resolver.id}"
  resource_id   = "${aws_api_gateway_rest_api.link-resolver.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.link-resolver.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.create-doi.invoke_arn}"
}

resource "aws_api_gateway_deployment" "lr" {
  depends_on = [
    "aws_api_gateway_integration.resolve-doi-lambda",
    "aws_api_gateway_integration.create-doi-lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.link-resolver.id}"
  stage_name  = "doi"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.create-doi.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.link-resolver.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigwresolve" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.resolve-doi.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.link-resolver.execution_arn}/*/*"
}
