variable "stage" {
  type = string
  description = "Name of the stage - this can be used to create different environments"
}

variable "project_id" {
  type        = string
  description = "Atlas project ID"
}

variable "instance_name" {
  type = string
  description = "Name of the MongoDB serverless instance"
}

variable "aws_account_id" {
  type = string
  description = "AWS account ID"
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
  description = "The VPC ID to create the private link in"
}

variable "private_subnet_ids" {
  type = list(string)
    description = "The private subnet IDs to create the private link in"
}

variable "tenant_id_field_in_jwt" {
  type        = string
  description = "The field in the JWT that contains the tenant ID"
}

variable "display_name_field_in_jwt" {
    type        = string
    description = "The field in the JWT that identifies the display name of the user (to be shown in the console)"
}

variable "aws_allowed_access_security_groups" {
  type = list(string)
    description = "The security groups that are allowed to access the MongoDB private endpoint"
}

variable "enable_continuous_backup" {
  type        = bool
  default     = false
  description = "Continuous backup incurs additional costs, Use only in production"
}

variable "organization_id" {
  type = string
  description = "The Atlas organization ID"
}

variable "jwt_audience" {
  type = string
  description = "The audience for the JWT"
}

variable "jwt_public_key" {
  type = string
  description = "The public key to verify the JWT"
}

variable "data_api_id" {
  type = string
  description = "The ID of the data API"
}
