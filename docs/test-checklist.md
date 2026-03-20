# Test Checklist

## Purpose

Use this checklist to validate the Terraform stacks locally before moving to GitHub Actions and customer-facing rollout.

## Subscription scenarios

- [ ] Create a new subscription when it does not exist.
- [ ] Confirm the subscription uses the expected deployment model.
- [ ] Confirm the subscription `creation_plan.quantity` is `1`.
- [ ] Confirm the subscription name matches the naming convention.
- [ ] Confirm the subscription uses the expected Redis Cloud account or BYOC cloud account.
- [ ] Confirm the subscription profile values from `config/catalog.yaml` are applied as expected.

## Database scenarios

- [ ] Create a new database inside an existing subscription.
- [ ] Confirm the database name matches the naming convention.
- [ ] Confirm the selected `tier` is applied correctly.
- [ ] Confirm `persistence_mode` is applied correctly.
- [ ] Confirm `data_eviction` is applied correctly.
- [ ] Confirm the default database user is disabled.
- [ ] Confirm the public endpoint remains disabled.

## Access and security scenarios

- [ ] Confirm the ACL rule is created with the expected name.
- [ ] Confirm the ACL role is created with the expected name.
- [ ] Confirm the ACL user is created with the expected name.
- [ ] Confirm generated credentials are not exposed in plain Terraform outputs.
- [ ] Confirm the AWS Secrets Manager secret is created.
- [ ] Confirm the secret contains endpoint, username, and password.
- [ ] Confirm the expected AWS IAM role can read the secret.
- [ ] Confirm Terraform outputs return the secret name and/or ARN.

## Update and idempotency scenarios

- [ ] Re-run `apply` with no changes and confirm idempotency.
- [ ] Change only `tier` and confirm the update behavior is correct.
- [ ] Change only `persistence_mode` and confirm the update behavior is correct.
- [ ] Change only `data_eviction` and confirm the update behavior is correct.

## Import and adoption scenarios

- [ ] Adopt an existing subscription into Terraform state.
- [ ] Adopt an existing database into Terraform state.
- [ ] Confirm subscription state and database state remain isolated.

## Destroy scenarios

- [ ] Destroy only the database.
- [ ] Confirm the subscription remains when it should.
- [ ] Destroy with `destroy_subscription_if_empty = true`.
- [ ] Confirm the subscription is removed only when empty.

## GitHub Actions scenarios

- [ ] Validate the apply workflow in `dev` with no approval.
- [ ] Validate the apply workflow in `stage` or `prod` with approval.
- [ ] Validate the destroy workflow with approval.
- [ ] Confirm environment-specific Redis Cloud credentials are selected correctly.
- [ ] Confirm the S3 backend state keys match the expected naming pattern.

## Recommended execution order

1. Create the subscription locally.
2. Create the database locally.
3. Validate secret creation and IAM access.
4. Re-run apply and confirm idempotency.
5. Test update scenarios.
6. Test destroy scenarios.
7. Test import and adoption scenarios.
8. Validate GitHub Actions after local success.
