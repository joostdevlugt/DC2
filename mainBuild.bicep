targetScope='resourceGroup'

@description('Name of the Virtual Machine')
param vmName string = 'DC'

@description('Admin username for the VM')
param adminUsername string = 'joostadmin'

@description('Admin password for the VM')
@secure()
param adminPassword string = 

@description('Location for the resources')
param location string = resourceGroup().location

@description('Name of the Virtual Network')
param vnetName string = 'dcVnet'

@description('Address prefix for the Virtual Network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Name of the Subnet')
param subnetName string = 'dcSubnet'

@description('Address prefix for the Subnet')
param subnetAddressPrefix string = '10.0.0.0/24'

@description('VM size')
param vmSize string = 'Standard_DS2_v2'

@description('OS Disk Size in GB')
param osDiskSizeGB int = 128

@description('Install AD script')
param scriptFileUri string = ''

@description('Install AD script')
param scriptCommandToExecute string = ''

@description('Operating System')
param osPublisher string = 'MicrosoftWindowsServer'
param osOffer string = 'WindowsServer'
param osSku string = '2022-Datacenter'
param osVersion string = 'latest'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-LDAP'
        properties: {
          priority: 1001
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${vmName}-publicIP'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
          subnet: {
            id: vnet.properties.subnets[0].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: osPublisher
        offer: osOffer
        sku: osSku
        version: osVersion
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        diskSizeGB: osDiskSizeGB
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}
resource installdc 'Microsoft.Compute/virtualMachines/extensions@2020-12-01'{
    location: location
    name: '${vmName}/installdc'
    properties: {
        publisher: 'Microsoft.Compute'
        type: 'CustomScriptExtension'
        typeHandlerVersion: '1.10'
        autoUpgradeMinorVersion: true
        settings: {
          fileUris: scriptFileUri
          commandToExecute: scriptCommandToExecute
        }
      }
    
}



