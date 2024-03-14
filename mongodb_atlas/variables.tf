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
  description = "Configuration for MongoDB Atlas"
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