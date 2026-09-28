@description('Azure region.')
param location string
@description('Environment name.')
param environment string
@description('SQL logical server name.')
param sqlServerName string
@description('SQL database name.')
param databaseName string
@description('Microsoft Entra administrator object ID.')
param entraAdminObjectId string
@description('Microsoft Entra administrator display name.')
param entraAdminName string
@description('Microsoft Entra tenant ID.')
param tenantId string
@description('SQL public network access state.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string
@description('Database SKU name.')
param databaseSkuName string
@description('Database SKU tier.')
param databaseSkuTier string
@description('Grant the deployment principal permission to manage temporary firewall rules.')
param firewallManagerEnabled bool
@description('Resource ID of the custom firewall manager role definition.')
param firewallManagerRoleDefinitionId string

resource server 'Microsoft.Sql/servers@2023-08-01' = {
  name: sqlServerName
  location: location
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: entraAdminName
      principalType: 'Application'
      sid: entraAdminObjectId
      tenantId: tenantId
    }
    minimalTlsVersion: '1.2'
    publicNetworkAccess: publicNetworkAccess
    restrictOutboundNetworkAccess: publicNetworkAccess == 'Disabled' ? 'Enabled' : 'Disabled'
    version: '12.0'
  }
  tags: {
    environment: environment
    workload: 'sqldemo'
    'managed-by': 'bicep'
  }
}

resource database 'Microsoft.Sql/servers/databases@2023-08-01' = {
  parent: server
  name: databaseName
  location: location
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
  }
  properties: {
    catalogCollation: 'DATABASE_DEFAULT'
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    requestedBackupStorageRedundancy: 'Local'
  }
  tags: {
    environment: environment
    workload: 'sqldemo'
    'managed-by': 'bicep'
  }
}

resource firewallManagerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (firewallManagerEnabled) {
  name: guid(server.id, entraAdminObjectId, firewallManagerRoleDefinitionId)
  scope: server
  properties: {
    principalId: entraAdminObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: firewallManagerRoleDefinitionId
  }
}

output sqlServerId string = server.id
output sqlServerName string = server.name
output databaseName string = database.name
