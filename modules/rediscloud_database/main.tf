terraform {
  required_providers {
    rediscloud = {
      source = "RedisLabs/rediscloud"
    }
  }
}

resource "rediscloud_subscription_database" "this" {
  subscription_id                       = var.subscription_id
  name                                  = var.name
  dataset_size_in_gb                    = var.dataset_size_in_gb
  redis_version                         = var.redis_version
  throughput_measurement_by             = var.throughput_measurement_by
  throughput_measurement_value          = var.throughput_measurement_value
  data_persistence                      = var.data_persistence
  data_eviction                         = var.data_eviction
  replication                           = var.replication
  enable_tls                            = var.enable_tls
  enable_default_user                   = var.enable_default_user
  support_oss_cluster_api               = var.support_oss_cluster_api
  external_endpoint_for_oss_cluster_api = var.external_endpoint_for_oss_cluster_api
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  tags                                  = var.tags
  port                                  = var.port
  source_ips                            = var.source_ips

  dynamic "alert" {
    for_each = var.alerts
    content {
      name  = alert.value.name
      value = alert.value.value
    }
  }

  dynamic "modules" {
    for_each = var.modules
    content {
      name = modules.value.name
    }
  }
}
