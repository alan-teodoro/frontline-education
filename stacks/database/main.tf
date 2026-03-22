data "rediscloud_subscription" "target" {
  name = var.subscription_name

  depends_on = [
    terraform_data.validation
  ]
}

module "database" {
  source = "../../modules/rediscloud_database"

  subscription_id                       = data.rediscloud_subscription.target.id
  name                                  = var.database_name
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
  acl_rule_name                  = var.acl_rule_name
  acl_role_name                  = var.acl_role_name
  acl_user_name                  = var.acl_user_name
  acl_user_password_override     = var.acl_user_password_override
  acl_rule_string                = coalesce(var.acl_rule_string_override, local.default_acl_rule)
  secret_name                    = var.secret_name
  application_role_arn           = var.application_role_arn
  secret_recovery_window_in_days = try(local.secret_settings.recovery_window_in_days, 0)
  tags                           = local.aws_tags
}
