# All alerts configurations can be seen here:
# https://www.mongodb.com/docs/atlas/reference/api-resources-spec/v2/#tag/Alert-Configurations/operation/createAlertConfiguration
# It's possible to support all sorts of notifications targets (slack, etc..) - we use email here for simplicity

# This in case data-api returns a rate limit
module "alert_app_services_rate_limit" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "REQUEST_RATE_LIMIT"
  email = var.notification_email
}

# in case daily billing is bigger than expected (let's say 6 dollars)
module "alert_daily_bill" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "DAILY_BILL_OVER_THRESHOLD"
  threshold  = var.daily_price_threshold_alert
  alert_interval_minutes = 1440 # one day
  email = var.notification_email
}


# monthly price alert
module "alert_monthly_bill" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "PENDING_INVOICE_OVER_THRESHOLD"
  threshold  = var.monthly_price_threshold
  alert_interval_minutes = 10080 # one week
  email = var.notification_email
}

# if 80% of connections are used (500 are max)
module "alert_above_80_percent_connections" {
  source      = "../mongoatlas_alert"
  project_id  = mongodbatlas_project.main-project.id
  event_type  = "OUTSIDE_SERVERLESS_METRIC_THRESHOLD"
  metric_name = "SERVERLESS_CONNECTIONS_PERCENT"
  threshold   = 80
  email = var.notification_email
}

# if 75% of disk was used - there's a cap of 1TB per serverless cluster
module "alert_disk_space_getting_full" {
  source         = "../mongoatlas_alert"
  project_id     = mongodbatlas_project.main-project.id
  event_type     = "OUTSIDE_SERVERLESS_METRIC_THRESHOLD"
  metric_name    = "SERVERLESS_DATA_SIZE_TOTAL"
  threshold      = 0.75
  threshold_type = "TERABYTES"
  email = var.notification_email
}

# too many reads
module "alert_too_many_rpus" {
  source         = "../mongoatlas_alert"
  project_id     = mongodbatlas_project.main-project.id
  event_type     = "OUTSIDE_SERVERLESS_METRIC_THRESHOLD"
  metric_name    = "SERVERLESS_TOTAL_READ_UNITS"
  threshold      = 1
  alert_interval_minutes = 120
  delay_minutes = 5
  threshold_type = "MILLION_RPU"
  email = var.notification_email
}

# too many reads - lower threshold
module "alert_too_many_rpus_lower_threshold" {
  source         = "../mongoatlas_alert"
  project_id     = mongodbatlas_project.main-project.id
  event_type     = "OUTSIDE_SERVERLESS_METRIC_THRESHOLD"
  metric_name    = "SERVERLESS_TOTAL_READ_UNITS"
  threshold      = 0.25
  alert_interval_minutes = 720
  delay_minutes = 30
  threshold_type = "MILLION_RPU"
  email = var.notification_email
}


# too many writes
module "alert_too_many_wpus" {
  source         = "../mongoatlas_alert"
  project_id     = mongodbatlas_project.main-project.id
  event_type     = "OUTSIDE_SERVERLESS_METRIC_THRESHOLD"
  metric_name    = "SERVERLESS_TOTAL_WRITE_UNITS"
  threshold      = 1
  threshold_type = "MILLION_WPU"
  email = var.notification_email
}

# default alerts came with the projects - defining here to include slack notifications
# ==========================================================================

# Alert for replication oplog window running out - triggered when the value is LESS_THAN 1 hours
module "alert_replication_oplog_window_running_out" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "REPLICATION_OPLOG_WINDOW_RUNNING_OUT"
  threshold  = 1
  required_operator = "LESS_THAN"
  threshold_type = "HOURS"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for no primary
module "alert_no_primary" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "NO_PRIMARY"
  delay_minutes = 15
  email = var.notification_email
}

# Alert for cluster mongos is missing
module "alert_cluster_mongos_is_missing" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "CLUSTER_MONGOS_IS_MISSING"
  delay_minutes = 15
  email = var.notification_email
}

# Alert for outside metric threshold - triggered based on the connections percent when the value is GREATER_THAN 80.0 raw
module "alert_outside_metric_threshold_connections_percent" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "OUTSIDE_METRIC_THRESHOLD"
  metric_name    = "CONNECTIONS_PERCENT"
  threshold      = 80.0
  required_operator = "GREATER_THAN"
  threshold_type = "RAW"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for outside metric threshold - triggered based on the disk partition space used data when the value is GREATER_THAN 90.0 raw
module "alert_outside_metric_threshold_disk_partition_space_used_data" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "OUTSIDE_METRIC_THRESHOLD"
  metric_name    = "DISK_PARTITION_SPACE_USED_DATA"
  threshold      = 90.0
  required_operator = "GREATER_THAN"
  threshold_type = "RAW"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for outside metric threshold - triggered based on the query targeting scanned objects per returned when the value is GREATER_THAN 1000.0 raw
module "alert_outside_metric_threshold_query_targeting_scanned_objects_per_returned" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "OUTSIDE_METRIC_THRESHOLD"
  metric_name    = "QUERY_TARGETING_SCANNED_OBJECTS_PER_RETURNED"
  threshold      = 1000.0
  required_operator = "GREATER_THAN"
  threshold_type = "RAW"
  delay_minutes = 10
  email = var.notification_email
}

# Alert for credit card about to expire
module "alert_credit_card_about_to_expire" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "CREDIT_CARD_ABOUT_TO_EXPIRE"
  delay_minutes = 0
  alert_interval_minutes = 1440
  email = var.notification_email
}

# Alert for outside metric threshold - triggered based on the normalized system cpu user when the value is GREATER_THAN 95.0 raw
module "alert_outside_metric_threshold_normalized_system_cpu_user" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "OUTSIDE_METRIC_THRESHOLD"
  metric_name    = "NORMALIZED_SYSTEM_CPU_USER"
  threshold      = 95.0
  required_operator = "GREATER_THAN"
  threshold_type = "RAW"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for host has index suggestions
module "alert_host_has_index_suggestions" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "HOST_HAS_INDEX_SUGGESTIONS"
  delay_minutes = 10
  email = var.notification_email
}

# Alert for host mongot crashing oom
module "alert_host_mongot_crashing_oom" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "HOST_MONGOT_CRASHING_OOM"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for host not enough disk space
module "alert_host_not_enough_disk_space" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "HOST_NOT_ENOUGH_DISK_SPACE"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for outside metric threshold - triggered based on the search max number of lucene docs when the value is GREATER_THAN 1.0 billion
module "alert_outside_metric_threshold_search_max_number_of_lucene_docs" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "OUTSIDE_METRIC_THRESHOLD"
  metric_name    = "SEARCH_MAX_NUMBER_OF_LUCENE_DOCS"
  threshold      = 1.0
  required_operator = "GREATER_THAN"
  threshold_type = "BILLION"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for joined group
module "alert_joined_group" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "JOINED_GROUP"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for trigger failure
module "alert_trigger_failure" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "TRIGGER_FAILURE"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for trigger auto resumed
module "alert_trigger_auto_resumed" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "TRIGGER_AUTO_RESUMED"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for sync failure
module "alert_sync_failure" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "SYNC_FAILURE"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for log forwarder failure
module "alert_log_forwarder_failure" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "LOG_FORWARDER_FAILURE"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for fts index deletion failed
module "alert_fts_index_deletion_failed" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "FTS_INDEX_DELETION_FAILED"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for fts index build complete
module "alert_fts_index_build_complete" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "FTS_INDEX_BUILD_COMPLETE"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for fts index build failed
module "alert_fts_index_build_failed" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "FTS_INDEX_BUILD_FAILED"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for fts indexes restore failed
module "alert_fts_indexes_restore_failed" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "FTS_INDEXES_RESTORE_FAILED"
  delay_minutes = 0
  email = var.notification_email
}

# Alert for outside metric threshold - triggered based on the system memory percent used when the value is GREATER_THAN 90.0 raw
module "alert_outside_metric_threshold_system_memory_percent_used" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "OUTSIDE_METRIC_THRESHOLD"
  metric_name    = "SYSTEM_MEMORY_PERCENT_USED"
  threshold      = 90.0
  required_operator = "GREATER_THAN"
  threshold_type = "RAW"
  delay_minutes = 60
  alert_interval_minutes = 10080
  email = var.notification_email
}

# Alert for outside metric threshold - triggered based on the max normalized system cpu user when the value is GREATER_THAN 90.0 raw
module "alert_outside_metric_threshold_max_normalized_system_cpu_user" {
  source     = "../mongoatlas_alert"
  project_id = mongodbatlas_project.main-project.id
  event_type = "OUTSIDE_METRIC_THRESHOLD"
  metric_name    = "MAX_NORMALIZED_SYSTEM_CPU_USER"
  threshold      = 90.0
  required_operator = "GREATER_THAN"
  threshold_type = "RAW"
  delay_minutes = 60
  alert_interval_minutes = 10080
  email = var.notification_email
}

