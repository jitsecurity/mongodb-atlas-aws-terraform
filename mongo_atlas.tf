module "mongo-cf-secret" {
  count = var.enable_cloudformation_atlas_resources ? 1 : 0
  source      = "./modules/secret"
  secret_name = "cfn/atlas/profile/${var.org_id}"
  secret_value = jsonencode({
    PublicKey  = var.mongo_atlas_public_key
    PrivateKey = var.mongo_atlas_private_key
  })
  description = "Required to be able to use CloudFormation resources to create mongo resources"
}

module "mongo-cf-activation" {
  count = var.enable_cloudformation_atlas_resources ? 1 : 0
  source        = "./modules/cf_public_extension"
  iam_actions   = ["secretsmanager:GetSecretValue"]
  iam_resources = [module.mongo-cf-secret[0].secret_arn]
  publisher_id  = var.mongo_cloudformation_publisher_id
  custom_resources_types = ["MongoDB::Atlas::CustomDBRole",
  "MongoDB::Atlas::DatabaseUser"]
  policy_name = "mongo-resource-activator-cf"
}

module "mongodb_atlas" {
  source                             = "./modules/mongoatlas"
  stage                              = var.stage
  organization_id                    = var.org_id
  mongo_ip_access_list               = var.security.ip_whitelist
  mongo_instances                    = var.instances
  aws_vpc_id                         = var.security.aws_vpc_id
  private_subnet_ids                 = var.security.private_subnet_ids
  aws_allowed_access_security_groups = var.security.aws_allowed_access_security_groups
  jwt_audience                       = var.data_api_jwt_configurations.jwt_audience
  jwt_public_key                     = var.data_api_jwt_configurations.jwt_public_key
  tenant_id_field_in_jwt             = var.data_api_jwt_configurations.tenant_id_field_in_jwt
  display_name_field_in_jwt          = var.data_api_jwt_configurations.display_name_field_in_jwt
  add_mongo_ips_access_to_data_api   = var.data_api_jwt_configurations.add_mongo_ips_access_to_data_api
  notification_email                 = var.alerts.email_notification
  daily_price_threshold_alert        = var.alerts.daily_price_threshold_alert
  enable_continuous_backup           = var.enable_continuous_backup
  enable_termination_protection      = var.enable_termination_protection
  aws_region                         = var.region
}
