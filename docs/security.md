# Security design

## Why OIDC

GitHub exchanges a signed, job-scoped identity token for a short-lived Azure token. There is no client secret to store, rotate, leak in logs, or exfiltrate from a fork. Environment-specific federated subjects and GitHub protection rules bind trust to a narrow deployment context.

## Least privilege

Separate identities:

1. **Provisioner**: temporary Contributor (or a tailored infrastructure role) at the target subscription/resource-group scope, used by an operator only.
2. **Database deployer**: SQL contained user/administrator plus a narrow ARM role for ephemeral firewall rules.

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
* No permanent firewall rules; public mode is time-bound `/32`.
* `id-token: write` exists only in deployment jobs; PR workflow is read-only.
* Deployment concurrency prevents overlapping environment mutations.
* SqlPackage blocks possible data loss in test/prod and never drops objects absent from source.
* Key Vault is optional, RBAC-based, purge-protected, and contains no pipeline credential.
* Artifacts may expose schema names and deployment intent. Limit repository access and retention.

## Residual risks

Abrupt runner termination can bypass cleanup. Alert on `gh-*` firewall rules older than the expected deployment duration and run a scheduled cleanup under change control. A compromised main branch can alter database schema; enforce protected branches, pinned actions, CODEOWNERS, and environment approvals. Major-tag actions are retained only where an immutable SHA was not confidently known and are monitored by Dependabot.
