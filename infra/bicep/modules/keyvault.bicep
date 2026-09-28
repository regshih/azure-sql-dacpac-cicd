@description('Azure region.')
param location string
@description('Environment name.')
param environment string
@description('Key Vault name.')
param keyVaultName string
@description('Microsoft Entra tenant ID.')
param tenantId string
@description('Key Vault public network access state.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: publicNetworkAccess == 'Disabled' ? 'Deny' : 'Allow'
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
  }
  tags: {
    environment: environment
    workload: 'sqldemo'
    'managed-by': 'bicep'
  }
}

output keyVaultName string = vault.name
