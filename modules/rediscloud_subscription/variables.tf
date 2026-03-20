variable "name" {
  description = "Subscription name."
  type        = string
}

variable "payment_method" {
  description = "Payment method, for example credit-card or marketplace."
  type        = string
  default     = null
}

variable "payment_method_id" {
  description = "Payment method identifier when using credit-card."
  type        = string
  default     = null
}

variable "public_endpoint_access" {
  description = "Whether public endpoint access is enabled."
  type        = bool
  default     = false
}

variable "memory_storage" {
  description = "Memory storage type."
  type        = string
  default     = "ram"
}

variable "cloud_account_id" {
  description = "Redis Cloud account identifier for the AWS account."
  type        = string
}

variable "region" {
  description = "AWS region for the subscription."
  type        = string
}

variable "networking_deployment_cidr" {
  description = "Deployment CIDR for the subscription."
  type        = string
}

variable "multiple_availability_zones" {
  description = "Whether to use multiple availability zones."
  type        = bool
  default     = false
}

variable "preferred_availability_zones" {
  description = "Preferred availability zones."
  type        = list(string)
  default     = []
}

variable "dataset_size_in_gb" {
  description = "Largest expected dataset size for the subscription creation plan."
  type        = number
}

variable "planned_database_quantity" {
  description = "Expected number of databases for the subscription."
  type        = number
}

variable "replication" {
  description = "Whether replication is enabled."
  type        = bool
}

variable "support_oss_cluster_api" {
  description = "Whether OSS cluster API should be supported."
  type        = bool
  default     = false
}

variable "throughput_measurement_by" {
  description = "Throughput measurement mode."
  type        = string
}

variable "throughput_measurement_value" {
  description = "Throughput measurement value."
  type        = number
}

variable "modules" {
  description = "Redis modules to include in the creation plan."
  type        = list(string)
  default     = []
}

variable "maintenance_window" {
  description = "Optional maintenance window definition."
  type = object({
    mode = string
    window = object({
      start_hour        = number
      duration_in_hours = number
      days              = list(string)
    })
  })
  default = null
}

variable "allowlist_cidrs" {
  description = "Optional allowlist CIDRs."
  type        = list(string)
  default     = []
}

variable "allowlist_security_group_ids" {
  description = "Optional allowlist security groups."
  type        = list(string)
  default     = []
}

