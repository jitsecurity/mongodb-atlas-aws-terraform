variable "mongo_atlas" {
  type = object({
    org_id                           = string
    mongo_cloudformation_publisher_id = string
    ip_whitelist                     = list(object({
      cidr        = string
      description = string
    }))
    instances                        = list(string)
    aws_vpc_id                       = string
    private_subnet_ids               = list(string)
    add_mongo_ips_access_to_data_api = bool
    aws_allowed_access_security_groups = list(string)
    jwt_audience                     = string
    jwt_public_key                   = string
    tenant_id_field_in_jwt           = string
    email_notification               = string
    daily_price_threshold_alert      = number
    enable_continuous_backup         = bool
    stage                            = string
  })
  description = <<EOT
    mongo_atlas = {
      org_id: "The unique identifier for your MongoDB Atlas organization.",
      mongo_cloudformation_publisher_id: "The publisher ID for MongoDB Atlas resources within AWS CloudFormation, enabling integration and resource management. Keep the default value.",
      ip_whitelist: "A list of IP addresses or CIDR blocks allowed access to MongoDB Atlas resources, each with a description for identification purposes.",
      instances: "A list of MongoDB Atlas serverless instance names to create.",
      aws_vpc_id: "The ID of your AWS VPC where MongoDB Atlas resources will interact with AWS resources.",
      private_subnet_ids: "A list of subnet IDs within your AWS VPC designated for MongoDB Atlas resource connectivity.",
      add_mongo_ips_access_to_data_api: "A boolean flag indicating whether to configure the ip_whitelist to data api as well.",
      aws_allowed_access_security_groups: "A list of AWS security group IDs permitted access to MongoDB Atlas resources. (for example - your lambdas)",
      jwt_audience: "The 'aud' (audience) claim identifying the recipients that the JWT is intended for.",
      jwt_public_key: "The public key used to verify the signature of JWTs, ensuring the tokens are valid and issued by a trusted authority.",
      tenant_id_field_in_jwt: "The specific field within the JWT payload used to identify the tenant in multi-tenancy architectures.",
      email_notification: "An email address to receive notifications related to MongoDB Atlas, such as alerts.",
      daily_price_threshold_alert: "A numeric value representing the daily cost threshold in dollars that, when exceeded, triggers a pricing alert.",
      enable_continuous_backup: "A boolean flag to enable or disable continuous backups for MongoDB Atlas instances. (Incurs additional costs)",
      stage: "A string identifier to denote the environment or stage (e.g., development, test, production) for the MongoDB Atlas setup - A project is created for each stage."
    }
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