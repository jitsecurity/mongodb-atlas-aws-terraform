module "mongo-cf-secret" {
  source      = "./modules/secret"
  secret_name = "cfn/atlas/profile/${var.mongo_atlas.org_id}"
  secret_value = jsonencode({
    PublicKey  = var.mongo_atlas_public_key
    PrivateKey = var.mongo_atlas_private_key
  })
  description = "Required to be able to use cloudformation resources to create mongo resources"
}

module "mongo-cf-activation" {
  source        = "./modules/cf_public_extension"
  iam_actions   = ["secretsmanager:GetSecretValue"]
  iam_resources = [module.mongo-cf-secret.secret_arn]
  publisher_id  = var.mongo_atlas.mongo_cloudformation_publisher_id
  custom_resources_types = ["MongoDB::Atlas::CustomDBRole",
  "MongoDB::Atlas::DatabaseUser"]
  policy_name = "mongo-resource-activator-cf"
}

module "mongodb_atlas" {
  source                             = "./modules/mongodbatlas"
  stage                              = var.mongo_atlas.stage
  organization_id                    = var.mongo_atlas.org_id
  mongo_ip_access_list               = var.mongo_atlas.ip_whitelist
  mongo_instances                    = var.mongo_atlas.instances
  aws_vpc_id                         = var.mongo_atlas.aws_vpc_id
  private_subnet_ids                 = var.mongo_atlas.private_subnet_ids
  add_mongo_ips_access_to_data_api   = var.mongo_atlas.add_mongo_ips_access_to_data_api
  aws_allowed_access_security_groups = var.mongo_atlas.aws_allowed_access_security_groups
  jwt_audience                       = var.mongo_atlas.jwt_audience
  jwt_public_key                     = var.mongo_atlas.jwt_public_key
  tenant_id_field_in_jwt             = var.mongo_atlas.tenant_id_field_in_jwt
  notification_email                 = var.mongo_atlas.email_notification
  enable_continuous_backup           = var.mongo_atlas.enable_continuous_backup
  daily_price_threshold_alert        = var.mongo_atlas.daily_price_threshold_alert
  aws_region                         = local.aws_region
}
