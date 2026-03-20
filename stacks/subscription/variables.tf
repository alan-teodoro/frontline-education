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
  description = "Subscription family to create."
  type        = string
}

variable "subscription_name_override" {
  description = "Optional explicit subscription name."
  type        = string
  default     = null
}

variable "payment_method" {
  description = "Optional payment method such as marketplace or credit-card."
  type        = string
  default     = null

  validation {
    condition     = var.payment_method == null || contains(["credit-card", "marketplace"], var.payment_method)
    error_message = "payment_method must be null, credit-card, or marketplace."
  }
}

variable "payment_method_id" {
  description = "Optional payment method id when payment_method is credit-card."
  type        = string
  default     = null
}

variable "payment_card_type" {
  description = "Optional credit card type used to look up the payment method automatically."
  type        = string
  default     = null
}

variable "payment_card_last_four" {
  description = "Optional last four digits used to look up the payment method automatically."
  type        = string
  default     = null

  validation {
    condition     = var.payment_card_last_four == null || can(regex("^\\d{4}$", var.payment_card_last_four))
    error_message = "payment_card_last_four must contain exactly 4 digits."
  }
}

variable "max_tier_override" {
  description = "Optional override for the largest expected database tier in the subscription."
  type        = string
  default     = null
}

variable "planned_database_quantity_override" {
  description = "Optional override for the planned number of databases in the subscription."
  type        = number
  default     = null
}
