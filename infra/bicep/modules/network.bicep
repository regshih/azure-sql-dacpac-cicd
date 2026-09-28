@description('Azure region.')
param location string
@description('Environment name.')
param environment string
@description('Short region code.')
param regionCode string
@description('SQL logical server resource ID.')
param sqlServerId string
@description('Unique naming suffix.')
param uniqueSuffix string

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-sqldemo-${environment}-${regionCode}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.40.0.0/16']
    }
    subnets: [
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: '10.40.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
  tags: {
    environment: environment
    workload: 'sqldemo'
    'managed-by': 'bicep'
  }
}

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: 'snet-private-endpoints'
}

resource dns 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.${az.environment().suffixes.sqlServerHostname}'
  location: 'global'
}

resource dnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dns
  name: 'link-${environment}-${uniqueSuffix}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource endpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-sqldemo-${environment}-${uniqueSuffix}'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'sql'
        properties: {
          groupIds: ['sqlServer']
          privateLinkServiceId: sqlServerId
        }
      }
    ]
    subnet: {
      id: privateEndpointSubnet.id
    }
  }
}

resource zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: endpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'sql'
        properties: {
          privateDnsZoneId: dns.id
        }
      }
    ]
  }
}
