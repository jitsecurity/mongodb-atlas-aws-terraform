# This is the main project to create under an org, project per env.
resource "mongodbatlas_project" "main-project" {
  name                                             = var.stage
  org_id                                           = var.organization_id
  is_collect_database_specifics_statistics_enabled = true
  is_data_explorer_enabled                         = true
  is_performance_advisor_enabled                   = true
  is_realtime_performance_panel_enabled            = true
  is_schema_advisor_enabled                        = true
  with_default_alerts_settings                     = false # as we manage the alerts ourselves to allow adding notification targets
}

# In order to connect to the DBs (from compass), IP cidr is needed.
resource "mongodbatlas_project_ip_access_list" "mongo_ip_access_list" {
  project_id = mongodbatlas_project.main-project.id
  cidr_block = element(var.mongo_ip_access_list, count.index).cidr
  comment    = element(var.mongo_ip_access_list, count.index).description
  count      = length(var.mongo_ip_access_list)
  depends_on = [mongodbatlas_project.main-project]
}


# This script enables data API (to be used from customer facing APIs).
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
resource "shell_script" "enable-data-api" {
  environment = {
    VERSION                   = 1
    PROJECT_ID                = mongodbatlas_project.main-project.id
    AWS_REGION                = var.aws_region
    MONGO_LOCATION            = local.aws_region_to_atlas_location_map[var.aws_region]
    ATLAS_ADMIN_BASE_API_PATH = local.mongo_atlas_api_base_admin_URL
  }

  interpreter = ["/bin/bash", "-c"]

  lifecycle_commands {
    create = file("${path.module}/scripts/create_update_data_api.sh")
    update = file("${path.module}/scripts/create_update_data_api.sh")
    read   = file("${path.module}/scripts/get_data_api.sh")
    delete = file("${path.module}/scripts/delete_data_api.sh")
  }

  working_directory = path.module
}


resource "shell_script" "configure-data-api-security" {
  environment = {
    VERSION                   = 1
    PROJECT_ID                = mongodbatlas_project.main-project.id
    ATLAS_ADMIN_BASE_API_PATH = local.mongo_atlas_api_base_admin_URL
    DATA_API_APP_ID           = shell_script.enable-data-api.output["data_api_id"]
    AWS_NAT_GW_IPS            = var.add_mongo_ips_access_to_data_api ? join(",", concat(local.nat_gw_public_ips, [for ip in var.mongo_ip_access_list : ip.cidr])) : join(",", local.nat_gw_public_ips)
  }

  interpreter = ["/bin/bash", "-c"]

  lifecycle_commands {
    create = file("${path.module}/scripts/create_update_data_api_security.sh")
    update = file("${path.module}/scripts/create_update_data_api_security.sh")
    read   = file("${path.module}/scripts/get_data_api_security.sh")
    delete = file("${path.module}/scripts/delete_data_api_security.sh")
  }

  working_directory = path.module
}

# Save the data-api URL so we can later use it in the AWS Lambdas.
resource "aws_ssm_parameter" "data-api-URL" {
  name  = "/${var.stage}/infra/mongodb/data-api/url"
  type  = "String"
  value = "https://${var.aws_region}.aws.data.mongodb-api.com/app/${shell_script.enable-data-api.output["client_id"]}/endpoint/data/v1"
}


# create the atlas instance per variable defined
module "atlas_instance" {
  count                              = length(var.mongo_instances)
  source                             = "../mongoatlas_instance"
  stage                              = var.stage
  project_id                         = mongodbatlas_project.main-project.id
  instance_name                      = element(var.mongo_instances, count.index)
  aws_account_id                     = local.aws_account_id
  organization_id                    = var.organization_id
  aws_vpc_id                         = var.aws_vpc_id
  private_subnet_ids                 = var.private_subnet_ids
  aws_allowed_access_security_groups = var.aws_allowed_access_security_groups
  enable_termination_protection      = var.enable_termination_protection
  jwt_audience                       = var.jwt_audience
  jwt_public_key                     = var.jwt_public_key
  data_api_id                        = shell_script.enable-data-api.output["data_api_id"]
  enable_continuous_backup           = var.enable_continuous_backup
  tenant_id_field_in_jwt             = var.tenant_id_field_in_jwt
}
