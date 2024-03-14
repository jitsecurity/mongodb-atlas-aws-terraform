resource "mongodbatlas_alert_configuration" "mongo_alert" {
  enabled    = true
  event_type = var.event_type
  project_id = var.project_id

  notification {
    delay_min     = var.delay_minutes
    email_enabled = true
    interval_min  = var.alert_interval_minutes
    roles         = ["GROUP_OWNER"]
    type_name     = "GROUP"
  }
  notification {
    delay_min     = var.delay_minutes
    email_enabled = true
    interval_min  = var.alert_interval_minutes
    roles         = ["ORG_OWNER"]
    type_name     = "ORG"
  }

  notification {
    delay_min     = var.delay_minutes
    interval_min  = var.alert_interval_minutes
    type_name     = "EMAIL"
    email_address = var.email
  }

  dynamic "metric_threshold_config" {
    for_each = var.event_type == "OUTSIDE_METRIC_THRESHOLD" || var.event_type == "OUTSIDE_SERVERLESS_METRIC_THRESHOLD" ? [1] : []
    content {
      metric_name = var.metric_name
      mode        = "AVERAGE"
      operator    = var.required_operator
      threshold   = var.threshold
      units       = var.threshold_type
    }
  }

  dynamic "threshold_config" {
    for_each = var.event_type != "OUTSIDE_METRIC_THRESHOLD" && var.event_type != "OUTSIDE_SERVERLESS_METRIC_THRESHOLD" && var.threshold != null ? [1] : []
    content {
      operator  = var.required_operator
      threshold = var.threshold
      units     = var.threshold_type
    }
  }
}