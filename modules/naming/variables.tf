variable "environment" {
  description = "Environment name."
  type        = string
}

variable "subscription_family" {
  description = "Subscription family or platform slice."
  type        = string
}

variable "app_name" {
  description = "Application name used for database and service account names."
  type        = string
  default     = ""
}

variable "purpose" {
  description = "Database purpose such as session, cache, or reporting."
  type        = string
  default     = ""
}

variable "tier" {
  description = "T-shirt size used in the database name."
  type        = string
  default     = ""
}

variable "service_account_purpose" {
  description = "Service account purpose such as app, pipeline, readonly, or ops."
  type        = string
  default     = "app"
}

variable "access_level" {
  description = "Logical access level."
  type        = string
  default     = "readwrite"
}

variable "temporary" {
  description = "Whether the database is temporary."
  type        = bool
  default     = false
}

variable "expiration_date" {
  description = "Expiration date in YYYY-MM-DD format when temporary is true."
  type        = string
  default     = null
}

variable "secret_prefix" {
  description = "Secrets Manager prefix."
  type        = string
  default     = "frontline-education/redis"
}
