mongo_atlas = {
    org_id: "YOUR_ORG_ID",
    mongo_cloudformation_publisher_id: "bb989456c78c398a858fef18f2ca1bfc1fbba082",
    ip_whitelist:     [{
      cidr        = "1.1.1.1/32"
      description = "my IP"
      }],
    instances: ["my-instance"],
    aws_vpc_id: "YOUR_VPC_ID",
    private_subnet_ids: ["SUBNET_ID1", "SUBNET_ID2"],
    add_mongo_ips_access_to_data_api: true,
    aws_allowed_access_security_groups: ["sg-XXXXXXX"],
    jwt_audience: "YOUR_EXISTING_JWT_AUDIENCE",
    jwt_public_key: "-----BEGIN PUBLIC KEY-----\nXXXX\nYYY\n-----END PUBLIC KEY-----\n",
    tenant_id_field_in_jwt: "tenantId",
    email_notification: "your_email@example.com",
    daily_price_threshold_alert: 10,
    enable_continuous_backup: false,
    enable_termination_protection: true,
    enable_cloudformation_atlas_resources: true,
    stage: "test"
}