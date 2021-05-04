# This file describes variables to be used for deployment
# To override default values for your use case, include a terraform.tfvars

# Configure deployment region
variable "region" {
  description = "AWS Deployment Region"
  default = "us-east-1"
}

# Configure deployment profile
variable "profile" {
  description = "AWS Deployment Profile"
  default = "default"
}

# Configure deployment stage
variable "stage" {
  description = "Deployment Stage (staging, production)"
  default = "staging"

  validation {
    condition = can(regex("^(staging|production)", var.stage))
    error_message = "The deployment stage must be one of the following: (staging, production). Change your terraform.tfvars to match."
  }
}

//Networking
variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
}

variable "public_subnets_cidr" {
  type        = list
  description = "The CIDR block for the public subnet"
}

variable "private_subnets_cidr" {
  type        = list
  description = "The CIDR block for the private subnet"
}

// Security
variable "public_key" {
  description = "The public key in OpenSSH, DER or SSH public key format (RFC4716) formats."
}
