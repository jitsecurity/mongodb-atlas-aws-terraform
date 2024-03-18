variable "stage" {
  type = string
}

variable "project_id" {
  type        = string
  description = "project ID of atlas"
}

variable "instance_name" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "enable_termination_protection" {
    type        = bool
    description = "Enable termination protection for the instance"
}

# We are using it to create data-api, sdata.aws_region.current.name somehow forces a change to the shell script
# so we'll put it hard coded.
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "tenant_id_field_in_jwt" {
  type        = string
  description = "The field in the JWT that contains the tenant ID"
}

variable "aws_allowed_access_security_groups" {
  type = list(string)
}

variable "enable_continuous_backup" {
  type        = bool
  default     = false
  description = "Continuous backup costs more money, so should be only on prod"
}

variable "organization_id" {
  type = string
}

variable "jwt_audience" {
  type = string
}

variable "jwt_public_key" {
  type = string
}

variable "data_api_id" {
  type = string
}
