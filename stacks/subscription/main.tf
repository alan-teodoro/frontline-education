data "rediscloud_cloud_account" "target" {
  exclude_internal_account = true
  provider_type            = "AWS"
  name                     = local.environment_settings.cloud_account_name
}

module "naming" {
  source = "../../modules/naming"

  environment         = var.environment
  subscription_family = var.subscription_family
}

module "subscription" {
  source = "../../modules/rediscloud_subscription"

  name                         = coalesce(var.subscription_name_override, module.naming.subscription_name)
  payment_method               = var.payment_method
  payment_method_id            = var.payment_method_id
  public_endpoint_access       = try(local.defaults.public_endpoint_access, false)
  memory_storage               = try(local.profile.memory_storage, "ram")
  cloud_account_id             = data.rediscloud_cloud_account.target.id
  region                       = local.environment_settings.region
  networking_deployment_cidr   = local.environment_settings.networking_deployment_cidr
  multiple_availability_zones  = try(local.environment_settings.multiple_availability_zones, false)
  preferred_availability_zones = try(local.environment_settings.preferred_availability_zones, [])
  dataset_size_in_gb           = local.size_profile.dataset_size_in_gb
  planned_database_quantity    = coalesce(var.planned_database_quantity_override, try(local.profile.planned_database_quantity, 1))
  replication                  = try(local.profile.replication, true)
  support_oss_cluster_api      = try(local.profile.support_oss_cluster_api, false)
  throughput_measurement_by    = try(local.size_profile.throughput_measurement_by, try(local.defaults.throughput_measurement_by, "operations-per-second"))
  throughput_measurement_value = local.size_profile.throughput_measurement_value
  modules                      = try(local.profile.modules, [])
  maintenance_window           = try(local.defaults.maintenance_windows, null)

  depends_on = [
    terraform_data.validation
  ]
}
