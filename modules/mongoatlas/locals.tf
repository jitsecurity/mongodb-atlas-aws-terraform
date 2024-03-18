locals {
  # This maps aws regions to mongo locations.
  aws_region_to_atlas_location_map = {
    "us-east-1"      = "US-VA"
    "us-west-2"      = "US-OR"
    "eu-central-1"   = "DE-FF"
    "eu-west-1"      = "IE"
    "ap-southeast-2" = "AU"
    "ap-south-1"     = "IN-MB"
    "ap-southeast-1" = "SG"
    "sa-east-1"      = "BR-SP"
  }
  mongo_atlas_api_base_admin_URL = "https://realm.mongodb.com/api/admin/v3.0"
  aws_account_id    = data.aws_caller_identity.current.account_id
  aws_region        = data.aws_region.current.name
  nat_gw_public_ips = [for _, ngw in data.aws_nat_gateway.example : ngw.public_ip]
}