# Declare providers in here
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.15.3"
}

# Declare Providers
provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      "socialab:application:stage" = var.stage
      "socialab:deployment:terraform" = true
    }
  }
}

