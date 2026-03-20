output "bucket_name" {
  description = "Terraform state bucket name."
  value       = var.bucket_name
}

output "bucket_arn" {
  description = "Terraform state bucket ARN."
  value       = "arn:aws:s3:::${var.bucket_name}"
}

output "backend_access_policy_name" {
  description = "Inline IAM policy name attached to the GitHub Actions roles."
  value       = "terraform-state-${substr(sha1(var.bucket_name), 0, 12)}"
}
