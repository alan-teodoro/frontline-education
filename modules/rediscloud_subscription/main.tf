terraform {
  required_providers {
    rediscloud = {
      source = "RedisLabs/rediscloud"
    }
  }
}

resource "rediscloud_subscription" "this" {
  name                   = var.name
  payment_method         = var.payment_method
  payment_method_id      = var.payment_method_id
  public_endpoint_access = var.public_endpoint_access
  memory_storage         = var.memory_storage

  dynamic "allowlist" {
    for_each = length(var.allowlist_cidrs) > 0 || length(var.allowlist_security_group_ids) > 0 ? [1] : []
    content {
      cidrs              = var.allowlist_cidrs
      security_group_ids = var.allowlist_security_group_ids
    }
  }

  cloud_provider {
    provider         = "AWS"
    cloud_account_id = var.cloud_account_id

    region {
      region                       = var.region
      multiple_availability_zones  = var.multiple_availability_zones
      networking_deployment_cidr   = var.networking_deployment_cidr
      preferred_availability_zones = var.preferred_availability_zones
    }
  }

  creation_plan {
    dataset_size_in_gb           = var.dataset_size_in_gb
    quantity                     = var.planned_database_quantity
    replication                  = var.replication
    support_oss_cluster_api      = var.support_oss_cluster_api
    throughput_measurement_by    = var.throughput_measurement_by
    throughput_measurement_value = var.throughput_measurement_value
    modules                      = var.modules
  }

  dynamic "maintenance_windows" {
    for_each = var.maintenance_window == null ? [] : [var.maintenance_window]
    content {
      mode = maintenance_windows.value.mode

      window {
        start_hour        = maintenance_windows.value.window.start_hour
        duration_in_hours = maintenance_windows.value.window.duration_in_hours
        days              = maintenance_windows.value.window.days
      }
    }
  }

  lifecycle {
    precondition {
      condition     = !(var.payment_method == "credit-card" && var.payment_method_id == null)
      error_message = "payment_method_id must be provided when payment_method is credit-card."
    }
  }
}
