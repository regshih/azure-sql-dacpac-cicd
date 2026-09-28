# Security design

## Why OIDC

GitHub exchanges a signed, job-scoped identity token for a short-lived Azure token. There is no client secret to store, rotate, leak in logs, or exfiltrate from a fork. Environment-specific federated subjects and GitHub protection rules bind trust to a narrow deployment context.

## Least privilege

Separate identities:

1. **Provisioner**: temporary Contributor (or a tailored infrastructure role) at the target subscription/resource-group scope, used by an operator only.
2. **Database deployer**: SQL contained user/administrator authenticated through OIDC. Private mode requires no ARM write role.

Illustrative public-mode custom role actions:

```json
{
  "Name": "SqlDacpacEphemeralFirewallOperator",
  "IsCustom": true,
  "Actions": [
    "Microsoft.Sql/servers/read",
    "Microsoft.Sql/servers/databases/read",
    "Microsoft.Sql/servers/firewallRules/read",
    "Microsoft.Sql/servers/firewallRules/write",
    "Microsoft.Sql/servers/firewallRules/delete"
  ],
  "NotActions": [],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": ["/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.Sql/servers/<SERVER>"]
}
```

Validate custom-role assignable scopes in your tenant; some organizations use resource-group scope for role definitions and server scope for assignments. Private mode needs only `read`, or no ARM role after connection values are stored as GitHub variables.

## Controls

* Entra-only SQL authentication; no SQL passwords or connection-string secrets.
* TLS 1.2 minimum and certificate validation.
* SQL public network access is disabled; deployments traverse private endpoints.
* The runner VM has no public IP or inbound NSG rules and uses NAT for outbound access.
* `id-token: write` exists only in deployment jobs; PR workflow is read-only.
* Deployment concurrency prevents overlapping environment mutations.
* SqlPackage blocks possible data loss in test/prod and never drops objects absent from source.
* Key Vault is optional, RBAC-based, purge-protected, and contains no pipeline credential.
* Artifacts may expose schema names and deployment intent. Limit repository access and retention.

## Residual risks

The persistent runner requires OS and runner patching, monitoring, and prompt
replacement if compromised. Restrict repository access to the runner and avoid
co-hosting unrelated workloads. A compromised main branch can alter database
schema; enforce protected branches, pinned actions, CODEOWNERS, and environment
approvals. Major-tag actions are retained only where an immutable SHA was not
confidently known and are monitored by Dependabot.
