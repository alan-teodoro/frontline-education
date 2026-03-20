locals {
  normalize = {
    environment         = trim(replace(replace(lower(var.environment), "/[^a-z0-9-]/", "-"), "/-+/", "-"), "-")
    subscription_family = trim(replace(replace(lower(var.subscription_family), "/[^a-z0-9-]/", "-"), "/-+/", "-"), "-")
    app_name            = trim(replace(replace(lower(var.app_name), "/[^a-z0-9-]/", "-"), "/-+/", "-"), "-")
    purpose             = trim(replace(replace(lower(var.purpose), "/[^a-z0-9-]/", "-"), "/-+/", "-"), "-")
    tier                = trim(replace(replace(lower(var.tier), "/[^a-z0-9-]/", "-"), "/-+/", "-"), "-")
    secret_prefix       = trim(replace(replace(lower(var.secret_prefix), "/[^a-z0-9/-]/", "-"), "/-+/", "-"), "/")
  }

  database_name = join("-", compact([
    local.normalize.app_name,
    local.normalize.purpose
  ]))
}
