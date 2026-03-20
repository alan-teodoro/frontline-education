# Naming Convention

## General rules

- Use lowercase only.
- Use `a-z`, `0-9`, and `-`.
- Keep names human-readable and sortable.
- Use `svc-` for service accounts so they cannot be confused with human admin users such as `ADMjdoe`.

## Object patterns

### Redis Cloud subscriptions

Pattern:

```text
sub-fle-<subscription_family>
```

Segments:

- `sub`: resource type prefix.
- `fle`: fixed Frontline Education short code.
- `<subscription_family>`: shared platform, pillar, or app family.

Examples:

- `sub-fle-student-solutions`
- `sub-fle-business-systems`
- `sub-fle-shared`

### Redis Cloud databases

Pattern:

```text
<app>-<purpose>
```

Segments:

- `<app>`: application identifier.
- `<purpose>`: workload purpose such as `session`, `cache`, or `reporting`.

Examples:

- `student-sessions-session`
- `student-sessions-cache`
- `business-reporting-cache`
- `student-profile-session`

### Redis users

Pattern:

```text
svc-<subscription_family>-<app>-<purpose>
```

Segments:

- `svc`: service account prefix.
- `<subscription_family>`: prevents cross-subscription naming collisions.
- `<app>`: application name.
- `<purpose>`: database purpose.

Examples:

- `svc-student-solutions-student-sessions-session`
- `svc-student-solutions-student-sessions-cache`
- `svc-business-systems-reporting-cache`
- `svc-shared-student-profile-session`

Human admin example for contrast:

- `ADMjdoe`

### Redis ACL roles

Pattern:

```text
role-<subscription_family>-<app>-<purpose>
```

Examples:

- `role-student-solutions-student-sessions-session`
- `role-student-solutions-student-sessions-cache`
- `role-business-systems-reporting-cache`

### Redis ACL rules

Pattern:

```text
acl-<subscription_family>-<app>-<purpose>
```

Examples:

- `acl-student-solutions-student-sessions-session`
- `acl-student-solutions-student-sessions-cache`
- `acl-business-systems-reporting-cache`

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

- `environment`: `dev | qa | stage | prod` for state keys, secret paths, tags, and approval routing
- `subscription_family`: workload family or platform slice
- `app_name`: application identifier
- `purpose`: database purpose
- `tier`: `s | m | l | xl` for provisioning only
