param environment string
param resourcePrefix string
param location string = resourceGroup().location
param repositoryBranch string
param repositoryUrl string

@secure()
param repositoryToken string
param skuName string = 'Free'
param skuTier string = 'Free'

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/staticsites?tabs=bicep
resource staticWebApp 'Microsoft.Web/staticSites@2021-01-15' = {
  name: 'sw-${resourcePrefix}-${environment}'
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    provider: 'GitHub' // required to ensure success in follow up deployments
    repositoryUrl: repositoryUrl
    repositoryToken: repositoryToken
    branch: repositoryBranch
    buildProperties: {
      outputLocation: '' // next.js will export to the out directory
      appLocation: 'build/web'
      appBuildCommand: 'flutter build web'
      apiLocation: ''
    }
  }
}
