variable "aws_region" {
  description = "AWS region where the Terraform state bucket will be created."
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name used for Terraform remote state."
  type        = string
}

variable "github_actions_role_arns" {
  description = "GitHub Actions IAM role ARNs that should access the state bucket."
  type        = set(string)

  validation {
    condition     = length(var.github_actions_role_arns) > 0
    error_message = "At least one GitHub Actions role ARN must be provided."
  }
}

variable "allowed_state_prefixes" {
  description = "Object key prefixes that GitHub Actions can manage in the backend bucket."
  type        = set(string)
  default = [
    "subscriptions/*",
    "databases/*"
  ]
}

variable "enable_versioning" {
  description = "Whether to enable bucket versioning."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Whether Terraform may destroy a non-empty bucket."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN used to encrypt the bucket."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to merge into backend resources."
  type        = map(string)
  default     = {}
}
