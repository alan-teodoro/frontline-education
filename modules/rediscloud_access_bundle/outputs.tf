output "acl_user_name" {
  description = "ACL user name."
  value       = rediscloud_acl_user.this.name
}

output "secret_name" {
  description = "Secrets Manager secret name."
  value       = aws_secretsmanager_secret.this.name
}

output "secret_arn" {
  description = "Secrets Manager secret ARN."
  value       = aws_secretsmanager_secret.this.arn
}

output "iam_policy_arn" {
  description = "IAM policy ARN granting secret read access."
  value       = aws_iam_policy.secret_access.arn
}

