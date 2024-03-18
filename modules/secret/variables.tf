variable "secret_name" {
  type = string
  description = "The name of the secret"
}

variable "description" {
  type = string
  description = "The description of the secret"
}

variable "secret_value" {
  type      = string
  sensitive = true
  description = "The value of the secret - will be encrypted at rest"
}
