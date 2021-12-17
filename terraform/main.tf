locals {
  cloud = {
    aws = {
      provider = {
        endpoints                   = []
        skip_requesting_account_id  = false
        skip_credentials_validation = false
      }
    }
    localstack = {
      provider = {
        endpoints = [
          {
            apigateway       = var.localstack_url
            cloudformation   = var.localstack_url
            cloudwatch       = var.localstack_url
            cloudwatchevents = var.localstack_url
            cloudwatchlogs   = var.localstack_url
            dynamodb         = var.localstack_url
            ec2              = var.localstack_url
            es               = var.localstack_url
            firehose         = var.localstack_url
            iam              = var.localstack_url
            kinesis          = var.localstack_url
            lambda           = var.localstack_url
            route53          = var.localstack_url
            redshift         = var.localstack_url
            s3               = var.localstack_url
            secretsmanager   = var.localstack_url
            ses              = var.localstack_url
            sns              = var.localstack_url
            sqs              = var.localstack_url
            ssm              = var.localstack_url
            stepfunctions    = var.localstack_url
            sts              = var.localstack_url
          }
        ]
        skip_credentials_validation = true
        skip_requesting_account_id  = true
      }
    }
  }
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = var.aws_access_key
  secret_key                  = var.aws_secret_key
  skip_requesting_account_id  = local.cloud[var.mode].provider.skip_requesting_account_id
  skip_credentials_validation = local.cloud[var.mode].provider.skip_credentials_validation
  dynamic "endpoints" {
    for_each = local.cloud[var.mode].provider.endpoints
    content {
      apigateway       = endpoints.value.apigateway
      cloudformation   = endpoints.value.cloudformation
      cloudwatch       = endpoints.value.cloudwatch
      cloudwatchevents = endpoints.value.cloudwatchevents
      cloudwatchlogs   = endpoints.value.cloudwatchlogs
      dynamodb         = endpoints.value.dynamodb
      ec2              = endpoints.value.ec2
      es               = endpoints.value.es
      firehose         = endpoints.value.firehose
      iam              = endpoints.value.iam
      kinesis          = endpoints.value.kinesis
      lambda           = endpoints.value.lambda
      route53          = endpoints.value.route53
      redshift         = endpoints.value.redshift
      s3               = endpoints.value.s3
      secretsmanager   = endpoints.value.secretsmanager
      ses              = endpoints.value.ses
      sns              = endpoints.value.sns
      sqs              = endpoints.value.sqs
      ssm              = endpoints.value.ssm
      stepfunctions    = endpoints.value.stepfunctions
      sts              = endpoints.value.sts
    }
  }
}

provider "aws" {
  alias                       = "us-east-1"
  access_key                  = var.aws_access_key
  region                      = "us-east-1"
  secret_key                  = var.aws_secret_key
  skip_requesting_account_id  = local.cloud[var.mode].provider.skip_requesting_account_id
  skip_credentials_validation = local.cloud[var.mode].provider.skip_credentials_validation
  dynamic "endpoints" {
    for_each = local.cloud[var.mode].provider.endpoints
    content {
      apigateway       = endpoints.value.apigateway
      cloudformation   = endpoints.value.cloudformation
      cloudwatch       = endpoints.value.cloudwatch
      cloudwatchevents = endpoints.value.cloudwatchevents
      cloudwatchlogs   = endpoints.value.cloudwatchlogs
      dynamodb         = endpoints.value.dynamodb
      ec2              = endpoints.value.ec2
      es               = endpoints.value.es
      firehose         = endpoints.value.firehose
      iam              = endpoints.value.iam
      kinesis          = endpoints.value.kinesis
      lambda           = endpoints.value.lambda
      route53          = endpoints.value.route53
      redshift         = endpoints.value.redshift
      s3               = endpoints.value.s3
      secretsmanager   = endpoints.value.secretsmanager
      ses              = endpoints.value.ses
      sns              = endpoints.value.sns
      sqs              = endpoints.value.sqs
      ssm              = endpoints.value.ssm
      stepfunctions    = endpoints.value.stepfunctions
      sts              = endpoints.value.sts
    }
  }
}
