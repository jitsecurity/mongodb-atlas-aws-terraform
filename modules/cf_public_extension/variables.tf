variable "iam_actions" {
  type        = list(string)
  description = "IAM permissions required by CloudFormation resources in order to provision the resources"
}

variable "iam_resources" {
  type        = list(string)
  description = "IAM permissions required by CloudFormation resources in order to provision the resources"
}

variable "publisher_id" {
  type        = string
  description = "extension publisher ID, usually can be retrieved using console (go into a resource and check the URL)"
}
variable "custom_resources_types" {
  type        = list(string)
  description = "List of custom resource to provision, for example - ['MongoDB::Atlas::CustomDBRole]"
}

variable "policy_name" {
  type        = string
  description = "policy name that provisions the resources"
}