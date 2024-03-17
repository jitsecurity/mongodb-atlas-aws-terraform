# Create the relevant DB instance.
resource "mongodbatlas_serverless_instance" "database_instance" {
  project_id = var.project_id
  name       = var.instance_name

  provider_settings_backing_provider_name = "AWS"
  provider_settings_provider_name         = "SERVERLESS"
  provider_settings_region_name           = replace(upper(var.aws_region), "-", "_")
  termination_protection_enabled          = true
  continuous_backup_enabled               = var.enable_continuous_backup

}

# The 4 resources below define the mutual private connection between AWS and atlas
resource "mongodbatlas_privatelink_endpoint_serverless" "privatelink_ep_sls" {
  project_id    = var.project_id
  instance_name = mongodbatlas_serverless_instance.database_instance.name
  provider_name = "AWS"
}

# This creates all private VPC in AWS
module "third_party_vpc_endpoint" {
  source                         = "../third_party_vpc_endpoint"
  name                           = var.instance_name
  service_name                   = mongodbatlas_privatelink_endpoint_serverless.privatelink_ep_sls.endpoint_service_name
  vpc_id                         = var.aws_vpc_id
  subnet_ids                     = var.private_subnet_ids
  allowed_access_security_groups = var.aws_allowed_access_security_groups
  stage                          = var.stage
}

# This configures the vpc in mongo side
resource "mongodbatlas_privatelink_endpoint_service_serverless" "sls_service" {
  project_id                 = var.project_id
  instance_name              = mongodbatlas_serverless_instance.database_instance.name
  comment                    = mongodbatlas_serverless_instance.database_instance.name
  endpoint_id                = mongodbatlas_privatelink_endpoint_serverless.privatelink_ep_sls.endpoint_id
  cloud_provider_endpoint_id = module.third_party_vpc_endpoint.provider_id
  provider_name              = "AWS"
}

# This is a trick, we need to re-read the private endpoint connection string, which is available on the INSTANCE
# but only after the sls_service is created.
data "mongodbatlas_serverless_instance" "aws_private_connection" {
  project_id = mongodbatlas_serverless_instance.database_instance.project_id
  name       = mongodbatlas_serverless_instance.database_instance.name

  depends_on = [mongodbatlas_privatelink_endpoint_service_serverless.sls_service]
}

# Trick #2 - in order not to cause recreation of the resources below, we are defining a local variable.
# If the instance itself doesn't yet have the private ep url, we are taking it from data source.
# if it has (2nd and further deploys) - we are taking it from the resource itself.
# this will not cause recreation of the ssm and AWS Lambda below.
locals {
  private_connection_string = coalesce(
    mongodbatlas_serverless_instance.database_instance.connection_strings_private_endpoint_srv != null ?
    mongodbatlas_serverless_instance.database_instance.connection_strings_private_endpoint_srv[0] :
    null,
    data.mongodbatlas_serverless_instance.aws_private_connection.connection_strings_private_endpoint_srv[0]
  )
}

# Save the private EP URL - this will be used in AWS Lambdas with pymongo proxy.
resource "aws_ssm_parameter" "private-endpoint-connection-string" {
  name  = "/${var.stage}/infra/mongodb/${mongodbatlas_serverless_instance.database_instance.name}/private-endpoint/connection-string"
  type  = "String"
  value = local.private_connection_string
}

# Save also standard connection, it can help us connecting through compass
resource "aws_ssm_parameter" "standard-endpoint-connection-string" {
  name  = "/${var.stage}/infra/mongodb/${mongodbatlas_serverless_instance.database_instance.name}/standard-connection/connection-string"
  type  = "String"
  value = mongodbatlas_serverless_instance.database_instance.connection_strings_standard_srv
}


# This configures the data-api with JWT token authentication.
# This also configures tenant isolation (takes the tenantId field from the JWT token and uses it as a filter)
# https://www.mongodb.com/docs/atlas/app-services/rules/filters
# NOTE - this resource is a bit weird, if you want to change the script to support something new, do the following:
# change all scripts all together to support the new change:
# 1. create/update - should perform both creation and update (so if it runs several times, it aligns the environment to what you need
# 2. get - to save in state the wanted configuration, terraform will call this each apply and if there's a drift - will call create/update script
# 3. delete - in case of deletion when resource is deleted
# after doing the change, the apply will NOT trigger an update, but WILL CHANGE THE STATE.
# this is unavoidable, in order to trigger a real update change, you will need to change the environment section.
# this can be done only after scripts are deployed.
# add VERSION env var (or change it if it's there) - and then apply again, update will be trigger and align your environment.
# so - 2 deploys will be needed (first scripts, then change a dummy env var)
resource "shell_script" "configure-data-api" {
  environment = {
    PROJECT_ID                               = var.project_id
    ATLAS_ADMIN_BASE_API_PATH                = local.mongo_atlas_api_base_admin_URL
    APP_ID                                   = var.data_api_id
    DB_INSTANCE_NAME                         = mongodbatlas_serverless_instance.database_instance.name
    FRONTEGG_PUBLIC_KEY                      = replace(var.jwt_public_key, "\n", "\\n")
    FRONTEGG_AUD                             = var.jwt_audience
    TENANT_ID_FIELD_IN_JWT                   = var.tenant_id_field_in_jwt
    APP_SERVICES_USER_DISPLAY_FIELD_FROM_JWT = "sub" # Replace with other fields if necessary
  }

  lifecycle_commands {
    create = file("${path.module}/configure_data_api_scripts/create_update.sh")
    update = file("${path.module}/configure_data_api_scripts/create_update.sh")
    read   = file("${path.module}/configure_data_api_scripts/get.sh")
    delete = file("${path.module}/configure_data_api_scripts/delete.sh")
  }
  interpreter = ["/bin/bash", "-c"]
  working_directory = path.module
}