output "apigateway_url" {
  value = (
    var.mode == "aws" ?
    (
      local.environment.api_gateway_domain_name != "" ?
      format("https://%s/", local.environment.api_gateway_domain_name)
      :
      format("https://%s.execute-api.%s.amazonaws.com/%s/",
        aws_api_gateway_rest_api.root_rest_api.id,
        var.aws_region,
        local.environment.api_gateway_deployment_stage_name
      )
    )
    :
    format(
      "%s/restapis/%s/%s/_user_request_/",
      var.localstack_url,
      aws_api_gateway_rest_api.root_rest_api.id,
      local.environment.api_gateway_deployment_stage_name
    )
  )
}

output "boilerplate_service_url" {
  value = (
    local.environment.cloudfront_distribution_alias != "" ?
    format("https://%s/boilerplate/", local.environment.cloudfront_distribution_alias) : ""
  )
}
output "heartbeat_urls" {
  value = [
    for path in [
      aws_api_gateway_resource.heartbeat.path,
    ] : "${local.root_rest_api_url}${path}"
  ]
}

output "mode" {
  value = var.mode
}
