locals {
  catalog              = yamldecode(file(var.catalog_file))
  defaults             = try(local.catalog.defaults, {})
  secret_settings      = try(local.catalog.secret_settings, {})
  environment_settings = try(local.catalog.environments[var.environment], {})
  size_profile         = try(local.catalog.database_sizes[var.tier], {})
  aws_region           = try(local.environment_settings.aws_region, local.environment_settings.region)
  alert_defaults = {
    dataset_size_pct                   = 80
    throughput_high_ratio_warning      = 0.7
    throughput_high_ratio_critical     = 0.9
    latency_ms_warning                 = 10
    latency_ms_critical                = 20
    replica_unable_to_sync_timeout_sec = 1
    replica_lag_sec_warning            = 60
    replica_lag_sec_critical           = 120
  }
  alert_settings = merge(local.alert_defaults, try(local.defaults.database_alert_settings, {}))
  database_alerts = try(local.defaults.database_alert_settings, null) != null ? [
    {
      name  = "dataset-size"
      value = local.alert_settings.dataset_size_pct
    },
    {
      name  = "latency"
      value = local.alert_settings.latency_ms_critical
    },
    {
      name  = "throughput-higher-than"
      value = ceil(local.size_profile.throughput_measurement_value * local.alert_settings.throughput_high_ratio_critical)
    }
  ] : try(local.defaults.database_alerts, [])

  default_acl_rule = "+@all -@dangerous +info ~*"

  redis_tags = {
    for key, value in merge(
      try(local.defaults.tags, {}),
      var.tags,
      {
        environment         = var.environment
        subscription_family = var.subscription_family
        app                 = var.app_name
        purpose             = var.purpose
        use_case            = var.purpose
        tier                = var.tier
      }
    ) : lower(key) => lower(tostring(value))
  }

  aws_tags = merge(
    try(local.defaults.tags, {}),
    var.tags,
    {
      environment         = var.environment
      subscription_family = var.subscription_family
      app                 = var.app_name
      purpose             = var.purpose
      use_case            = var.purpose
    }
  )
}

resource "terraform_data" "validation" {
  lifecycle {
    precondition {
      condition     = contains(keys(try(local.catalog.environments, {})), var.environment)
      error_message = "The selected environment is not present in catalog.yaml."
    }

    precondition {
      condition     = contains(keys(try(local.catalog.database_sizes, {})), var.tier)
      error_message = "The selected tier is not present in catalog.yaml."
    }

    precondition {
      condition     = local.alert_settings.dataset_size_pct >= 1 && local.alert_settings.dataset_size_pct <= 100
      error_message = "database_alert_settings.dataset_size_pct must be between 1 and 100."
    }

    precondition {
      condition = (
        local.alert_settings.throughput_high_ratio_warning > 0 &&
        local.alert_settings.throughput_high_ratio_warning <= 1 &&
        local.alert_settings.throughput_high_ratio_critical > 0 &&
        local.alert_settings.throughput_high_ratio_critical <= 1 &&
        local.alert_settings.throughput_high_ratio_warning < local.alert_settings.throughput_high_ratio_critical
      )
      error_message = "database_alert_settings throughput ratios must be between 0 and 1, and warning must be lower than critical."
    }

    precondition {
      condition = (
        local.alert_settings.latency_ms_warning > 0 &&
        local.alert_settings.latency_ms_critical > 0 &&
        local.alert_settings.latency_ms_warning < local.alert_settings.latency_ms_critical
      )
      error_message = "database_alert_settings latency thresholds must be positive, and warning must be lower than critical."
    }
  }
}
