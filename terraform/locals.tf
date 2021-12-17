locals {
  account_id  = data.aws_caller_identity.this.account_id
  environment = local.environments[var.environment]
  environments = {
    qa = {
      acm_certificate                   = "*.domain.com"
      api_gateway_domain_name           = "${var.workspace}-apigateway.dev.domain.com"
      api_gateway_deployment_stage_name = "dev"
      cloudfront_distribution_alias     = "${var.workspace}.dev.domain.com"
      cloudfront_distribution_aliases = [
        "${var.workspace}.dev.domain.com"
      ]
      route53_zone = "domain.com"
      tags = {
        Environment = "qa"
      }
    }
    local = {
      acm_certificate                   = ""
      api_gateway_domain_name           = ""
      api_gateway_deployment_stage_name = "local"
      cloudfront_distribution_alias     = ""
      cloudfront_distribution_aliases   = []
      route53_zone                      = ""
      tags = {
        Environment = "local"
      }
    }
    prod = {
      acm_certificate                   = "*.domain.com"
      api_gateway_domain_name           = "apigateway.domain.com"
      api_gateway_deployment_stage_name = "prod"
      cloudfront_distribution_alias     = "domain.com"
      cloudfront_distribution_aliases = [
        "domain.com",
        "www.domain.com"
      ]
      route53_zone = "domain.com"
      tags = {
        Environment = "prod"
      }
    }
    stage = {
      acm_certificate                   = "*.stage.domain.com"
      api_gateway_domain_name           = "${var.workspace}-apigateway.stage.domain.com"
      api_gateway_deployment_stage_name = "stage"
      cloudfront_distribution_alias     = "stage.domain.com"
      cloudfront_distribution_aliases = [
        "stage.domain.com",
        "www.stage.domain.com"
      ]
      route53_zone = "domain.com"
      tags = {
        Environment = "stage"
      }
    }
  }
  root_rest_api_url = (
    var.mode == "aws" ?
    (
      local.environment.api_gateway_domain_name != "" ?
      format(
        "https://%s",
        local.environment.api_gateway_domain_name
      )
      :
      format(
        "https://%s.execute-api.%s.amazonaws.com/%s",
        aws_api_gateway_rest_api.root_rest_api.id,
        var.aws_region,
        local.environment.api_gateway_deployment_stage_name
      )
    )
    :
    format(
      "%s/restapis/%s/%s/_user_request_",
      "http://localstack:4566",
      aws_api_gateway_rest_api.root_rest_api.id,
      local.environment.api_gateway_deployment_stage_name
    )
  )
  tags = {
    Client      = var.workspace
    Environment = local.environments[var.environment].tags.Environment
    Managed-By  = "Terraform"
  }
}
