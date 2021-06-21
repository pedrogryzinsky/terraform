variable "stage" {
  description = "Deployment Stage (staging, production)"
}

variable "cluster_id" {
  description = "The ECS cluster ID"
  type        = string
}

variable "subnets" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
}

variable "target_group_arns" {
  type = list(string)
  default = []
}
