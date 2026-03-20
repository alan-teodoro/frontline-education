variable "bucket_name" {
  description = "Name of the S3 bucket that stores Terraform state."
  type        = string
}

variable "github_actions_role_arns" {
  description = "GitHub Actions IAM role ARNs that should access the Terraform state bucket."
  type        = set(string)
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
  description = "Optional KMS key ARN for bucket encryption."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to backend resources."
  type        = map(string)
  default     = {}
}
