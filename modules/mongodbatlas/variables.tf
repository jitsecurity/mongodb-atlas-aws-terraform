variable "stage" {
  type = string
  description = "Name of the stage - this can be used to create different environments"
}

variable "organization_id" {
  type        = string
  description = "Org ID to work on, usually received from the organization part in the UI"
}

variable "mongo_ip_access_list" {
  type        = list(map(string))
  description = "List of IPs allowed to access the DBs via API (for example mongo compass, etc..)"
}

variable "add_mongo_ips_access_to_data_api" {
  type        = bool
  description = "this indicates if we should also let ips from mongo_ip_access_list to use data-api"
  default     = false
}

variable "enable_termination_protection" {
    type        = bool
    description = "Enable termination protection all instances"
}

variable "mongo_instances" {
  type        = list(string)
  description = "instances to be created - they will all be serverless instances"
}

variable "aws_vpc_id" {
  type = string
  description = "VPC ID to integrate the private endpoint"
}

variable "private_subnet_ids" {
    type = list(string)
    description = "Subnet IDs to integrate the private endpoint"
}

# We are using it to create data-api, data.aws_region.current.name somehow forces a change to the shell script
# so we'll put it hard coded.
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_allowed_access_security_groups" {
  type = list(string)
}

variable "enable_continuous_backup" {
  type    = bool
  default = false
}

variable "jwt_audience" {
  type = string
}

variable "jwt_public_key" {
  type = string
}

variable "notification_email" {
  type        = string
}

variable "daily_price_threshold_alert" {
  type = number
  description = "The price threshold to send a slack notification (daily)"
}

variable "monthly_price_threshold" {
  type = number
  description = "The price threshold to send a slack notification (monthly)"
  default = 100
}


variable "tenant_id_field_in_jwt" {
  type        = string
  description = "The field in the JWT that contains the tenant ID"
}
