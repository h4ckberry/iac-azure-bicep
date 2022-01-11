param adminUser string = 'adminUser'

resource windowsVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'vm-windows'
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: 'windowsVM'
      adminUsername: adminUser
      adminPassword: 'adminP@ssword'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'vm-windows'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}

resource windowsVMExtensions 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: windowsVM
  name: 'nodejsInstallScript'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    // settings: {
    //   fileUris: [
    //     'fileUris'
    //   ]
    // }
    protectedSettings: {
      commandToExecute: loadTextContent('myscript.ps1')
    }
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'networkInterfaceName'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
          subnet: {
            id: vNet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource vNet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: 'vNetName'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'vNetSubnetName'
        properties: {
          addressPrefix: '10.0.0.0/24'
          // networkSecurityGroup: {
          //   id: networkSecurityGroup.id
          // }
        }
      }
    ]
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: 'publicIPAddress'
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    // dnsSettings: {
    //   domainNameLabel: dnsLabelPrefix
    // }
  }
}

// resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'nodejsInstallScript'
//   location: resourceGroup().location
//   kind: 'AzurePowerShell'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${managedIdentity.id}': {}
//       // '/subscriptions/${subId}/resourcegroups/${rgName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/': {}
//     }
//   }
//   properties: {
//     azPowerShellVersion: '3.0'
//     scriptContent: loadTextContent('myscript.ps1')
//     // scriptContent: '''
//     //   mkdir test-test-v2
//     // '''
//     retentionInterval: 'P1D'
//   }
// }

// resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
//   name: 'managedId'
//   location: resourceGroup().location
// }

// resource customRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
//   name: guid('deploymentScriptMinimum') // ここで role_name を知っていればguid が算出できるようにする。
//   properties: {
//     roleName: 'deployment-script-minimum-privilege-for-deployment-principal'
//     description: 'Configure least privilege for the deployment principal in deployment script'
//     type: 'customRole'
//     permissions: [
//       {
//         actions: [
//           'Microsoft.Storage/storageAccounts/*'
//           'Microsoft.ContainerInstance/containerGroups/*'
//           'Microsoft.Resources/deployments/*'
//           'Microsoft.Resources/deploymentScripts/*'
//         ]
//       }
//     ]
//     assignableScopes: [
//       resourceGroup().id
//     ]
//   }
// }

// resource RoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
//   name: customRole.name
//   scope: deploymentScript
//   properties: {
//     roleDefinitionId: customRole.id
//     principalId: managedIdentity.properties.principalId
//     principalType: 'ServicePrincipal'
//     // https://githubmemory.com/repo/Azure/bicep/issues/3695
//   }
// }
