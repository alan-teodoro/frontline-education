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

variable "access_level" {
  description = "Logical access level."
  type        = string
  default     = "readwrite"
}

variable "secret_prefix" {
  description = "Secrets Manager prefix."
  type        = string
  default     = "frontline-education/redis"
}
