org_id                                = "YOUR_ORG_ID"
instances                             = ["my-instance"]
enable_continuous_backup              = false
enable_termination_protection         = true
enable_cloudformation_atlas_resources = false
stage                                 = "test"

security                              = {
  aws_vpc_id                        : "vpc-xxxxxxx",
  private_subnet_ids                : ["subnet-aaa", "subnet-bbb"],
  aws_allowed_access_security_groups : ["sg-xxxxxx"],
  ip_whitelist                      : [
    {
      cidr        : "1.1.1.1/32",
      description : "my IP"
    }
  ]
}

data_api_configurations           = {
  jwt_audience              : "aud",
  jwt_public_key            : "-----BEGIN PUBLIC KEY-----\nXXXX\nYYY\n-----END PUBLIC KEY-----\n",
  tenant_id_field_in_jwt    : "tenantId",
  display_name_field_in_jwt : "sub",
  add_mongo_ips_access_to_data_api  : true
}

alerts                                = {
  email_notification          : "your_email@example.com",
  daily_price_threshold_alert : 10
}
