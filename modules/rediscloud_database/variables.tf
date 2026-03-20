variable "subscription_id" {
  description = "Target subscription identifier."
  type        = string
}

variable "name" {
  description = "Database name."
  type        = string
}

variable "dataset_size_in_gb" {
  description = "Database dataset size in GB."
  type        = number
}

variable "throughput_measurement_by" {
  description = "Throughput measurement mode."
  type        = string
}

variable "throughput_measurement_value" {
  description = "Throughput measurement value."
  type        = number
}

variable "data_persistence" {
  description = "Persistence policy."
  type        = string
}

variable "data_eviction" {
  description = "Eviction policy."
  type        = string
}

variable "replication" {
  description = "Whether replication is enabled."
  type        = bool
}

variable "redis_version" {
  description = "Redis version for the database."
  type        = string
  default     = null
}

variable "enable_tls" {
  description = "Whether TLS is enabled."
  type        = bool
  default     = true
}

variable "enable_default_user" {
  description = "Whether the default database user is enabled."
  type        = bool
  default     = false
}

variable "support_oss_cluster_api" {
  description = "Whether OSS cluster API is supported."
  type        = bool
  default     = false
}

variable "external_endpoint_for_oss_cluster_api" {
  description = "Whether the external endpoint is used for OSS cluster API."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Whether minor versions are upgraded automatically."
  type        = bool
  default     = true
}

variable "alerts" {
  description = "Database alert definitions."
  type = list(object({
    name  = string
    value = number
  }))
  default = []
}

variable "modules" {
  description = "Database modules."
  type = list(object({
    name = string
  }))
  default = []
}

variable "tags" {
  description = "Lowercase Redis Cloud tags."
  type        = map(string)
  default     = {}
}

variable "port" {
  description = "Optional database port."
  type        = number
  default     = null
}

variable "source_ips" {
  description = "Optional source IP ranges."
  type        = list(string)
  default     = null
}

