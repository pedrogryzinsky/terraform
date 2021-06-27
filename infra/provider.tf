# Declare providers in here
terraform {
  required_version = ">= 0.15.3"

  backend "s3" {
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

# Declare Providers
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      "socialab:application:name"       = var.application_name
      "socialab:application:stage"      = var.stage
      "socialab:application:repository" = var.repository_url
      "socialab:deployment:terraform"   = true
    }
  }
}

