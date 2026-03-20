output "subscription_id" {
  description = "Redis Cloud subscription id."
  value       = module.subscription.id
}

output "subscription_name" {
  description = "Redis Cloud subscription name."
  value       = module.subscription.name
}

output "cloud_account_name" {
  description = "Resolved Redis Cloud cloud account name."
  value       = local.environment_settings.cloud_account_name
}

output "region" {
  description = "Resolved AWS region."
  value       = local.environment_settings.region
}

