using '../main.bicep'
param environment = 'dev'
param location = 'eastus2'
param regionCode = 'eus2'
param uniqueSuffix = 'replace1234'
param entraAdminObjectId = '00000000-0000-0000-0000-000000000000'
param entraAdminName = 'github-oidc-sqldemo-dev'
param tenantId = '00000000-0000-0000-0000-000000000000'
param privateEndpointEnabled = false
param keyVaultEnabled = false
