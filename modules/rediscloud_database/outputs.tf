output "db_id" {
  description = "Database identifier."
  value       = rediscloud_subscription_database.this.db_id
}

output "name" {
  description = "Database name."
  value       = rediscloud_subscription_database.this.name
}

output "private_endpoint" {
  description = "Private database endpoint."
  value       = rediscloud_subscription_database.this.private_endpoint
}

output "public_endpoint" {
  description = "Public database endpoint."
  value       = rediscloud_subscription_database.this.public_endpoint
}

