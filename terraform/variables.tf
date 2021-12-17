variable "aws_access_key" {
  description = "AWS Access Key ID"
  default     = "123"
}

variable "aws_region" {
  description = "The AWS region"
  default     = "eu-west-1"
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key"
  default     = "qwe"
  sensitive   = true
}

variable "ci" {
  default = false
}

variable "env" {
  default = {
    TOKEN = "token"
  }
  sensitive = true
  type      = map(string)
}

variable "environment" {
  description = "The environment name" # local || qa || stage || prod
  default     = "local"
}

variable "lambda_function_associations" {
  type = map(any)
  default = {
    cloudfront-redirect-www = {
      arn          = "arn:aws:lambda:us-east-1:00000:function:wmaciejak-cloudfront-redirect-www:2"
      event_type   = "viewer-request"
      include_body = true
    }
    cloudfront-default-root-object = {
      arn          = "arn:aws:lambda:us-east-1:00000:function:wmaciejak-cloudfront-default-root-object:1"
      event_type   = "origin-request"
      include_body = true
    }
  }
}

variable "localstack_url" {
  type    = string
  default = "http://localhost:4566"
}

variable "mode" {
  default = "localstack" # (localstack|aws)
}

variable "workspace" {
  description = "The workspace name"
  default     = ""
}
