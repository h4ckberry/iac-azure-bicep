@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('for AKS Cluster Name & VNET Name Prefix')
param clusterName string

@description('for AKS Cluster Managed Identity Name')
param managedIdName string = guid(clusterName)

// 1. VNet & Subnet の作成

@description('for AKS Cluster Name & VNET Name Prefix')
param VNetAddressPrefix string = '10.10.0.0/16'

@description('for AKS Cluster Name & VNET Name Prefix')
param SubnetAddressPrefix string = '10.10.1.0/24'

resource AKSVNet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: 'vn-${clusterName}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        VNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'sn-${clusterName}'
        properties: {
          addressPrefix: SubnetAddressPrefix
        }
      }
    ]
  }
}

// scope プロパティでリソースを参照するには、リソースのシンボリック名を指定する必要がある
resource AKSSubNet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  parent: AKSVNet // https://githubmemory.com/repo/Azure/bicep/issues/1972
  name: 'sn-${clusterName}'
}

// ユーザー割り当て Managed ID の作成
resource ManagedId 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdName
  location: location
}

// ロールの作成と割り当て
@description('A new GUID used to identify the role assignment')
param roleNameGuid string = guid(managedIdName)

var role = {
  Owner: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  Reader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

resource RoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: roleNameGuid
  scope: AKSSubNet
  properties: {
    roleDefinitionId: role['Contributor']
    principalId: ManagedId.properties.principalId
    principalType: 'ServicePrincipal'
    // https://githubmemory.com/repo/Azure/bicep/issues/3695
  }
  dependsOn: [
    ManagedId
  ]
}

//　AKS Cluster の作成
resource aks 'Microsoft.ContainerService/managedClusters@2021-08-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'UserAssigned'
    // userAssignedIdentities: ManagedIdと指定するとデプロイできない。
    // https://stackoverflow.com/questions/64877861/the-template-function-reference-is-not-expected-at-this-location
    userAssignedIdentities: {
      '${ManagedId.id}': {}
    }
  }
  properties: {
    dnsPrefix: clusterName
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'agentpool1'
        count: 2
        vmSize: 'standard_d2s_v3'
        mode: 'System'
        vnetSubnetID: AKSSubNet.id
      }
    ]
  }
}
