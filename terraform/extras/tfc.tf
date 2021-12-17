terraform {
  backend "remote" {
    organization = "wmaciejak"

    workspaces {
      prefix = "aws-lambda-root-service-"
    }
  }
}
