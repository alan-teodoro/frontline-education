locals {
  catalog              = yamldecode(file(var.catalog_file))
  defaults             = try(local.catalog.defaults, {})
  secret_settings      = try(local.catalog.secret_settings, {})
  environment_settings = try(local.catalog.environments[var.environment], {})
  size_profile         = try(local.catalog.database_sizes[var.tier], {})
  aws_region           = try(local.environment_settings.aws_region, local.environment_settings.region)

  acl_rule_catalog = {
    readwrite = "+@all -@dangerous +info ~*"
    readonly  = "+@read +info ~*"
    ops       = "+@all -@dangerous +info ~*"
    pipeline  = "+@all -@dangerous +info ~*"
  }

  redis_tags = {
    for key, value in merge(
      try(local.defaults.tags, {}),
      var.tags,
      {
        environment         = var.environment
        subscription_family = var.subscription_family
        app                 = var.app_name
        purpose             = var.purpose
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
  }
}
