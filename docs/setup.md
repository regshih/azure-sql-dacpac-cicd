# Setup

## 1. Create environment-specific OIDC applications

Use one app/service principal per environment. Replace placeholders and repeat for `dev`, `test`, and `prod`.

```bash
az ad app create --display-name github-sqldemo-dev
az ad sp create --id <APP_CLIENT_ID>
az ad app federated-credential create --id <APP_CLIENT_ID> --parameters '{
  "name":"github-environment-dev",
  "issuer":"https://token.actions.githubusercontent.com",
  "subject":"repo:YOUR_ORG/YOUR_REPO:environment:dev",
  "audiences":["api://AzureADTokenExchange"]
}'
```

Exact subjects:

* `repo:YOUR_ORG/YOUR_REPO:environment:dev`
* `repo:YOUR_ORG/YOUR_REPO:environment:test`
* `repo:YOUR_ORG/YOUR_REPO:environment:prod`

Organizations can customize GitHub OIDC claims to use immutable owner and
repository IDs. In that case, create the credential with the exact subject
reported by `azure/login`, for example:

`repo:YOUR_ORG@OWNER_ID/YOUR_REPO@REPOSITORY_ID:environment:dev`

Use `gh api users/YOUR_ORG --jq .id` and
`gh api repos/YOUR_ORG/YOUR_REPO --jq .id` to retrieve those IDs.

Do not create client secrets. Record the application (client), tenant, subscription, and service-principal object IDs as non-secret identifiers.

## 2. Provision infrastructure manually

Review `docs/plan.md` and `.azure/infrastructure-plan.json`, replace placeholders, run a what-if/plan, then apply **either** Bicep or Terraform.

```bash
az deployment sub what-if --location eastus2 --template-file infra/bicep/main.bicep --parameters infra/bicep/environments/dev.bicepparam
terraform -chdir=infra/terraform init
terraform -chdir=infra/terraform plan -var-file=environments/dev.tfvars
```

The Entra administrator object ID/name in the parameters should be that environment's OIDC service principal. Use a separately controlled provisioning identity; do not grant infrastructure Contributor to the deployment identity.

## 3. Provision and register the private runner

Deploy each SQL environment with private networking enabled, then populate
`infra/bicep/environments/runner.bicepparam` with the three SQL server resource
IDs and an SSH public key:

```bash
az deployment sub what-if --location westus3 --template-file infra/bicep/runner.bicep --parameters infra/bicep/environments/runner.bicepparam
az deployment sub create --location westus3 --template-file infra/bicep/runner.bicep --parameters infra/bicep/environments/runner.bicepparam
```

Create a repository self-hosted runner registration token in GitHub, configure
the VM runner with labels `self-hosted`, `linux`, `x64`, and
`azure-sql-private`, and install it as a service under a non-root account.
The runner template preinstalls PowerShell and the .NET 8 SDK required by the
deployment scripts.
Registration tokens are short-lived credentials: pass one only at execution
time, never write it to source, parameters, cloud-init, or logs. Verify that
all SQL hostnames resolve to private addresses and TCP 1433 is reachable before
enabling deployments.

The deployment identity needs SQL data-plane authorization but no ARM write
permission in private mode.

## 4. Bootstrap SQL authorization

Because the OIDC principal is configured as the server's Entra administrator, it can publish the initial DACPAC. For separation of duties later, connect as the Entra administrator and create a contained user for a distinct deployment identity:

```sql
CREATE USER [github-sqldemo-dev-deployer] FROM EXTERNAL PROVIDER;
ALTER ROLE [db_ddladmin] ADD MEMBER [github-sqldemo-dev-deployer];
GRANT CONNECT TO [github-sqldemo-dev-deployer];
```

Test thoroughly before replacing the configured administrator. Avoid `db_owner`. Microsoft Graph directory permissions may be needed by Azure SQL to resolve service principal display names; follow the Azure SQL service-principal documentation and grant the logical server identity only the minimum directory read capability.

## 5. Configure GitHub Environments

Create `dev`, `test`, and `prod`, then add these **environment variables** (not secrets):

* `AZURE_CLIENT_ID`
* `AZURE_TENANT_ID`
* `AZURE_SUBSCRIPTION_ID`
* `AZURE_RESOURCE_GROUP`
* `AZURE_SQL_SERVER` (name only)
* `AZURE_SQL_DATABASE`

After all three environments are configured, create the repository variable
`AZURE_CONFIGURED` with the value `true`. Deployment jobs remain safely skipped
while this variable is absent or set to `false`.

Restrict deployment branches to `main`. Require reviewers for test and prod; prevent self-review for prod, set a wait timer if required, and limit prod administrators.

## 6. Repository controls

Protect `main`: require PRs, one or more reviews, CODEOWNERS review, `PR validation`, conversation resolution, signed commits where available, and no force pushes. Enable secret scanning, push protection, Dependabot alerts/updates, code scanning, and Actions policies that permit only trusted actions. Replace placeholder CODEOWNERS.
