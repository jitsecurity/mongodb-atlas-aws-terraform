variable "project_id" {
  type        = string
  description = "project ID of atlas"
}

variable "event_type" {
  type        = string
  description = "Event type - list is here: https://www.mongodb.com/docs/atlas/reference/api-resources-spec/#tag/Alert-Configurations/operation/createAlertConfiguration"
}

variable "metric_name" {
  type        = string
  description = "Metric name to check https://www.mongodb.com/docs/atlas/reference/api-resources-spec/#tag/Alert-Configurations/operation/createAlertConfiguration"
  default     = null
}

variable "threshold" {
  type        = number
  description = "Threshold to send alert, we will always use average"
  default     = null
}

variable "threshold_type" {
  type        = string
  description = "Threshold type"
  default     = "RAW"
}

variable "email" {
  type = string
  sensitive = true
  description = "email address for notifications"
}

variable "alert_interval_minutes" {
  type = number
  description = "Alert interval in minutes, default to 60"
  default = 60
}

variable "required_operator" {
  type        = string
  description = "required operator to test"
  default = "GREATER_THAN"

}

variable "delay_minutes" {
    type        = number
    description = "time to wait before sending the alert if it continues"
    default = 0 # amount of time to wait before sending the alert if it continues
}