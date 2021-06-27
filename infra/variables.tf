// This file describes variables to be used for deployment
// To override default values for your use case, include
// a terraform.tfvars on the project root.
//
// i.e. ./terraform/terraform.tfvars or ./tfstate/terraform.tfvars
//

//////////// APPLICATION LEVEL VARIABLES /////////////////
variable "stage" {
  description = "Deployment Stage (staging, prod)"
  default     = "staging"

  validation {
    error_message = "The deployment stage must be one of the following: (staging, prod). Change your terraform.tfvars to match."
    condition     = can(regex("^(staging|prod)", var.stage))
  }
}

variable "application_name" {
  description = "Application name"
  default     = "sl-webapp"
}

variable "repository_url" {
  description = "Application repository URL"
  default     = "https://bitbucket.org/socialabbr/sl-webapp"
}

///////////////// PROVIDER VARIABLES /////////////////
variable "aws_region" {
  description = "AWS Deployment Region"
  default     = "us-east-1"
}

//////////////// NETWORK VARIABLES //////////////////
variable "availability_zones" {
  description = "AWS Availability Zones"
  type        = list(string)
  default     = ["us-east-1c", "us-east-1f"]
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "The CIDR block for the public subnet"
  type        = list(any)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

}

variable "private_subnets_cidr" {
  description = "The CIDR block for the private subnet"
  type        = list(any)
  default     = ["10.0.128.0/24", "10.0.129.0/24"]
}

//////////////// SECURITY VARIABLES ///////////////////
variable "public_key" {
  description = "The public key in OpenSSH, DER or SSH public key format (RFC4716) formats."
}

//////////////// ROUTING VARIABLES ///////////////////
variable "use_existing_route53_zone" {
  description = "If a Route 53 zone already exists, reuses it."
  type        = bool
  default     = false
}
