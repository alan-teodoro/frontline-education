terraform {
  required_providers {
    rediscloud = {
      source = "RedisLabs/rediscloud"
    }
  }
}

locals {
  use_marketplace         = var.payment_method == "marketplace"
  use_credit_card         = var.payment_method == "credit-card"
  resolved_payment_method = local.use_credit_card ? coalesce(var.payment_method_id, try(data.rediscloud_payment_method.card[0].id, null)) : null
}

data "rediscloud_payment_method" "card" {
  count = local.use_credit_card && var.payment_method_id == null ? 1 : 0

  card_type         = var.payment_card_type
  last_four_numbers = var.payment_card_last_four
}

resource "rediscloud_subscription" "this" {
  name                   = var.name
  payment_method         = local.use_marketplace ? "marketplace" : null
  payment_method_id      = local.resolved_payment_method
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
      condition = (
        !local.use_credit_card ||
        var.payment_method_id != null ||
        (var.payment_card_type != null && var.payment_card_last_four != null)
      )
      error_message = "When payment_method is credit-card, provide payment_method_id or both payment_card_type and payment_card_last_four."
    }

    precondition {
      condition     = var.cloud_account_id == null || var.cloud_account_id != ""
      error_message = "cloud_account_id must be null or a valid Redis Cloud BYOC account id."
    }
  }
}
