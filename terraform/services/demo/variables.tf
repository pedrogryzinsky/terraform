variable "cluster_id" {
  description = "The ECS cluster ID"
  type        = string
}

variable "subnets" {
  type = list
}

variable "sgs" {
  type = list
}

variable "target_group_arns" {
  type = list
}
