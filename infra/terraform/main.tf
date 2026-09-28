locals {
  resource_group_name = "rg-sqldemo-${var.environment}-${var.region_code}"
  sql_server_name     = "sql-sqldemo-${var.environment}-${var.unique_suffix}"
  database_name       = "sqldb-sqldemo-${var.environment}"
  common_tags = {
    environment  = var.environment
    workload     = "sqldemo"
    "managed-by" = "terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "sql" {
  source = "./modules/sql"

  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  sql_server_name        = local.sql_server_name
  database_name          = local.database_name
  tenant_id              = var.tenant_id
  entra_admin_object_id  = var.entra_admin_object_id
  entra_admin_name       = var.entra_admin_name
  public_network_enabled = !var.private_endpoint_enabled
  database_sku_name      = var.database_sku_name
  database_max_size_gb   = var.database_max_size_gb
  tags                   = local.common_tags
}

module "network" {
  count  = var.private_endpoint_enabled ? 1 : 0
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  environment         = var.environment
  region_code         = var.region_code
  unique_suffix       = var.unique_suffix
  sql_server_id       = module.sql.sql_server_id
  tags                = local.common_tags
}

module "key_vault" {
  count  = var.key_vault_enabled ? 1 : 0
  source = "./modules/keyvault"

  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  name                          = "kv-sqldemo-${var.environment}-${var.unique_suffix}"
  tenant_id                     = var.tenant_id
  public_network_access_enabled = !var.private_endpoint_enabled
  tags                          = local.common_tags
}
