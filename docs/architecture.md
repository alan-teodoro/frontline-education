# Architecture Notes

## Goal

Provide a self-service Terraform foundation for Redis Cloud Pro on AWS where an internal request can eventually trigger:

1. Subscription discovery or creation.
2. Database discovery or creation.
3. ACL user and role provisioning.
4. Secret generation in AWS Secrets Manager.
5. IAM access grants for the application role.

## State boundaries

The repository uses two Terraform root stacks:

- `stacks/subscription`
- `stacks/database`

This is intentional.

### Subscription stack ownership

The subscription stack owns:

- one `rediscloud_subscription`

It does not own any databases.

The stack supports both `managed` and `byoc` deployment models. The repository baseline is `managed` for the customer, while BYOC can be enabled through explicit overrides for local testing.

### Database stack ownership

The database stack owns:

- one `rediscloud_subscription_database`
- one ACL rule
- one ACL role
- one ACL user
- one AWS Secrets Manager secret and secret value
- one AWS IAM policy plus attachment to the target application role

This allows one subscription to host many databases, each with isolated state and lifecycle.

## Why the workflow should not infer subscription sizing from a database ticket

Redis Cloud Pro subscriptions require a `creation_plan` during provisioning. That plan is used only when the subscription is created and should represent the expected subscription envelope, not the first database request.

Because of that, this repository uses `subscription_profiles` in [`config/catalog.yaml`](/Users/alan/workspaces/alan-teodoro/frontline-education/config/catalog.yaml) to define:

- the maximum expected t-shirt size for the subscription
- the base memory storage choice

This keeps shared subscriptions stable and predictable.

To keep the customer-facing behaviour simple, the repository always uses `creation_plan.quantity = 1` when creating a subscription.

## GitHub Actions orchestration

The repository now implements a controller-style GitHub Actions workflow instead of trying to let plain Terraform discover everything by itself.

### Step 1: receive a request payload

Suggested request inputs:

- `environment`
- `subscription_family`
- `app_name`
- `purpose`
- `tier`
- `persistence_mode`
- `data_eviction`
- `application_role_arn`

Suggested destroy inputs:

- `environment`
- `subscription_family`
- `database_name`
- `destroy_subscription_if_empty`

### Step 2: resolve internal defaults

Read the repository catalog to obtain:

- Redis Cloud cloud account name
- Redis Cloud environment target account model
- AWS region
- deployment CIDR
- subscription profile
- size profile
- maintenance windows

### Step 3: check whether the subscription exists

Use the Redis Cloud API or Terraform data lookup logic to determine whether the derived subscription name already exists.

- If it does not exist: run `stacks/subscription`.
- If it exists but is unmanaged in Terraform state: import it into the subscription state, then apply.

Recommended backend key pattern:

- `subscriptions/<environment>/<subscription_family>`

### Step 4: check whether the database exists

Look for the database inside the target subscription.

- If it does not exist: run `stacks/database`.
- If it exists but is unmanaged in Terraform state: import it into the database state, then apply.

Recommended backend key pattern:

- `databases/<environment>/<subscription_family>/<database_name>.tfstate`

## Implemented workflow behaviour

The repository now uses two request-driven workflows:

- [`rediscloud-apply.yml`](/Users/alan/workspaces/alan-teodoro/frontline-education/.github/workflows/rediscloud-apply.yml)
- [`rediscloud-destroy.yml`](/Users/alan/workspaces/alan-teodoro/frontline-education/.github/workflows/rediscloud-destroy.yml)

The workflow selects Redis Cloud credentials by environment. This is important because the customer may use a different Redis Cloud account for `dev`, `qa`, `stage`, and `prod`, even if the Terraform structure and naming rules stay the same.

### Apply path

1. Resolve the request into deterministic names and backend keys.
2. Query Redis Cloud to detect whether the subscription already exists.
3. Query Redis Cloud to detect whether the database already exists.
4. Run a Terraform plan for the subscription stack.
5. Run a Terraform plan for the database stack only when the subscription already exists.
6. Pause at the GitHub environment approval gate for the target environment.
7. Import the existing subscription into state when needed.
8. Apply the subscription stack.
9. Refresh discovery data.
10. Import the existing database into state when needed.
11. Apply the database stack.

### Destroy path

1. Receive a reduced destroy request with `environment`, `subscription_family`, and the exact `database_name`.
2. Resolve the subscription name and backend keys.
3. Query Redis Cloud to detect whether the database and subscription already exist.
4. Pause at the GitHub environment approval gate for the target environment.
5. Import the database into state when needed.
6. Destroy the database stack.
7. Optionally destroy the subscription only when it is empty.

## Import strategy

Terraform must import existing resources before it can update them.

### Subscription import

```bash
terraform import rediscloud_subscription.this <subscription_id>
```

### Database import

```bash
terraform import rediscloud_subscription_database.this <subscription_id>/<database_id>
```

### ACL and secret resources

The ACL rule, ACL role, ACL user, AWS secret, and IAM policy are all deterministic from naming inputs. If those already exist outside Terraform, they should also be imported before the first managed apply.

The repository now assumes a single default ACL profile for the bootstrap application user: read and write access. If the customer wants additional users or narrower privileges later, they can create them after the initial database provisioning flow.

## Approval model for environments

Recommended GitHub Actions policy:

- `dev`: plan and apply automatically.
- `qa`: optional approval depending on Frontline preference.
- `stage`: require manual approval after plan.
- `prod`: require manual approval after plan.
- `destroy` in any environment: require manual approval through dedicated destroy environments.

Use protected environments in GitHub Actions so the plan is visible before approval.

The one nuance is first-time provisioning of a brand-new subscription. In that case, the subscription plan can be shown before approval, but the final Terraform plan for the database stack only becomes possible after the subscription exists. The workflow handles that by producing the subscription plan first and then planning and applying the database in the gated apply job.

## Deletion model

Deletion should be explicit and state-driven:

- Destroying a database stack removes only the database-level resources.
- Destroying a subscription stack should be blocked operationally unless no managed databases remain in that subscription.
