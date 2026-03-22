data "rediscloud_cloud_account" "target" {
  count = local.deployment_model == "byoc" ? 1 : 0

  exclude_internal_account = true
  provider_type            = "AWS"
  name                     = local.cloud_account_name
}

locals {
  resolved_payment_method_setting = coalesce(var.payment_method, try(local.billing_settings.payment_method, null))
  use_marketplace                 = local.resolved_payment_method_setting == "marketplace"
  use_credit_card                 = local.resolved_payment_method_setting == "credit-card"
  resolved_payment_method_id      = local.use_credit_card ? coalesce(var.payment_method_id, try(data.rediscloud_payment_method.card[0].id, null)) : null
}

data "rediscloud_payment_method" "card" {
  count = local.use_credit_card && var.payment_method_id == null ? 1 : 0

  card_type         = coalesce(var.payment_card_type, try(local.billing_settings.credit_card_type, null))
  last_four_numbers = coalesce(var.payment_card_last_four, try(local.billing_settings.credit_card_last_four, null))
}

resource "rediscloud_subscription" "this" {
  name                   = var.subscription_name
  payment_method         = local.use_marketplace ? "marketplace" : null
  payment_method_id      = local.resolved_payment_method_id
  public_endpoint_access = try(local.defaults.public_endpoint_access, false)
  memory_storage         = try(local.profile.memory_storage, "ram")

  cloud_provider {
    provider         = "AWS"
    cloud_account_id = local.deployment_model == "byoc" ? data.rediscloud_cloud_account.target[0].id : null

    region {
      region                       = local.environment_settings.region
      multiple_availability_zones  = try(local.environment_settings.multiple_availability_zones, false)
      networking_deployment_cidr   = local.environment_settings.networking_deployment_cidr
      preferred_availability_zones = try(local.environment_settings.preferred_availability_zones, [])
    }
  }

  creation_plan {
    dataset_size_in_gb           = local.size_profile.dataset_size_in_gb
    quantity                     = 1
    replication                  = try(local.profile.replication, true)
    support_oss_cluster_api      = try(local.profile.support_oss_cluster_api, false)
    throughput_measurement_by    = try(local.size_profile.throughput_measurement_by, try(local.defaults.throughput_measurement_by, "operations-per-second"))
    throughput_measurement_value = local.size_profile.throughput_measurement_value
    modules                      = try(local.profile.modules, [])
  }

  dynamic "maintenance_windows" {
    for_each = try(local.defaults.maintenance_windows, null) == null ? [] : [local.defaults.maintenance_windows]
    content {
      mode = maintenance_windows.value.mode

      window {
        start_hour        = maintenance_windows.value.window.start_hour
        duration_in_hours = maintenance_windows.value.window.duration_in_hours
        days              = maintenance_windows.value.window.days
      }
    }
  }

  depends_on = [
    terraform_data.validation
  ]

  lifecycle {
    precondition {
      condition = (
        !local.use_credit_card ||
        var.payment_method_id != null ||
        (
          coalesce(var.payment_card_type, try(local.billing_settings.credit_card_type, null)) != null &&
          coalesce(var.payment_card_last_four, try(local.billing_settings.credit_card_last_four, null)) != null
        )
      )
      error_message = "When payment_method resolves to credit-card, provide payment_method_id or both payment_card_type and payment_card_last_four."
    }

    precondition {
      condition     = local.deployment_model != "byoc" || (length(data.rediscloud_cloud_account.target) > 0 && data.rediscloud_cloud_account.target[0].id != "")
      error_message = "cloud_account_id must resolve to a valid Redis Cloud BYOC account id when deployment_model is byoc."
    }
  }
}
