@description('Azure region for all resources')
param location string

@description('Resource name prefix for the ISE node hostname')
param hostname string

@description('Organization tag value')
param organizationName string

@description('Creator tag value')
param creatorTag string

@description('Existing virtual network name')
param virtualNetworkName string

@description('Existing subnet name inside the virtual network')
param subnetName string

@description('VM size for the ISE node')
param vmSize string = 'Standard_D4s_v3'

@description('Admin username for the VM')
param adminUsername string = 'iseadmin'

@secure()
@description('Admin password for the VM')
param adminPassword string

@description('SSH public key content')
param sshPublicKey string

@description('OS managed disk type')
param managedDiskType string = 'Standard_LRS'

@description('OS disk size in GiB')
param osDiskSizeGb int = 300

@description('Marketplace image offer')
param imageOffer string = 'cisco-ise-virtual'

@description('Marketplace image publisher')
param imagePublisher string = 'cisco'

@description('Marketplace image SKU')
param imageSku string = 'cisco-ise_3_4'

@description('Marketplace image version')
param imageVersion string = 'latest'

@description('ISE roles tag value')
param iseRoles string = ''

@description('ISE services tag value')
param iseServices string = ''

@description('Plain-text cloud-init/user-data payload to inject into the VM')
param userData string

var publicIpName = '${hostname}-public-ip'
var nicName = '${hostname}-nic'
var osDiskName = '${hostname}-os-disk'
var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: {
    Name: publicIpName
    Creator: creatorTag
    Machine: hostname
    Subnet: subnetName
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-ise-node'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
  tags: {
    Name: nicName
    Creator: creatorTag
    Organization: organizationName
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: hostname
  location: location
  plan: {
    name: imageSku
    product: imageOffer
    publisher: imagePublisher
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: hostname
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
      userData: base64(userData)
    }
    storageProfile: {
      imageReference: {
        offer: imageOffer
        publisher: imagePublisher
        sku: imageSku
        version: imageVersion
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        diskSizeGB: osDiskSizeGb
        managedDisk: {
          storageAccountType: managedDiskType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  tags: {
    Name: hostname
    Creator: creatorTag
    Organization: organizationName
    Roles: iseRoles
    Services: iseServices
  }
}

output networkInterfaceId string = nic.id
output publicIpResourceId string = publicIp.id
output vmResourceId string = vm.id
