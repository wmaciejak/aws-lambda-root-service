data "aws_route53_zone" "this" {
  for_each = toset(
    local.environment.route53_zone == "" ? [] : [local.environment.route53_zone]
  )
  name         = each.key
  private_zone = false
}

data "aws_acm_certificate" "eu-west-1" {
  for_each = toset(
    local.environment.acm_certificate == "" ? [] : [local.environment.acm_certificate]
  )
  domain   = each.key
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "us-east-1" {
  for_each = toset(
    local.environment.acm_certificate == "" ? [] : [local.environment.acm_certificate]
  )
  domain   = each.key
  provider = aws.us-east-1
  statuses = ["ISSUED"]
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "dynamodb" {
  statement {
    actions   = ["dynamodb:*"]
    resources = ["arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/${var.workspace}-*"]
  }
}

data "aws_caller_identity" "this" {}

resource "aws_api_gateway_deployment" "root_rest_api" {
  lifecycle {
    create_before_destroy = true
  }
  rest_api_id = aws_api_gateway_rest_api.root_rest_api.id
  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.heartbeat.id,
    ]))
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  for_each = toset(
    local.environment.api_gateway_domain_name == "" ? [] : [local.environment.api_gateway_domain_name]
  )
  api_id      = aws_api_gateway_rest_api.root_rest_api.id
  stage_name  = aws_api_gateway_stage.root_rest_api.stage_name
  domain_name = each.key
}

resource "aws_api_gateway_rest_api" "root_rest_api" {
  name = var.workspace == "" ? "api-gateway" : "${var.workspace}-api-gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = local.tags
}

resource "aws_api_gateway_domain_name" "this" {
  for_each = toset(
    local.environment.api_gateway_domain_name == "" ? [] : [local.environment.api_gateway_domain_name]
  )
  domain_name              = each.key
  regional_certificate_arn = data.aws_acm_certificate.eu-west-1[local.environment.acm_certificate].arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = local.tags
}

resource "aws_iam_role" "this" {
  name               = var.workspace == "" ? "root-service" : "${var.workspace}-root-service"
  assume_role_policy = data.aws_iam_policy_document.this.json
  inline_policy {
    name   = "DynamoDB"
    policy = data.aws_iam_policy_document.dynamodb.json
  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]
  max_session_duration = 3600
  tags                 = local.tags
}

resource "aws_route53_record" "apigateway" {
  for_each = toset(
    local.environment.api_gateway_domain_name == "" ? [] : [local.environment.api_gateway_domain_name]
  )
  name    = aws_api_gateway_domain_name.this[each.key].domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.this[local.environment.route53_zone].id

  alias {
    evaluate_target_health = false
    name                   = aws_api_gateway_domain_name.this[each.key].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.this[each.key].regional_zone_id
  }
}

resource "aws_route53_record" "cloudfront" {
  for_each = toset(
    local.environment.cloudfront_distribution_alias == "" ? [] : [local.environment.cloudfront_distribution_alias]
  )
  name    = each.key
  type    = "A"
  zone_id = data.aws_route53_zone.this[local.environment.route53_zone].id

  alias {
    name                   = aws_cloudfront_distribution.this[each.key].domain_name
    zone_id                = aws_cloudfront_distribution.this[each.key].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_api_gateway_stage" "root_rest_api" {
  deployment_id = aws_api_gateway_deployment.root_rest_api.id
  rest_api_id   = aws_api_gateway_rest_api.root_rest_api.id
  stage_name    = local.environment.api_gateway_deployment_stage_name
  tags          = local.tags
}

resource "aws_api_gateway_resource" "heartbeat" {
  rest_api_id = aws_api_gateway_rest_api.root_rest_api.id
  parent_id   = aws_api_gateway_rest_api.root_rest_api.root_resource_id
  path_part   = "heartbeat"
}

resource "aws_api_gateway_method" "heartbeat" {
  rest_api_id   = aws_api_gateway_rest_api.root_rest_api.id
  resource_id   = aws_api_gateway_resource.heartbeat.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "heartbeat" {
  rest_api_id = aws_api_gateway_rest_api.root_rest_api.id
  resource_id = aws_api_gateway_method.heartbeat.resource_id
  http_method = aws_api_gateway_method.heartbeat.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.boilerplate_service.heartbeat_invoke_arn
}

# DynamoDB
resource "aws_dynamodb_table" "test" {
  read_capacity  = 20
  write_capacity = 20
  name           = var.workspace == "" ? "test" : "${var.workspace}-test"
  hash_key       = "subdomain"

  attribute {
    name = "subdomain"
    type = "S"
  }
  tags = local.tags
}

resource "aws_s3_bucket" "this" {
  for_each = toset(
    local.environment.cloudfront_distribution_alias == "" ? [] : [local.environment.cloudfront_distribution_alias]
  )
  acl           = "public-read"
  bucket        = "${var.workspace}-root-service-cloudfront"
  force_destroy = true
  tags          = local.tags
  versioning {
    enabled    = false
    mfa_delete = false
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = toset(
    local.environment.cloudfront_distribution_alias == "" ? [] : [local.environment.cloudfront_distribution_alias]
  )
  bucket = aws_s3_bucket.this[each.key].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_cloudfront_distribution" "this" {
  for_each = toset(
    local.environment.cloudfront_distribution_alias == "" ? [] : [local.environment.cloudfront_distribution_alias]
  )
  aliases = local.environment.cloudfront_distribution_aliases
  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]
    cached_methods = [
      "GET",
      "HEAD"
    ]
    compress    = true
    default_ttl = 3600
    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = true
    }
    lambda_function_association {
      event_type   = var.lambda_function_associations["cloudfront-default-root-object"].event_type
      include_body = var.lambda_function_associations["cloudfront-default-root-object"].include_body
      lambda_arn   = var.lambda_function_associations["cloudfront-default-root-object"].arn
    }
    lambda_function_association {
      event_type   = var.lambda_function_associations["cloudfront-redirect-www"].event_type
      include_body = var.lambda_function_associations["cloudfront-redirect-www"].include_body
      lambda_arn   = var.lambda_function_associations["cloudfront-redirect-www"].arn
    }
    max_ttl                = 86400
    target_origin_id       = "default"
    viewer_protocol_policy = "redirect-to-https"
  }
  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  ordered_cache_behavior {
    path_pattern     = "/boilerplate/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "boilerplate"

    default_ttl = 0
    min_ttl     = 0
    max_ttl     = 0

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    lambda_function_association {
      event_type   = var.lambda_function_associations["cloudfront-default-root-object"].event_type
      include_body = var.lambda_function_associations["cloudfront-default-root-object"].include_body
      lambda_arn   = var.lambda_function_associations["cloudfront-default-root-object"].arn
    }
    lambda_function_association {
      event_type   = var.lambda_function_associations["cloudfront-redirect-www"].event_type
      include_body = var.lambda_function_associations["cloudfront-redirect-www"].include_body
      lambda_arn   = var.lambda_function_associations["cloudfront-redirect-www"].arn
    }

    viewer_protocol_policy = "redirect-to-https"
  }
  origin {
    domain_name = aws_s3_bucket.this[each.key].bucket_regional_domain_name
    origin_id   = "default"
    origin_path = "/default"
  }
  origin {
    domain_name = aws_s3_bucket.this[each.key].bucket_regional_domain_name
    origin_id   = "heartbeat"
  }
  price_class = "PriceClass_All"
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  retain_on_delete = false
  tags             = local.tags
  viewer_certificate {
    acm_certificate_arn            = data.aws_acm_certificate.us-east-1[local.environment.acm_certificate].arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1"
    ssl_support_method             = "sni-only"
  }
}
