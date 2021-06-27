variable "stage" {
  description = "Deployment Stage (staging, prod)"
}

variable "security_groups" {
  type        = list(string)
  description = "A list of security groups to be applied to the instances"
}

variable "instance_subnets" {
  type        = list(string)
  description = "A list of subnets to be associated with the instance"
}


variable "key_name" {
  description = "The EC2-KeyPair name to be associated with the instances"
}
