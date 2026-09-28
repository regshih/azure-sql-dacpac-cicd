resource "azurerm_mssql_server" "this" {
  name                                 = var.sql_server_name
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  version                              = "12.0"
  minimum_tls_version                  = "1.2"
  public_network_access_enabled        = var.public_network_enabled
  outbound_network_restriction_enabled = true
  tags                                 = var.tags

  azuread_administrator {
    login_username              = var.entra_admin_name
    object_id                   = var.entra_admin_object_id
    tenant_id                   = var.tenant_id
    azuread_authentication_only = true
  }
}

resource "azurerm_mssql_database" "this" {
  name                                = var.database_name
  server_id                           = azurerm_mssql_server.this.id
  sku_name                            = var.database_sku_name
  max_size_gb                         = var.database_max_size_gb
  collation                           = "SQL_Latin1_General_CP1_CI_AS"
  storage_account_type                = "Local"
  transparent_data_encryption_enabled = true
  tags                                = var.tags
}
