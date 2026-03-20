terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

    random = {
      source = "hashicorp/random"
    }

    rediscloud = {
      source = "RedisLabs/rediscloud"
    }
  }
}

locals {
  role_name = element(reverse(split("/", var.application_role_arn)), 0)

  generated_acl_user_password = try(
    "${random_string.acl_user_upper[0].result}${random_string.acl_user_lower[0].result}${random_string.acl_user_numeric[0].result}!${random_string.acl_user_mixed[0].result}",
    null
  )

  acl_user_password = coalesce(var.acl_user_password_override, local.generated_acl_user_password)

  preferred_endpoint = try(compact([
    var.database_private_endpoint,
    var.database_public_endpoint
  ])[0], null)

  secret_payload = jsonencode({
    subscription_id  = var.subscription_id
    database_id      = var.database_id
    database_name    = var.database_name
    endpoint         = local.preferred_endpoint
    private_endpoint = var.database_private_endpoint
    public_endpoint  = var.database_public_endpoint
    username         = rediscloud_acl_user.this.name
    password         = local.acl_user_password
    tls_enabled      = true
  })
}

resource "random_string" "acl_user_upper" {
  count = var.acl_user_password_override == null ? 1 : 0

  length  = 4
  upper   = true
  lower   = false
  numeric = false
  special = false
}

resource "random_string" "acl_user_lower" {
  count = var.acl_user_password_override == null ? 1 : 0

  length  = 6
  upper   = false
  lower   = true
  numeric = false
  special = false
}

resource "random_string" "acl_user_numeric" {
  count = var.acl_user_password_override == null ? 1 : 0

  length  = 4
  upper   = false
  lower   = false
  numeric = true
  special = false
}

resource "random_string" "acl_user_mixed" {
  count = var.acl_user_password_override == null ? 1 : 0

  length  = 12
  upper   = true
  lower   = true
  numeric = true
  special = false
}

resource "rediscloud_acl_rule" "this" {
  name = var.acl_rule_name
  rule = var.acl_rule_string
}

resource "rediscloud_acl_role" "this" {
  name = var.acl_role_name

  rule {
    name = rediscloud_acl_rule.this.name

    database {
      subscription = var.subscription_id
      database     = var.database_id
    }
  }
}

resource "rediscloud_acl_user" "this" {
  name     = var.acl_user_name
  role     = rediscloud_acl_role.this.name
  password = local.acl_user_password
}

resource "aws_secretsmanager_secret" "this" {
  name                    = var.secret_name
  recovery_window_in_days = var.secret_recovery_window_in_days
  description             = "Redis Cloud connection details for ${var.database_name}"
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = local.secret_payload
}

data "aws_iam_policy_document" "secret_access" {
  statement {
    sid    = "ReadRedisCloudSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.this.arn
    ]
  }
}

resource "aws_iam_policy" "secret_access" {
  name        = "redis-secret-${substr(sha1(var.secret_name), 0, 12)}"
  description = "Read access to ${var.secret_name}"
  policy      = data.aws_iam_policy_document.secret_access.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "secret_access" {
  role       = local.role_name
  policy_arn = aws_iam_policy.secret_access.arn
}
