variable "catalog_file" {
  description = "Path to the YAML catalog."
  type        = string
  default     = "../../config/catalog.yaml"
}

variable "environment" {
  description = "Environment to target."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "stage", "prod"], var.environment)
    error_message = "environment must be one of dev, qa, stage, or prod."
  }
}

variable "subscription_family" {
  description = "Subscription family."
  type        = string
}

variable "subscription_name_override" {
  description = "Optional explicit subscription name."
  type        = string
  default     = null
}

variable "app_name" {
  description = "Application name."
  type        = string
}

variable "purpose" {
  description = "Database purpose."
  type        = string
}

variable "tier" {
  description = "T-shirt size for the database."
  type        = string

  validation {
    condition     = contains(["s", "m", "l", "xl"], var.tier)
    error_message = "tier must be one of s, m, l, or xl."
  }
}

variable "persistence_mode" {
  description = "Database persistence mode."
  type        = string

  validation {
    condition = contains([
      "none",
      "aof-every-1-second",
      "aof-every-write",
      "snapshot-every-1-hour",
      "snapshot-every-6-hours",
      "snapshot-every-12-hours"
    ], var.persistence_mode)
    error_message = "persistence_mode must be one of none, aof-every-1-second, aof-every-write, snapshot-every-1-hour, snapshot-every-6-hours, or snapshot-every-12-hours."
  }
}

variable "data_eviction" {
  description = "Database eviction policy."
  type        = string

  validation {
    condition = contains([
      "allkeys-lru",
      "allkeys-lfu",
      "allkeys-random",
      "volatile-lru",
      "volatile-lfu",
      "volatile-random",
      "volatile-ttl",
      "noeviction"
    ], var.data_eviction)
    error_message = "data_eviction must be one of allkeys-lru, allkeys-lfu, allkeys-random, volatile-lru, volatile-lfu, volatile-random, volatile-ttl, or noeviction."
  }
}

variable "application_role_arn" {
  description = "IAM role ARN that should read the generated secret."
  type        = string

  validation {
    condition     = trimspace(var.application_role_arn) != ""
    error_message = "application_role_arn must be provided."
  }
}

variable "access_level" {
  description = "Logical access level such as readwrite, readonly, or ops."
  type        = string
  default     = "readwrite"
}

variable "database_name_override" {
  description = "Optional explicit database name."
  type        = string
  default     = null
}

variable "secret_name_override" {
  description = "Optional explicit secret name."
  type        = string
  default     = null
}

variable "acl_user_password_override" {
  description = "Optional explicit ACL user password override, intended mainly for controlled testing."
  type        = string
  default     = null
}

variable "acl_rule_string_override" {
  description = "Optional explicit ACL rule string."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to merge into Redis Cloud and AWS resources."
  type        = map(string)
  default     = {}
}

variable "port" {
  description = "Optional database port."
  type        = number
  default     = null
}

variable "source_ips" {
  description = "Optional source IPs for the database."
  type        = list(string)
  default     = null
}

variable "redis_version_override" {
  description = "Optional explicit Redis version."
  type        = string
  default     = null
}
