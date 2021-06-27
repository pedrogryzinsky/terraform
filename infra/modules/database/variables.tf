variable "stage" {
  description = "Deployment Stage (staging, prod)"
}

variable "security_groups" {
  type        = list(string)
  description = "A list of security groups to be applied to the rds instance"
}

variable "instance_subnets" {
  type        = list(string)
  description = "A list of subnets to be associated with the rds instance"
}
