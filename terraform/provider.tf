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
  region = var.region

  default_tags {
    tags = {
      "socialab:application:name"     = "socialab"
      "socialab:application:stage"    = var.stage
      "socialab:deployment:terraform" = true
    }
  }
}

