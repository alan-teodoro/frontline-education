output "subscription_name" {
  description = "Derived Redis Cloud subscription name."
  value = join("-", compact([
    "sub",
    "fle",
    local.normalize.subscription_family
  ]))
}

output "database_name" {
  description = "Derived Redis Cloud database name."
  value       = local.database_name
}

output "acl_rule_name" {
  description = "Derived ACL rule name."
  value = join("-", compact([
    "acl",
    local.normalize.subscription_family,
    local.normalize.app_name,
    local.normalize.purpose
  ]))
}

output "acl_role_name" {
  description = "Derived ACL role name."
  value = join("-", compact([
    "role",
    local.normalize.subscription_family,
    local.normalize.app_name,
    local.normalize.purpose
  ]))
}

output "acl_user_name" {
  description = "Derived ACL user name."
  value = join("-", compact([
    "svc",
    local.normalize.subscription_family,
    local.normalize.app_name,
    local.normalize.purpose
  ]))
}

output "secret_name" {
  description = "Derived AWS Secrets Manager secret name."
  value = join("/", compact([
    local.normalize.secret_prefix,
    local.normalize.environment,
    local.normalize.subscription_family,
    local.normalize.app_name,
    local.normalize.purpose
  ]))
}
