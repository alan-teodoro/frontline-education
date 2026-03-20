output "subscription_name" {
  description = "Resolved subscription name."
  value       = data.rediscloud_subscription.target.name
}

output "subscription_id" {
  description = "Resolved subscription id."
  value       = data.rediscloud_subscription.target.id
}

output "database_name" {
  description = "Managed database name."
  value       = module.database.name
}

output "database_id" {
  description = "Managed database id."
  value       = module.database.db_id
}

output "private_endpoint" {
  description = "Private endpoint to be used by the application when available."
  value       = module.database.private_endpoint
}

output "secret_name" {
  description = "Application-facing secret name."
  value       = module.access_bundle.secret_name
}

output "secret_arn" {
  description = "Application-facing secret ARN."
  value       = module.access_bundle.secret_arn
}

output "application_username" {
  description = "Generated ACL username stored in the secret."
  value       = module.access_bundle.acl_user_name
}

