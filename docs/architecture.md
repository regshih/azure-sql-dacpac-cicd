# Architecture

The DACPAC is the immutable database schema delivery unit. PR validation runs deterministic compilation and SQL linting. Deployment workflows rebuild the exact selected commit, authenticate to Azure with a short-lived GitHub OIDC token, obtain an Azure SQL access token, and call SqlPackage.

## Network architecture

The deployment workflows target a self-hosted Linux runner labeled
`azure-sql-private`. The included Bicep runner template creates a dedicated
VNet, runner subnet, private-endpoint subnet, NAT Gateway, private DNS zone,
and one private endpoint per SQL logical server. The VM has no public IP and
the NSG has no inbound rules. NAT permits outbound access to GitHub and package
registries.

Azure SQL public network access is disabled. From the runner,
`<server>.database.windows.net` resolves through
`privatelink.database.windows.net` to a private address. SqlPackage connects
over TCP 1433 using an Entra access token.

The environment IaC retains an optional public mode for adopters that cannot
operate a private runner. Using it requires a deliberate workflow change and
time-bound firewall controls; it is not the workflow default in this repository.

## Boundaries and availability

Each environment has its own resource group, logical server, database, OIDC identity, and GitHub Environment. The POC defaults to Basic/2 GB. Production examples use General Purpose serverless but do not provide multi-region failover or zone redundancy; those require workload-specific RTO/RPO and regional SKU validation.

## Data model

Customers place Orders; Orders contain OrderItems linked to Products. Constraints enforce identifiers, valid states, positive quantities, nonnegative prices, uniqueness, and referential integrity. Covering indexes support customer order history and product usage. `vw_OrderSummary` aggregates order totals; `usp_GetCustomerOrders` exposes a bounded, parameterized query surface.
