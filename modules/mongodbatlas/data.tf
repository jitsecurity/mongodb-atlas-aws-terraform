data "aws_caller_identity" "current" {} # data.aws_caller_identity.current.account_id
data "aws_region" "current" {} # data.aws_region.current.name
data "aws_nat_gateways" "nat_gateways" {
  vpc_id = var.aws_vpc_id

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_nat_gateway" "example" {
  for_each = toset(data.aws_nat_gateways.nat_gateways.ids)
  id = each.value
}