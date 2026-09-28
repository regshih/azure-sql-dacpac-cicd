targetScope = 'subscription'

@description('Azure region for the private runner network and VM.')
param location string = 'westus3'

@description('Short region code used in resource names.')
param regionCode string = 'wus3'

@description('Globally unique lowercase suffix.')
@minLength(4)
@maxLength(12)
param uniqueSuffix string

@description('Linux administrator username.')
param adminUsername string = 'ghrunner'

@description('SSH public key used only for emergency access through Azure Run Command.')
@secure()
param adminSshPublicKey string

@description('Resource IDs of Azure SQL logical servers requiring private connectivity.')
param sqlServerIds array

@description('Runner VM size. Standard_D2ls_v6 is the smallest supported SKU in this subscription.')
param vmSize string = 'Standard_D2ls_v6'

var resourceGroupName = 'rg-sqldemo-runner-${regionCode}'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    environment: 'shared'
    workload: 'sqldemo'
    'managed-by': 'bicep'
  }
}

module runner 'modules/private-runner.bicep' = {
  name: 'private-runner'
  scope: rg
  params: {
    location: location
    regionCode: regionCode
    uniqueSuffix: uniqueSuffix
    adminUsername: adminUsername
    adminSshPublicKey: adminSshPublicKey
    sqlServerIds: sqlServerIds
    vmSize: vmSize
  }
}

output resourceGroupName string = rg.name
output vmName string = runner.outputs.vmName
output privateEndpointNames array = runner.outputs.privateEndpointNames
