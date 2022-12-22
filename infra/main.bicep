targetScope = 'subscription'

param project string
param env string
param location string = 'westeurope'

param postGresAdministratorLogin string

@secure()
param postGresAdministratorLoginPassword string

var compositeName = '${project}-${env}'

var trinoImage = 'vdkg01pocacr.azurecr.io/trino:2022-12-22_15-59-08'
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

module storageAccount 'modules/storagAccount.bicep' = {
  name: 'sa'
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

module postgreDb 'modules/postgreSQL.bicep' = {
  name: 'postgreDB'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    compositeName: compositeName
    keyVaultName: keyVault.outputs.keyVaultName
    administratorLogin: postGresAdministratorLogin
    administratorLoginPassword: postGresAdministratorLoginPassword
  }
}

module containerAppEnvironment 'modules/containerAppEnv.bicep' = {
  name: 'appenv'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    compositeName: compositeName 
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceName
    storageAccountName: storageAccount.outputs.storageAccountName
    shareName: storageAccount.outputs.shareName
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
      image: trinoImage
      env: [
          {
            name: 'TRINO_NODE_TYPE'
            value: 'coordinator'
          }
          {
            name: 'TRINO_DISCOVERY_URI'
            value: 'https://${trinoCoordinatorName}.${containerAppEnvironment.outputs.defaultDomain}'
          }
          {
            name: 'POSTGRES_CONNECTION_JDBC_URL'
            value: 'jdbc:postgresql://${postgreDb.outputs.fqdn}:5432/employees_database'
          }
          {
            name: 'POSTGRES_CONNECTION_USER'
            value: '${postGresAdministratorLogin}@${postgreDb.outputs.name}'
          }
          {
            name: 'POSTGRES_CONNECTION_PASSWORD'
            value: postGresAdministratorLoginPassword
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
      image: trinoImage
      env: [
          {
            name: 'TRINO_NODE_TYPE'
            value: 'worker'
          }
          {
            name: 'TRINO_DISCOVERY_URI'
            value: 'https://${trinoCoordinatorName}.${containerAppEnvironment.outputs.defaultDomain}'
          }
        ]
      }
    ]
  }
}
