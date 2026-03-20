variable "subscription_id" {
  description = "Subscription identifier."
  type        = string
}

variable "database_id" {
  description = "Database identifier."
  type        = string
}

variable "database_name" {
  description = "Database name."
  type        = string
}

variable "database_private_endpoint" {
  description = "Private endpoint to prefer for the secret payload."
  type        = string
  default     = null
}

variable "database_public_endpoint" {
  description = "Public endpoint, if one exists."
  type        = string
  default     = null
}

variable "acl_rule_name" {
  description = "ACL rule name."
  type        = string
}

variable "acl_role_name" {
  description = "ACL role name."
  type        = string
}

variable "acl_user_name" {
  description = "ACL user name."
  type        = string
}

variable "acl_user_password_override" {
  description = "Optional explicit ACL user password override, intended mainly for controlled testing."
  type        = string
  default     = null
}

variable "acl_rule_string" {
  description = "ACL rule string."
  type        = string
}

variable "secret_name" {
  description = "AWS Secrets Manager secret name."
  type        = string
}

variable "application_role_arn" {
  description = "IAM role ARN that should be allowed to read the secret."
  type        = string
}

variable "secret_recovery_window_in_days" {
  description = "Recovery window for the secret."
  type        = number
  default     = 0
}

variable "tags" {
  description = "AWS tags."
  type        = map(string)
  default     = {}
}
