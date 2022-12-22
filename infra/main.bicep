targetScope = 'subscription'

param project string
param env string
param location string = 'westeurope'

var compositeName = '${project}-${env}'

var trinoCoordinatorName = 'trino-coordinator'
var trinoWorkerName = 'trino-worker'

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
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceName
  }
}

module trinoCoordinatorContainerApp 'modules/containerApp.bicep' = {
  name: 'trinoCoordinator'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    containerAppName: trinoCoordinatorName
    containerAppEnvId: containerAppEnvironment.outputs.environmentId
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    isExternal: true
    targetPort: 8080
    containers: [
      {
      name: trinoCoordinatorName
      image: 'vdkg01pocacr.azurecr.io/trino:2022-12-22_09-21-40'
      env: [
          {
            name: 'TRINO_NODE_TYPE'
            value: 'coordinator'
          }
          {
            name: 'TRINO_DISCOVERY_URI'
            value: 'https://${trinoCoordinatorName}${containerAppEnvironment.outputs.defaultDomain}'
          }
        ]
      }
    ]
  }
}

module trinoWorkerContainerApp 'modules/containerApp.bicep' = {
  name: 'trinoWorker'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    containerAppName: trinoWorkerName
    containerAppEnvId: containerAppEnvironment.outputs.environmentId
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    isExternal: true
    targetPort: 8080
    containers: [
      {
      name: trinoWorkerName
      image: 'vdkg01pocacr.azurecr.io/trino:2022-12-22_09-21-40'
      env: [
          {
            name: 'TRINO_NODE_TYPE'
            value: 'worker'
          }
          {
            name: 'TRINO_DISCOVERY_URI'
            value: 'https://${trinoCoordinatorName}${containerAppEnvironment.outputs.defaultDomain}'
          }
        ]
      }
    ]
  }
}
