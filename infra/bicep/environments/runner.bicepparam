using '../runner.bicep'

param location = 'westus3'
param regionCode = 'wus3'
param uniqueSuffix = 'replace1234'
param adminUsername = 'ghrunner'
param adminSshPublicKey = 'ssh-ed25519 REPLACE_WITH_PUBLIC_KEY'
param vmSize = 'Standard_D2ls_v6'
param sqlServerIds = [
  '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/REPLACE_DEV_RG/providers/Microsoft.Sql/servers/REPLACE_DEV_SERVER'
  '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/REPLACE_TEST_RG/providers/Microsoft.Sql/servers/REPLACE_TEST_SERVER'
  '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/REPLACE_PROD_RG/providers/Microsoft.Sql/servers/REPLACE_PROD_SERVER'
]
