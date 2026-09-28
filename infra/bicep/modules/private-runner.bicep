@description('Azure region.')
param location string

@description('Short region code.')
param regionCode string

@description('Globally unique lowercase suffix.')
param uniqueSuffix string

@description('Linux administrator username.')
param adminUsername string

@description('SSH public key.')
@secure()
param adminSshPublicKey string

@description('Azure SQL logical server resource IDs.')
param sqlServerIds array

@description('Runner VM size.')
param vmSize string

var vmName = 'vm-sqldemo-ghrunner-${regionCode}'
var cloudInit = '''
#cloud-config
package_update: true
packages:
  - curl
  - git
  - jq
  - libicu-dev
  - python3
  - python3-pip
  - unzip
  - ca-certificates
runcmd:
  - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
  - curl -sSLo /tmp/packages-microsoft-prod.deb https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb
  - dpkg -i /tmp/packages-microsoft-prod.deb
  - apt-get update
  - DEBIAN_FRONTEND=noninteractive apt-get install -y powershell
  - rm -f /tmp/packages-microsoft-prod.deb
'''

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-sqldemo-ghrunner-${regionCode}'
  location: location
  properties: {
    securityRules: []
  }
  tags: {
    environment: 'shared'
    workload: 'sqldemo'
    'managed-by': 'bicep'
  }
}

resource natPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-sqldemo-nat-${regionCode}-${uniqueSuffix}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: {
    environment: 'shared'
    workload: 'sqldemo'
    'managed-by': 'bicep'
  }
}

resource nat 'Microsoft.Network/natGateways@2024-05-01' = {
  name: 'nat-sqldemo-ghrunner-${regionCode}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 10
    publicIpAddresses: [
      {
        id: natPublicIp.id
      }
    ]
  }
  tags: {
    environment: 'shared'
    workload: 'sqldemo'
    'managed-by': 'bicep'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-sqldemo-runner-${regionCode}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.50.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-runner'
        properties: {
          addressPrefix: '10.50.1.0/24'
          natGateway: {
            id: nat.id
          }
          networkSecurityGroup: {
            id: nsg.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: '10.50.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
  tags: {
    environment: 'shared'
    workload: 'sqldemo'
    'managed-by': 'bicep'
  }
}

resource runnerSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: 'snet-runner'
}

resource endpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: 'snet-private-endpoints'
}

resource privateDns 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink${az.environment().suffixes.sqlServerHostname}'
  location: 'global'
}

resource privateDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDns
  name: 'link-runner-${regionCode}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateEndpoints 'Microsoft.Network/privateEndpoints@2024-05-01' = [
  for (sqlServerId, index) in sqlServerIds: {
    name: 'pe-sqldemo-sql-${index + 1}-${uniqueSuffix}'
    location: location
    properties: {
      privateLinkServiceConnections: [
        {
          name: 'sql'
          properties: {
            groupIds: [
              'sqlServer'
            ]
            privateLinkServiceId: sqlServerId
          }
        }
      ]
      subnet: {
        id: endpointSubnet.id
      }
    }
    tags: {
      environment: 'shared'
      workload: 'sqldemo'
      'managed-by': 'bicep'
    }
  }
]

resource dnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = [
  for (sqlServerId, index) in sqlServerIds: {
    parent: privateEndpoints[index]
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'sql'
          properties: {
            privateDnsZoneId: privateDns.id
          }
        }
      ]
    }
  }
]

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${vmName}'
  location: location
  properties: {
    enableAcceleratedNetworking: false
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: runnerSubnet.id
          }
        }
      }
    ]
  }
  tags: {
    environment: 'shared'
    workload: 'sqldemo'
    'managed-by': 'bicep'
  }
}

//checkov:skip=CKV_AZURE_50:The VM has no extension resources; cloud-init installs only required packages.
resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    osProfile: {
      adminUsername: adminUsername
      computerName: vmName
      customData: base64(cloudInit)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        provisionVMAgent: true
        ssh: {
          publicKeys: [
            {
              keyData: adminSshPublicKey
              path: '/home/${adminUsername}/.ssh/authorized_keys'
            }
          ]
        }
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    storageProfile: {
      imageReference: {
        offer: 'ubuntu-24_04-lts'
        publisher: 'Canonical'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
        deleteOption: 'Delete'
        diskSizeGB: 30
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
  }
  tags: {
    environment: 'shared'
    workload: 'sqldemo'
    'managed-by': 'bicep'
  }
}

output vmName string = vm.name
output privateEndpointNames array = [for (sqlServerId, index) in sqlServerIds: privateEndpoints[index].name]
