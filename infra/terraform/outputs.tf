output "resource_group_name" {
  value = azurerm_resource_group.this.name
}
output "sql_server_name" {
  value = module.sql.sql_server_name
}
output "database_name" {
  value = module.sql.database_name
}
output "key_vault_name" {
  value = var.key_vault_enabled ? module.key_vault[0].name : null
}
