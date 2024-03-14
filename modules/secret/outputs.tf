output "secret_value" {
  value     = var.secret_value
  sensitive = true
}

output "secret_arn" {
  value = aws_secretsmanager_secret.secret.arn
}