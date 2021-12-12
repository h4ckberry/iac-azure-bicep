@description('DB Name')
param dbName string
@description('location')
param location string = resourceGroup().location
@description('Administrator user name')
param adminUser string
@description('Administrator user password')
param adminPassword string
@description('SKU tier')
@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
param skuTier string = 'Basic'
@description('The family of hardware')
param skuFamily string = 'Gen5'
@description('The scale up/out capacity')
param skuCapacity int = skuTier == 'Basic' ? 2 : 4

var skuNamePrefix = skuTier == 'GeneralPurpose' ? 'GP' : (skuTier == 'Basic' ? 'B' : 'MO')
var skuName = '${skuNamePrefix}_${skuFamily}_${skuCapacity}'

@description('Allow source ipaddress')
param allowIp string

resource pgsql 'Microsoft.DBForPostgreSQL/servers@2017-12-01' = {
  name: dbName
  location: location
  sku: {
    name: skuName
    tier: skuTier
    family: skuFamily
    capacity: skuCapacity
  }
  properties: {
    createMode: 'Default'
    administratorLogin: adminUser
    administratorLoginPassword: adminPassword
    publicNetworkAccess: 'Enabled'
  }
}

resource symbolicname 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = {
  name: 'allow-local-ip'
  parent: pgsql
  properties: {
    endIpAddress: allowIp
    startIpAddress: allowIp
  }
}
