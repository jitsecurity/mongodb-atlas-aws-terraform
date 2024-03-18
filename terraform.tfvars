mongo_atlas = {
    org_id: "639b3e430709e57f49adca31",
    mongo_cloudformation_publisher_id: "bb989456c78c398a858fef18f2ca1bfc1fbba082",
    ip_whitelist:     [{
      cidr        = "1.1.1.1/32"
      description = "my IP"
      }],
    instances: ["my-instance"],
    aws_vpc_id: "vpc-0fa423ff6dc4f52e9",
    private_subnet_ids: ["subnet-0b75827734a80d0d3"],
    add_mongo_ips_access_to_data_api: true,
    aws_allowed_access_security_groups: ["sg-02734dc05bb87697e"],
    jwt_audience: "aud",
    jwt_public_key: "-----BEGIN PUBLIC KEY-----\nXXXX\nYYY\n-----END PUBLIC KEY-----\n",
    tenant_id_field_in_jwt: "tenantId",
    display_name_field_in_jwt: "sub",
    email_notification: "your_email@example.com",
    daily_price_threshold_alert: 10,
    enable_continuous_backup: false,
    enable_termination_protection: true,
    stage: "test",
    enable_cloudformation_atlas_resources: false
}
