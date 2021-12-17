module "boilerplate_service" {
  source = "./modules/aws-lambda-boilerplate/terraform"

  iam_role_arn                = aws_iam_role.this.arn
  ci                          = var.ci
  env                         = var.env
  root_rest_api_execution_arn = aws_api_gateway_rest_api.root_rest_api.execution_arn
  root_rest_api_id            = aws_api_gateway_rest_api.root_rest_api.id
  workspace                   = var.workspace
}

module "heartbeat_cors_configuration" {
  count = local.environment.api_gateway_domain_name == "" ? 0 : 1

  source  = "mewa/apigateway-cors/aws"
  version = "2.0.0"

  api      = aws_api_gateway_rest_api.root_rest_api.id
  resource = aws_api_gateway_resource.heartbeat.id

  methods = ["GET"]
  headers = ["X-Subdomain"]
}
