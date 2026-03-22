output "subscription_id" {
  description = "Redis Cloud subscription id."
  value       = rediscloud_subscription.this.id
}

output "subscription_name" {
  description = "Redis Cloud subscription name."
  value       = rediscloud_subscription.this.name
}

output "cloud_account_name" {
  description = "Resolved Redis Cloud cloud account name."
  value       = local.deployment_model == "byoc" ? local.cloud_account_name : null
}

output "deployment_model" {
  description = "Resolved subscription deployment model."
  value       = local.deployment_model
}

output "region" {
  description = "Resolved AWS region."
  value       = local.environment_settings.region
}
