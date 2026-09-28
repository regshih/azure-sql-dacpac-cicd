# Architecture

The DACPAC is the immutable database schema delivery unit. PR validation runs deterministic compilation and SQL linting. Deployment workflows rebuild the exact selected commit, authenticate to Azure with a short-lived GitHub OIDC token, obtain an Azure SQL access token, and call SqlPackage.

## Network modes

### Public endpoint (default POC)

Azure SQL public network access is enabled, but IaC creates **no firewall rules**. Each deployment resolves the current GitHub-hosted runner's public address, creates a uniquely named `/32` rule, and deletes it in an `always()` cleanup step. Concurrent deployments are serialized per environment. A cancelled job can leave a rule behind; monitor and remove rules prefixed `gh-`.

### Private endpoint

Setting `privateEndpointEnabled`/`private_endpoint_enabled` creates a VNet, dedicated subnet, SQL private endpoint, `privatelink.database.windows.net` zone, and VNet link, while disabling public access. GitHub-hosted runners cannot reach the endpoint. Change `runs-on` to approved self-hosted runner labels with VNet connectivity and verify private DNS before deployment.

## Boundaries and availability

Each environment has its own resource group, logical server, database, OIDC identity, and GitHub Environment. The POC defaults to Basic/2 GB. Production examples use General Purpose serverless but do not provide multi-region failover or zone redundancy; those require workload-specific RTO/RPO and regional SKU validation.

## Data model

Customers place Orders; Orders contain OrderItems linked to Products. Constraints enforce identifiers, valid states, positive quantities, nonnegative prices, uniqueness, and referential integrity. Covering indexes support customer order history and product usage. `vw_OrderSummary` aggregates order totals; `usp_GetCustomerOrders` exposes a bounded, parameterized query surface.
