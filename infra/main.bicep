targetScope = 'subscription'

param project string
param env string
param location string = 'westeurope'

param deployApplications bool = false

param postGresAdministratorLogin string

@secure()
param postGresAdministratorLoginPassword string

var compositeName = '${project}-${env}'

param trinoImage string = ''
var trinoCoordinatorName = 'trino-coordinator'
var trinoWorkerName = 'trino-worker'

param h2Image string = ''
var h2Name = 'h2-sample-db'

param ontopImage string = ''
var ontopName = 'ontop-endpoint'

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${compositeName}-rg'
  location: location
}

module virtualNetwork 'modules/vnet.bicep' = {
  name: 'vnet'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    compositeName: compositeName
  }
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

module postgreDb 'modules/postgreSQL.bicep' = if (!deployApplications) {
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
    virtualNetworkInfrastructureSubnetId: virtualNetwork.outputs.virtualNetworkInfrastructureSubnetId
  }
}

module trinoCoordinatorContainerApp 'modules/containerApp.bicep' = if (deployApplications) {
  name: 'trinoCoordinator'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    containerAppName: trinoCoordinatorName
    containerAppEnvId: containerAppEnvironment.outputs.environmentId
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    minReplicas: 1
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

module trinoWorkerContainerApp 'modules/containerApp.bicep' = if (deployApplications) {
  name: 'trinoWorker'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    containerAppName: trinoWorkerName
    containerAppEnvId: containerAppEnvironment.outputs.environmentId
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    minReplicas: 3
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


module h2SampleContainerApp 'modules/containerApp.bicep' = if (deployApplications) {
  name: 'h2Sample'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    containerAppName: h2Name
    containerAppEnvId: containerAppEnvironment.outputs.environmentId
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    minReplicas: 1
    isExternal: true
    targetPort: 9092
    containers: [
      {
        name: h2Name
        image: h2Image
        env: [
        ]
      }
    ]
  }
}

module ontopContainerApp 'modules/containerApp.bicep' = if (deployApplications) {
  name: 'ontop'
  scope: resourceGroup(resGroup.name)
  params: {
    location: location
    containerAppName: ontopName
    containerAppEnvId: containerAppEnvironment.outputs.environmentId
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    minReplicas: 1
    isExternal: true
    targetPort: 8080
    containers: [
      {
        name: ontopName
        image: ontopImage
        env: [
        ]
      }
    ]
  }
}
