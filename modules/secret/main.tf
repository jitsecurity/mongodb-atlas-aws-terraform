resource "aws_secretsmanager_secret" "secret" {
  name                    = var.secret_name
  description             = var.description
  recovery_window_in_days = "0"

  // this is optional and can be set to true | false
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "secret_value" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = var.secret_value
}
