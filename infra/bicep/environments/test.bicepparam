using '../main.bicep'
param environment = 'test'
param location = 'westus3'
param regionCode = 'wus3'
param uniqueSuffix = 'replace1234'
param entraAdminObjectId = '00000000-0000-0000-0000-000000000000'
param entraAdminName = 'github-oidc-sqldemo-test'
param tenantId = '00000000-0000-0000-0000-000000000000'
param privateEndpointEnabled = false
param keyVaultEnabled = false
