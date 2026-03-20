# Naming Convention

## General rules

- Use lowercase only.
- Use `a-z`, `0-9`, `-`, and `_expireYYYYMMDD` where expiration is needed.
- Keep names human-readable and sortable.
- Use `svc-` for service accounts so they cannot be confused with human admin users such as `ADMjdoe`.

## Object patterns

### Redis Cloud subscriptions

Pattern:

```text
sub-fle-<subscription_family>-<environment>
```

Segments:

- `sub`: resource type prefix.
- `fle`: fixed Frontline Education short code.
- `<subscription_family>`: shared platform, pillar, or app family.
- `<environment>`: one of `dev`, `qa`, `stage`, `prod`.

Examples:

- `sub-fle-student-solutions-dev`
- `sub-fle-business-systems-qa`
- `sub-fle-shared-prod`

### Redis Cloud databases

Pattern:

```text
<app>-<purpose>-<environment>-<tier>[_expireYYYYMMDD]
```

Segments:

- `<app>`: application identifier.
- `<purpose>`: workload purpose such as `session`, `cache`, or `reporting`.
- `<environment>`: `dev`, `qa`, `stage`, `prod`.
- `<tier>`: `s`, `m`, `l`, `xl`.
- `_expireYYYYMMDD`: only for temporary or R&D databases.

Examples:

- `student-sessions-session-dev-s`
- `student-sessions-session-qa-m`
- `student-sessions-session-stage-l`
- `student-sessions-session-prod-xl`
- `student-sessions-cache-dev-s_expire20260430`
- `business-reporting-cache-qa-m_expire20260515`

### Redis users

Pattern:

```text
svc-<subscription_family>-<app>-<purpose>-<environment>-<service_purpose>
```

Segments:

- `svc`: service account prefix.
- `<subscription_family>`: prevents cross-subscription naming collisions.
- `<app>`: application name.
- `<purpose>`: database purpose.
- `<environment>`: `dev`, `qa`, `stage`, `prod`.
- `<service_purpose>`: `app`, `pipeline`, `readonly`, and so on.

Examples:

- `svc-student-solutions-student-sessions-session-dev-app`
- `svc-student-solutions-student-sessions-session-qa-app`
- `svc-student-solutions-student-sessions-session-stage-readonly`
- `svc-business-systems-reporting-cache-prod-app`
- `svc-business-systems-reporting-cache-prod-pipeline`

Human admin example for contrast:

- `ADMjdoe`

### Redis ACL roles

Pattern:

```text
role-<subscription_family>-<app>-<purpose>-<environment>-<service_purpose>-<access_level>
```

Examples:

- `role-student-solutions-student-sessions-session-dev-app-readwrite`
- `role-student-solutions-student-sessions-session-qa-app-readonly`
- `role-business-systems-reporting-cache-prod-ops-ops`

### Redis ACL rules

Pattern:

```text
acl-<subscription_family>-<app>-<purpose>-<environment>-<access_level>
```

Examples:

- `acl-student-solutions-student-sessions-session-dev-readwrite`
- `acl-student-solutions-student-sessions-session-qa-readonly`
- `acl-business-systems-reporting-cache-prod-ops`

### AWS Secrets Manager secrets

Pattern:

```text
<prefix>/<environment>/<subscription_family>/<app>/<purpose>
```

Default prefix:

```text
frontline-education/redis
```

Examples:

- `frontline-education/redis/dev/student-solutions/student-sessions/session`
- `frontline-education/redis/qa/business-systems/reporting/cache`

## Terraform variable mapping

The naming model maps naturally to these variables:

- `environment`: `dev | qa | stage | prod`
- `subscription_family`: workload family or platform slice
- `app_name`: application identifier
- `purpose`: database purpose
- `tier`: `s | m | l | xl`
- `temporary`: `true | false`
- `expiration_date`: `YYYY-MM-DD`
- `service_account_purpose`: `app | pipeline | readonly | ops`
- `access_level`: `readwrite | readonly | ops`
