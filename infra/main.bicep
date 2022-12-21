targetScope = 'subscription'

param project string
param env string
param location string = 'westeurope'

var compositeName = '${project}-${env}'

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${compositeName}-rg'
  location: location
}

module keyVault 'modules/keyVault.bicep' = {
  name: 'kv'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    compositeName: compositeName
  }
}

module logAnalyticsWorkspace 'modules/logAnalytics.bicep' = {
  name: 'logs'
  scope: resourceGroup(resGroup.name)
  params:{
    location: location
    compositeName: compositeName
  }
}

module containerRegistry 'modules/containerRegistry.bicep' = {
  name: 'acr'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    compositeName: compositeName
    keyVaultName: keyVault.outputs.keyVaultName
  }
}

module containerAppEnvironment 'modules/containerAppEnv.bicep' = {
  name: 'appenv'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    compositeName: compositeName 
  }
}
