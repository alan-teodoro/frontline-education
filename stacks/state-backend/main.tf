module "state_backend" {
  source = "../../modules/terraform_state_backend"

  bucket_name              = var.bucket_name
  github_actions_role_arns = var.github_actions_role_arns
  allowed_state_prefixes   = var.allowed_state_prefixes
  enable_versioning        = var.enable_versioning
  force_destroy            = var.force_destroy
  kms_key_arn              = var.kms_key_arn
  tags = merge(
    {
      managed_by   = "terraform"
      organization = "frontline-education"
      component    = "terraform-state-backend"
    },
    var.tags
  )
}
