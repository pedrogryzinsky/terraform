variable "stage" {

}

variable "vpc_id" {

}

variable "use_existing_route53_zone" {
  default = false
}


variable "subnets" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
}
