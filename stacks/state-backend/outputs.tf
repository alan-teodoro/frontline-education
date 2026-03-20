output "bucket_name" {
  description = "Terraform state bucket name."
  value       = module.state_backend.bucket_name
}

output "bucket_arn" {
  description = "Terraform state bucket ARN."
  value       = module.state_backend.bucket_arn
}

output "backend_access_policy_name" {
  description = "Inline IAM policy name attached to the GitHub Actions roles."
  value       = module.state_backend.backend_access_policy_name
}

output "aws_region" {
  description = "AWS region used by the backend stack."
  value       = var.aws_region
}
