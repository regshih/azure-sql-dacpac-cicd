targetScope = 'subscription'

@description('Deployment environment.')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Azure region.')
param location string = 'eastus2'

@description('Short region code used in names.')
param regionCode string = 'eus2'

@description('Globally unique suffix using lowercase letters and digits.')
@minLength(4)
@maxLength(12)
param uniqueSuffix string

@description('Object ID of the Microsoft Entra principal used as SQL administrator.')
param entraAdminObjectId string

@description('Display name of the Microsoft Entra principal used as SQL administrator.')
param entraAdminName string

@description('Microsoft Entra tenant ID.')
param tenantId string

@description('Create private networking and disable SQL public network access.')
param privateEndpointEnabled bool = false

@description('Create an optional Key Vault.')
param keyVaultEnabled bool = false

@description('Azure SQL Database SKU name.')
param databaseSkuName string = 'Basic'

@description('Azure SQL Database SKU tier.')
param databaseSkuTier string = 'Basic'

var resourceGroupName = 'rg-sqldemo-${environment}-${regionCode}'
var sqlServerName = 'sql-sqldemo-${environment}-${uniqueSuffix}'
var databaseName = 'sqldb-sqldemo-${environment}'
var keyVaultName = 'kv-sqldemo-${environment}-${uniqueSuffix}'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    environment: environment
    workload: 'sqldemo'
    'managed-by': 'bicep'
  }
}

module sql 'modules/sql.bicep' = {
  name: 'sql-${environment}'
  scope: rg
  params: {
    location: location
    environment: environment
    sqlServerName: sqlServerName
    databaseName: databaseName
    entraAdminObjectId: entraAdminObjectId
    entraAdminName: entraAdminName
    tenantId: tenantId
    publicNetworkAccess: privateEndpointEnabled ? 'Disabled' : 'Enabled'
    databaseSkuName: databaseSkuName
    databaseSkuTier: databaseSkuTier
  }
}

module network 'modules/network.bicep' = if (privateEndpointEnabled) {
  name: 'network-${environment}'
  scope: rg
  params: {
    location: location
    environment: environment
    regionCode: regionCode
    sqlServerId: sql.outputs.sqlServerId
    uniqueSuffix: uniqueSuffix
  }
}

module vault 'modules/keyvault.bicep' = if (keyVaultEnabled) {
  name: 'vault-${environment}'
  scope: rg
  params: {
    location: location
    environment: environment
    keyVaultName: keyVaultName
    tenantId: tenantId
    publicNetworkAccess: privateEndpointEnabled ? 'Disabled' : 'Enabled'
  }
}

output resourceGroupName string = rg.name
output sqlServerName string = sql.outputs.sqlServerName
output databaseName string = sql.outputs.databaseName
output keyVaultName string = keyVaultEnabled ? vault!.outputs.keyVaultName : ''
