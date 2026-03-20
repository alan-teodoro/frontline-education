output "id" {
  description = "Subscription identifier."
  value       = rediscloud_subscription.this.id
}

output "name" {
  description = "Subscription name."
  value       = rediscloud_subscription.this.name
}

output "public_endpoint_access" {
  description = "Whether public endpoint access is enabled."
  value       = rediscloud_subscription.this.public_endpoint_access
}

