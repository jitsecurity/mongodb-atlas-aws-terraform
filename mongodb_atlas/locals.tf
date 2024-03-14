locals {
  aws_account_id    = data.aws_caller_identity.current.account_id
  aws_region        = data.aws_region.current.name
}