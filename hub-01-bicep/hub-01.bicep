param location string = 'westeurope'
param locationSpoke03 string = 'northeurope'

param username string = 'nicola'
@secure()
param password string = 'password.123'
param virtualMachineSKU string = 'Standard_D2s_v3'
@description('Basic, Standard or Premium tier')
@allowed([ 'Basic', 'Standard', 'Premium' ])
param firewallTier string = 'Premium'

param enableBgp bool = false
param localGatewayFqdn string = ''
param vnetGatewayDnsLabel string = ''

var hublabName = 'hub-lab-net'
var spoke01Name = 'spoke-01'
var spoke02Name = 'spoke-02'
var spoke03Name = 'spoke-03'

var firewallName = 'lab-firewall'
var firewallIPName = 'lab-firewall-ip'
var firewallManagementIPName = 'lab-firewall-mgt-ip'

var bastionName = 'lab-bastion'
var bastionIPName = 'lab-bastion-ip'

var vnetGatewayIPName = 'lab-gateway-ip'
var vnetGatewayName = 'lab-gateway'

var localGatewayName = 'lab-local-gateway'

var vmHubName = 'hub-vm'
var vmHubDiskName = '${vmHubName}-disk'
var vmHubNICName = '${vmHubName}-nic'
var vmHubAutoshutdownName = 'shutdown-computevm-${vmHubName}'

var vm01Name = '${spoke01Name}-vm'
var vm01DiskName = '${vm01Name}-disk'
var vm01NICName = '${vm01Name}-nic'
var vm01AutoshutdownName = 'shutdown-computevm-${vm01Name}'

var vm02Name = '${spoke02Name}-vm'
var vm02DiskName = '${vm02Name}-disk'
var vm02NICName = '${vm02Name}-nic'
var vm02AutoshutdownName = 'shutdown-computevm-${vm02Name}'

var vm03Name = '${spoke03Name}-vm'
var vm03DiskName = '${vm03Name}-disk'
var vm03NICName = '${vm03Name}-nic'
var vm03AutoshutdownName = 'shutdown-computevm-${vm03Name}'

var subnets = concat(
  [
    { name: 'GatewaySubnet', properties: { addressPrefix: '10.12.4.0/24' } }
    { name: 'AzureFirewallSubnet', properties: { addressPrefix: '10.12.0.0/24' } }
    { name: 'AzureBastionSubnet', properties: { addressPrefix: '10.12.2.0/24' } }
    { name: 'DefaultSubnet', properties: { addressPrefix: '10.12.1.0/24' } }
  ],
  firewallTier == 'Basic' ? [
    {
      name: 'AzureFirewallManagementSubnet'
      properties: {
        addressPrefix: '10.12.3.0/24'
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    }
  ] : []
)

resource hubLabVnet 'Microsoft.Network/virtualNetworks@2019-09-01' = {
  name: hublabName
  location: location
  properties: { addressSpace: { addressPrefixes: [ '10.12.0.0/16' ] }
    subnets: subnets
  }
}

resource spoke01vnet 'Microsoft.Network/virtualNetworks@2019-09-01' = {
  name: spoke01Name
  location: location
  properties: { addressSpace: { addressPrefixes: [ '10.13.1.0/24' ] }
    subnets: [
      { name: 'default', properties: { addressPrefix: '10.13.1.0/26' } }
      { name: 'services', properties: { addressPrefix: '10.13.1.64/26' } }
    ]
  }
}

resource spoke02vnet 'Microsoft.Network/virtualNetworks@2019-09-01' = {
  name: spoke02Name
  location: location
  properties: { addressSpace: { addressPrefixes: [ '10.13.2.0/24' ] }
    subnets: [
      { name: 'default', properties: { addressPrefix: '10.13.2.0/26' } }
      { name: 'services', properties: { addressPrefix: '10.13.2.64/26' } }
    ]
  }
}

resource spoke03vnet 'Microsoft.Network/virtualNetworks@2019-09-01' = {
  name: spoke03Name
  location: locationSpoke03
  properties: { addressSpace: { addressPrefixes: [ '10.13.3.0/24' ] }
    subnets: [
      { name: 'default', properties: { addressPrefix: '10.13.3.0/26' } }
      { name: 'services', properties: { addressPrefix: '10.13.3.64/26' } }
    ]
  }
}

resource peeringHubSpoke01 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = {
  parent: hubLabVnet
  name: '${hublabName}-to-${spoke01Name}'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: true, useRemoteGateways: false, remoteVirtualNetwork: { id: spoke01vnet.id } }
}

resource peeringSpoke01Hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = {
  parent: spoke01vnet
  name: '${spoke01Name}-to-${hublabName}'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: hubLabVnet.id } }
}

resource peeringHubSpoke02 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = {
  parent: hubLabVnet
  name: '${hublabName}-to-${spoke02Name}'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: true, useRemoteGateways: false, remoteVirtualNetwork: { id: spoke02vnet.id } }
}

resource peeringSpoke02Hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = {
  parent: spoke02vnet
  name: '${spoke02Name}-to-${hublabName}'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: hubLabVnet.id } }
}

resource peeringHubSpoke03 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = {
  parent: hubLabVnet
  name: '${hublabName}-to-${spoke03Name}'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: true, useRemoteGateways: false, remoteVirtualNetwork: { id: spoke03vnet.id } }
}

resource peeringSpoke03Hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = {
  parent: spoke03vnet
  name: '${spoke03Name}-to-${hublabName}'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: hubLabVnet.id } }
}

resource bastionHubIP 'Microsoft.Network/publicIPAddresses@2019-09-01' = {
  name: bastionIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource bastion 'Microsoft.Network/bastionHosts@2019-09-01' = {
  name: bastionName
  location: location
  dependsOn: [ hubLabVnet ]
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', hublabName, 'AzureBastionSubnet') }
          publicIPAddress: { id: bastionHubIP.id }
        }
      }
    ]
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'hub-playground-ws'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource firewallIP 'Microsoft.Network/publicIPAddresses@2019-09-01' = {
  name: firewallIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource firewallManagementIP 'Microsoft.Network/publicIPAddresses@2019-09-01' = if (firewallTier == 'Basic') {
  name: firewallManagementIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

@description('Need to do things a bit different if the policy already exists')
param firewallPolicyExists bool = false

// if we do this when the firewall policy has rule collection groups then we get a weird error
resource newFirewallPolicy 'Microsoft.Network/firewallPolicies@2022-07-01' = if (!firewallPolicyExists) {
  name: '${firewallName}-${toLower(firewallTier)}-policy'
  location: location
  properties: {
    sku: {
      tier: firewallTier
    }
  }
}

resource existingFirewallPolicy 'Microsoft.Network/firewallPolicies@2020-05-01' existing = if (firewallPolicyExists) {
  name: '${firewallName}-${toLower(firewallTier)}-policy'
}

resource firewall 'Microsoft.Network/azureFirewalls@2022-09-01' = {
  name: firewallName
  location: location
  dependsOn: [ hubLabVnet, vnetGateway ] // can run into some weird conflict error with the gateway
  properties: {
    firewallPolicy: {
      id: firewallPolicyExists ? existingFirewallPolicy.id : newFirewallPolicy.id
    }
    managementIpConfiguration: firewallTier == 'Basic' ? {
      name: 'ipconfig-mgt'
      properties: {
        subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', hublabName, 'AzureFirewallManagementSubnet') }
        publicIPAddress: { id: firewallManagementIP.id }
      }
    } : null
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', hublabName, 'AzureFirewallSubnet') }
          publicIPAddress: { id: firewallIP.id }
        }
      } ]
    sku: { name: 'AZFW_VNet', tier: firewallTier }
  }
}

resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: workspace.name
  scope: firewall
  properties: {
    workspaceId: workspace.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: true
        }
      }
    ]
    logAnalyticsDestinationType: null
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: true
        }
      }
    ]
  }
}

resource vnetGatewayIP 'Microsoft.Network/publicIPAddresses@2019-09-01' = {
  name: vnetGatewayIPName
  location: location
  sku: { name: 'Basic' }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vnetGatewayDnsLabel == '' ? null : vnetGatewayDnsLabel
    }
  }
}

resource vnetGateway 'Microsoft.Network/virtualNetworkGateways@2019-09-01' = {
  name: vnetGatewayName
  location: location
  dependsOn: [ hubLabVnet ]
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', hublabName, 'GatewaySubnet') }
          publicIPAddress: { id: vnetGatewayIP.id }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: enableBgp
    bgpSettings: enableBgp ? {
      asn: 65511
    } : null
    sku: { name: 'VpnGw1', tier: 'VpnGw1' }
  }
}

// if we enable bgp we also need a local gateway for the connection
resource localGateway 'Microsoft.Network/localNetworkGateways@2022-09-01' = if (enableBgp) {
  name: localGatewayName
  location: location
  properties: {
    bgpSettings: {
      asn: 65510
      bgpPeeringAddress: '192.168.3.254'
    }
    localNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
    fqdn: localGatewayFqdn
  }
}

resource vmHubDisk 'Microsoft.Compute/disks@2019-07-01' = {
  name: vmHubDiskName
  location: location
  properties: {
    creationData: { createOption: 'Empty' }
    diskSizeGB: 128
  }
}

resource vmHubNIC 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: vmHubNICName
  location: location
  dependsOn: [ hubLabVnet ]
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', hublabName, 'DefaultSubnet') }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vmHub 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmHubName
  location: location
  dependsOn: []
  properties: {
    hardwareProfile: { vmSize: virtualMachineSKU }
    storageProfile: {
      imageReference: { publisher: 'MicrosoftWindowsServer', offer: 'WindowsServer', sku: '2019-Datacenter', version: 'latest' }
      dataDisks: [ {
          lun: 0
          name: vmHubDiskName
          createOption: 'Attach'
          managedDisk: { id: vmHubDisk.id }
        }
      ]
    }
    osProfile: {
      computerName: vmHubName
      adminUsername: username
      adminPassword: password
      windowsConfiguration: { enableAutomaticUpdates: true }
    }
    networkProfile: {
      networkInterfaces: [ {
          id: vmHubNIC.id
        }
      ]
    }
  }
}

resource vmHubAutoshutdown 'microsoft.devtestlab/schedules@2018-09-15' = {
  name: vmHubAutoshutdownName
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: 'UTC'
    dailyRecurrence: { time: '20:00' }
    notificationSettings: { status: 'Disabled' }
    targetResourceId: vmHub.id
  }
}

resource vm01Disk 'Microsoft.Compute/disks@2019-07-01' = {
  name: vm01DiskName
  location: location
  properties: {
    creationData: { createOption: 'Empty' }
    diskSizeGB: 128
  }
}

resource vm01NIC 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: vm01NICName
  location: location
  dependsOn: [ spoke01vnet ]
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', spoke01Name, 'default') }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm01 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vm01Name
  location: location
  dependsOn: []
  properties: {
    hardwareProfile: { vmSize: virtualMachineSKU }
    storageProfile: {
      imageReference: { publisher: 'MicrosoftWindowsServer', offer: 'WindowsServer', sku: '2019-Datacenter', version: 'latest' }
      dataDisks: [ {
          lun: 0
          name: vm01DiskName
          createOption: 'Attach'
          managedDisk: { id: vm01Disk.id }
        }
      ]
    }
    osProfile: {
      computerName: vm01Name
      adminUsername: username
      adminPassword: password
      windowsConfiguration: { enableAutomaticUpdates: true }
    }
    networkProfile: {
      networkInterfaces: [ {
          id: vm01NIC.id
        }
      ]
    }
  }
}

resource vm01Autoshutdown 'microsoft.devtestlab/schedules@2018-09-15' = {
  name: vm01AutoshutdownName
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: 'UTC'
    dailyRecurrence: { time: '20:00' }
    notificationSettings: { status: 'Disabled' }
    targetResourceId: vm01.id
  }
}

resource vm02Disk 'Microsoft.Compute/disks@2019-07-01' = {
  name: vm02DiskName
  location: location
  properties: {
    creationData: { createOption: 'Empty' }
    diskSizeGB: 128
  }
}

resource vm02NIC 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: vm02NICName
  location: location
  dependsOn: [ spoke02vnet ]
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', spoke02Name, 'default') }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm02 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vm02Name
  location: location
  dependsOn: []
  properties: {
    hardwareProfile: { vmSize: virtualMachineSKU }
    storageProfile: {
      imageReference: { publisher: 'MicrosoftWindowsServer', offer: 'WindowsServer', sku: '2019-Datacenter', version: 'latest' }
      dataDisks: [ {
          lun: 0
          name: vm02DiskName
          createOption: 'Attach'
          managedDisk: { id: vm02Disk.id }
        }
      ]
    }
    osProfile: {
      computerName: vm02Name
      adminUsername: username
      adminPassword: password
      windowsConfiguration: { enableAutomaticUpdates: true }
    }
    networkProfile: {
      networkInterfaces: [ {
          id: vm02NIC.id
        }
      ]
    }
  }
}

resource vm02Autoshutdown 'microsoft.devtestlab/schedules@2018-09-15' = {
  name: vm02AutoshutdownName
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: 'UTC'
    dailyRecurrence: { time: '20:00' }
    notificationSettings: { status: 'Disabled' }
    targetResourceId: vm02.id
  }
}

resource vm03Disk 'Microsoft.Compute/disks@2019-07-01' = {
  name: vm03DiskName
  location: locationSpoke03
  properties: {
    creationData: { createOption: 'Empty' }
    diskSizeGB: 128
  }
}

resource vm03NIC 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: vm03NICName
  location: locationSpoke03
  dependsOn: [ spoke03vnet ]
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', spoke03Name, 'default') }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm03 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vm03Name
  location: locationSpoke03
  dependsOn: []
  properties: {
    hardwareProfile: { vmSize: virtualMachineSKU }
    storageProfile: {
      imageReference: { publisher: 'MicrosoftWindowsServer', offer: 'WindowsServer', sku: '2019-Datacenter', version: 'latest' }
      dataDisks: [ {
          lun: 0
          name: vm03DiskName
          createOption: 'Attach'
          managedDisk: { id: vm03Disk.id }
        }
      ]
    }
    osProfile: {
      computerName: vm03Name
      adminUsername: username
      adminPassword: password
      windowsConfiguration: { enableAutomaticUpdates: true }
    }
    networkProfile: {
      networkInterfaces: [ {
          id: vm03NIC.id
        }
      ]
    }
  }
}

resource vm03Autoshutdown 'microsoft.devtestlab/schedules@2018-09-15' = {
  name: vm03AutoshutdownName
  location: locationSpoke03
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: 'UTC'
    dailyRecurrence: { time: '20:00' }
    notificationSettings: { status: 'Disabled' }
    targetResourceId: vm03.id
  }
}
