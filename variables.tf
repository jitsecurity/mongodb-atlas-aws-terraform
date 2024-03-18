
variable "org_id" {
  type        = string
  description = "The unique identifier for your MongoDB Atlas organization."
}

variable "mongo_cloudformation_publisher_id" {
  type        = string
  description = "The publisher ID for MongoDB Atlas resources within AWS CloudFormation, enabling integration and resource management. Keep the default value unless changed by AWS/MongoDB."
  default = "bb989456c78c398a858fef18f2ca1bfc1fbba082"
}

variable "instances" {
  type        = list(string)
  description = "A list of MongoDB Atlas serverless instance names to create."
}

variable "enable_continuous_backup" {
  type        = bool
  description = "A boolean flag to enable or disable continuous backups for MongoDB Atlas instances. (Incurs additional costs)"
}

variable "enable_termination_protection" {
  type        = bool
  description = "A boolean flag to enable or disable termination protection for MongoDB Atlas instances."
}

variable "enable_cloudformation_atlas_resources" {
  type        = bool
  description = "A boolean flag to enable or disable the creation of MongoDB Atlas resources within AWS CloudFormation."
}

variable "stage" {
  type        = string
  description = "A string identifier to denote the environment or stage (e.g., development, test, production) for the MongoDB Atlas setup - A project is created for each stage."
}


variable "security" {
  type = object({
    aws_vpc_id                        = string
    private_subnet_ids                = list(string)
    aws_allowed_access_security_groups = list(string)
    ip_whitelist                      = list(object({
      cidr        = string
      description = string
    }))
  })
  description = <<EOT
    aws_vpc_id: "The ID of your AWS VPC where MongoDB Atlas resources will interact with AWS resources.",
    private_subnet_ids: "A list of subnet IDs within your AWS VPC designated for MongoDB Atlas resource connectivity.",
    aws_allowed_access_security_groups: "A list of AWS security group IDs permitted access to MongoDB Atlas resources. (for example - your lambdas)"
    ip_whitelist: "A list of IP addresses or CIDR blocks allowed access to MongoDB Atlas resources, each with a description for identification purposes."
  EOT
}

variable "data_api_configurations" {
  type = object({
    jwt_audience              = string
    jwt_public_key            = string
    tenant_id_field_in_jwt    = string
    display_name_field_in_jwt = string
    add_mongo_ips_access_to_data_api  = bool
  })
  description = <<EOT
    jwt_audience: "The 'aud' (audience) claim identifying the recipients that the JWT is intended for.",
    jwt_public_key: "The public key used to verify the signature of JWTs, ensuring the tokens are valid and issued by a trusted authority.",
    tenant_id_field_in_jwt: "The specific field within the JWT payload used to identify the tenant in multi-tenancy architectures.",
    display_name_field_in_jwt: "The specific field within the JWT payload used to identify the string to show in the data-api console as the user ID."
    add_mongo_ips_access_to_data_api: "A boolean flag indicating whether to configure the ip_whitelist under security to data api as well.",
  EOT
}

variable "alerts" {
  type = object({
    email_notification          = string
    daily_price_threshold_alert = number
  })
  description = <<EOT
    email_notification: "An email address to receive notifications related to MongoDB Atlas, such as alerts.",
    daily_price_threshold_alert: "A numeric value representing the daily cost threshold in dollars that, when exceeded, triggers a pricing alert."
  EOT
}


variable "mongo_atlas_public_key" {
  description = "Public key for your API key defined here https://cloud.mongodb.com/v2#/org/<org-id>/access/apiKeys"
  type = string
}

variable "mongo_atlas_private_key" {
  description = "Secret value for your API key defined here https://cloud.mongodb.com/v2#/org/<org-id>/access/apiKeys"
  type = string
  sensitive = true
}

variable "region" {
    description = "The AWS region to deploy the solution."
    type = string
    default = "us-east-1"
}