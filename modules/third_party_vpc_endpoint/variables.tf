variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "allowed_access_security_groups" {
  type = list(string)
}

variable "stage" {
  type = string
}

variable "service_name" {
  type = string
}

variable "endpoint_id" {
  type    = string
  default = "Dummy"
}

variable "name" {
  type = string
}