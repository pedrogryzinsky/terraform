variable "availability_zones" {
  description = "AWS Availability Zones (without the region prefix)"
  type        = list(string)
  default     = ["us-east-1c", "us-east-1f"]
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  type        = list(any)
  description = "The CIDR block for the public subnet"
}

variable "private_subnets_cidr" {
  type        = list(any)
  description = "The CIDR block for the private subnet"
}
