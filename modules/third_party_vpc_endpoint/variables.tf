variable "vpc_id" {
  type = string
  description = "The VPC ID where the endpoint will be created"
}

variable "subnet_ids" {
  type = list(string)
  description = "The subnet IDs where the endpoint will be created"
}

variable "allowed_access_security_groups" {
  type = list(string)
  description = "The security groups that will be allowed to access the endpoint"
}

variable "service_name" {
  type = string
  description = "The corresponding service name for the endpoint, obtained from the connected service."
}

variable "name" {
  type = string
  description = "The name of the endpoint, used to tag the endpoint resource."
}