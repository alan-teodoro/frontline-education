locals {
  catalog              = yamldecode(file(var.catalog_file))
  defaults             = try(local.catalog.defaults, {})
  environment_settings = try(local.catalog.environments[var.environment], {})
  profile              = try(local.catalog.subscription_profiles[var.subscription_family], {})
  size_key             = lower(coalesce(var.max_tier_override, try(local.profile.max_tier, null)))
  size_profile         = try(local.catalog.database_sizes[local.size_key], {})
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
  }
}
