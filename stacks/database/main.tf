module "naming" {
  source = "../../modules/naming"

  environment             = var.environment
  subscription_family     = var.subscription_family
  app_name                = var.app_name
  purpose                 = var.purpose
  tier                    = var.tier
  service_account_purpose = var.service_account_purpose
  access_level            = var.access_level
  temporary               = var.temporary
  expiration_date         = var.expiration_date
  secret_prefix           = try(local.secret_settings.prefix, "frontline-education/redis")
}

data "rediscloud_subscription" "target" {
  name = coalesce(var.subscription_name_override, module.naming.subscription_name)

  depends_on = [
    terraform_data.validation
  ]
}

module "database" {
  source = "../../modules/rediscloud_database"

  subscription_id                       = data.rediscloud_subscription.target.id
  name                                  = coalesce(var.database_name_override, module.naming.database_name)
  dataset_size_in_gb                    = local.size_profile.dataset_size_in_gb
  redis_version                         = coalesce(var.redis_version_override, try(local.defaults.redis_version, null))
  throughput_measurement_by             = try(local.size_profile.throughput_measurement_by, try(local.defaults.throughput_measurement_by, "operations-per-second"))
  throughput_measurement_value          = local.size_profile.throughput_measurement_value
  data_persistence                      = var.persistence_mode
  data_eviction                         = var.data_eviction
  replication                           = try(local.size_profile.replication, true)
  enable_tls                            = try(local.defaults.enable_tls, true)
  enable_default_user                   = try(local.defaults.enable_default_user, false)
  support_oss_cluster_api               = try(local.defaults.support_oss_cluster_api, false)
  external_endpoint_for_oss_cluster_api = try(local.defaults.external_endpoint_for_oss_cluster_api, false)
  auto_minor_version_upgrade            = try(local.defaults.auto_minor_version_upgrade, true)
  alerts                                = try(local.defaults.database_alerts, [])
  tags                                  = local.redis_tags
  port                                  = var.port
  source_ips                            = var.source_ips
}

module "access_bundle" {
  source = "../../modules/rediscloud_access_bundle"

  subscription_id                = data.rediscloud_subscription.target.id
  database_id                    = module.database.db_id
  database_name                  = module.database.name
  database_private_endpoint      = module.database.private_endpoint
  database_public_endpoint       = module.database.public_endpoint
  acl_rule_name                  = module.naming.acl_rule_name
  acl_role_name                  = module.naming.acl_role_name
  acl_user_name                  = module.naming.acl_user_name
  acl_rule_string                = coalesce(var.acl_rule_string_override, lookup(local.acl_rule_catalog, var.access_level, local.acl_rule_catalog.readwrite))
  secret_name                    = coalesce(var.secret_name_override, module.naming.secret_name)
  application_role_arns          = var.application_role_arns
  secret_recovery_window_in_days = try(local.secret_settings.recovery_window_in_days, 0)
  tags                           = local.aws_tags
}
