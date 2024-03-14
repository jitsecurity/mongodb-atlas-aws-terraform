resource "aws_iam_role" "extension-activation-role" {
  name = "${var.policy_name}-role"

  assume_role_policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Effect : "Allow"
        Principal : {
          Service : ["resources.cloudformation.amazonaws.com"]
        }
        Action : "sts:AssumeRole"
      }
    ]
  })

  path = "/"

  max_session_duration = 8400
}

resource "aws_iam_policy" "extension-activator-policy" {
  name = var.policy_name

  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Effect : "Allow"
        Action : var.iam_actions
        Resource : var.iam_resources
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "extension-activator-role-policy-attachment" {
  policy_arn = aws_iam_policy.extension-activator-policy.arn
  role       = aws_iam_role.extension-activation-role.name
}

resource "shell_script" "cf_activation_script" {
  for_each = toset(var.custom_resources_types)
  lifecycle_commands {
    create = "aws cloudformation activate-type   --type RESOURCE --type-name ${each.value} --execution-role-arn ${aws_iam_role.extension-activation-role.arn} --publisher-id ${var.publisher_id} >/dev/null"
    update = "aws cloudformation activate-type   --type RESOURCE --type-name ${each.value} --execution-role-arn ${aws_iam_role.extension-activation-role.arn} --publisher-id ${var.publisher_id} >/dev/null"
    read   = "aws cloudformation describe-type   --type RESOURCE --type-name ${each.value}"
    delete = "aws cloudformation deactivate-type --type RESOURCE --type-name ${each.value}"
  }

  //sets current working directory
  working_directory = path.module

  depends_on = [aws_iam_policy.extension-activator-policy, aws_iam_role.extension-activation-role, aws_iam_role_policy_attachment.extension-activator-role-policy-attachment]
}
