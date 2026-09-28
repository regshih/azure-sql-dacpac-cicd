# Infrastructure plan and decisions

The approved machine-readable plan is `.azure/infrastructure-plan.json`. Generation was explicitly approved; deployment was not and has not been performed.

## Naming rules

| Resource | Pattern | Azure constraint |
|---|---|---|
| Resource group | `rg-sqldemo-<env>-<region>` | 1–90 characters; alphanumerics, `_`, `-`, `.`, `(`, `)`; not ending in `.` |
| SQL server | `sql-sqldemo-<env>-<unique>` | 1–63 lowercase letters, numbers, hyphens; globally unique; not start/end hyphen |
| SQL database | `sqldb-sqldemo-<env>` | 1–128 valid SQL resource-name characters; unique within server |
| Key Vault | `kv-sqldemo-<env>-<unique>` | 3–24 alphanumerics/hyphens; begin with letter, end alphanumeric; globally unique |
| VNet | `vnet-sqldemo-<env>-<region>` | 2–64 characters; resource-group unique |
| Private endpoint | `pe-sqldemo-<env>-<unique>` | 2–64 characters; resource-group unique |

## Alternatives and tradeoffs

* **Basic versus General Purpose:** Basic minimizes POC cost. General Purpose serverless adds autoscaling and stronger production capability but can introduce resume latency. Business Critical improves latency/availability at materially higher cost.
* **Public ephemeral access versus private endpoint:** GitHub-hosted runners are simple and elastic, but the public endpoint exists during deployments. Private mode closes it completely, at the cost of self-hosted runner operations and network/DNS design.
* **Bicep versus Terraform:** Bicep is Azure-native with no external state. Terraform supports a broader ecosystem but production use requires a separately bootstrapped, locked remote state backend. Both variants describe equivalent resources; select one.
* **Single database versus failover group:** This POC omits geo-DR. Add a secondary server/failover group only after defining RTO, RPO, region pairing, and cost.
* **Platform TDE versus customer-managed key:** Azure SQL TDE is on by default. CMK adds control and auditability but requires Key Vault, a server identity, rotation, and recovery procedures.
* **Optional Key Vault:** The passwordless pipeline does not require it. It is included only as a hardened extension point.

## Operational assumptions

`eastus2` and example SKUs are placeholders to validate against policy, quota, data residency, and availability before deployment. Address space `10.40.0.0/16` must be checked for overlap. Tags are environment, workload, and IaC owner. No diagnostic workspace, Defender plan, policy assignment, budget, or alert is provisioned; enterprise landing zones should supply these controls.
