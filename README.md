# Azure SQL DACPAC CI/CD proof of concept

Enterprise-oriented reference repository for building, validating, and promoting a SQL project to Azure SQL Database without passwords or public database access. It contains equivalent Bicep and Terraform implementations; **nothing in this repository deploys infrastructure automatically**.

## Architecture

```mermaid
flowchart LR
  PR[Pull request] --> CI[Lint + build DACPAC]
  CI --> A[(Immutable artifact)]
  MAIN[Push to main] --> DEV[GitHub environment: dev]
  DEV --> TEST[GitHub environment: test]
  DISPATCH[Manual dispatch] --> PROD[GitHub environment: prod]
  DEV & TEST & PROD --> OIDC[GitHub OIDC]
  OIDC --> ARM[Azure Resource Manager]
  DEV & TEST & PROD --> RUNNER[Private self-hosted runner]
  RUNNER --> DNS[Private DNS]
  DNS --> PE[SQL private endpoints]
  PE --> SQL[(Azure SQL Database)]
  DEV & TEST & PROD --> PKG[SqlPackage + Entra access token]
  PKG --> SQL
```

The included runner template uses NAT for outbound GitHub access and has no public IP or inbound NSG rules.

## Repository map

| Path | Purpose |
|---|---|
| `database/` | SDK-style Microsoft.Build.Sql project and database objects |
| `scripts/` | Build, SQL policy/lint, and token-based SqlPackage deployment |
| `.github/workflows/` | PR validation and dev/test/prod promotion |
| `infra/bicep/` | Subscription-scope Bicep and environment parameters |
| `infra/terraform/` | Equivalent modular Terraform and environment tfvars |
| `.azure/` | Approved design record; not deployment state |
| `docs/` | Setup, architecture, security, planning, and troubleshooting |

## Quick start

```powershell
pwsh ./scripts/Test-Sql.ps1
pwsh ./scripts/Build-Dacpac.ps1
az bicep build --file ./infra/bicep/main.bicep
terraform -chdir=./infra/terraform init -backend=false
terraform -chdir=./infra/terraform validate
```

Replace every `YOUR_*`, all-zero GUID, and `replace1234` placeholder before use. Follow [setup](docs/setup.md), then choose **one** IaC implementation. Do not apply both to the same environment.

## Promotion behavior

* Pull requests lint and build but cannot request an Azure token.
* After setup sets the repository variable `AZURE_CONFIGURED=true`, a push to `main` deploys dev automatically. Unconfigured forks safely skip deployment.
* A successful dev workflow triggers test, whose GitHub Environment can require approval.
* Production is manual and protected by the `prod` Environment.
* Every deployment runs on the labeled private runner, rebuilds the selected commit, generates a report and SQL script, publishes with an Entra token, and uploads evidence even on failure.

> Screenshot placeholder: GitHub Environments protection rules (`docs/images/github-environments.png`)
>
> Screenshot placeholder: successful dev → test workflow promotion (`docs/images/workflow-promotion.png`)
>
> Screenshot placeholder: Azure SQL networking blade with public access disabled (`docs/images/sql-networking.png`)

## Safety

The parameter examples are non-runnable placeholders. Infrastructure deployment is intentionally absent from GitHub workflows. Review generated deployment scripts before production approval. See [SECURITY.md](SECURITY.md).
