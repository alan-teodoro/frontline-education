locals {
  catalog               = yamldecode(file(var.catalog_file))
  defaults              = try(local.catalog.defaults, {})
  billing_settings      = try(local.catalog.billing, {})
  subscription_settings = try(local.catalog.subscription_settings, {})
  environment_settings  = try(local.catalog.environments[var.environment], {})
  profile               = try(local.catalog.subscription_profiles[var.subscription_family], {})
  size_key              = lower(coalesce(var.max_tier_override, try(local.profile.max_tier, null)))
  size_profile          = try(local.catalog.database_sizes[local.size_key], {})
  deployment_model      = lower(coalesce(var.deployment_model, try(local.subscription_settings.deployment_model, "managed")))
  cloud_account_name    = coalesce(var.cloud_account_name_override, try(local.environment_settings.cloud_account_name, null))
}

resource "terraform_data" "validation" {
  lifecycle {
    precondition {
      condition     = contains(keys(try(local.catalog.environments, {})), var.environment)
      error_message = "The selected environment is not present in catalog.yaml."
    }

    precondition {
      condition     = contains(keys(try(local.catalog.subscription_profiles, {})), var.subscription_family)
      error_message = "The selected subscription_family is not present in catalog.yaml."
    }

    precondition {
      condition     = local.size_key != null && contains(keys(try(local.catalog.database_sizes, {})), local.size_key)
      error_message = "The subscription profile must resolve to a known t-shirt size in catalog.yaml."
    }

    precondition {
      condition     = contains(["managed", "byoc"], local.deployment_model)
      error_message = "deployment_model must resolve to managed or byoc."
    }

    precondition {
      condition     = local.deployment_model != "byoc" || local.cloud_account_name != null
      error_message = "When deployment_model is byoc, cloud_account_name must be available from catalog.yaml or cloud_account_name_override."
    }
  }
}
