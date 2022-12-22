param location string
param compositeName string
param logAnalyticsWorkspaceName string
param storageAccountName string
param shareName string

resource laws 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}
resource sa 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageAccountName
}

resource env 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: '${compositeName}-appenv'
  location: location 
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: laws.properties.customerId
        sharedKey: laws.listKeys().primarySharedKey 
      }
    }
  }
  
  resource storage 'storages' = {
    name: '${compositeName}-appenv-storage'
    properties: {
       azureFile: {
         accessMode: 'ReadOnly'
          accountKey: sa.listKeys().keys[0].value
          accountName: sa.name
          shareName: shareName
       }
    }
  }
}

output environmentId string = env.id
output defaultDomain string = env.properties.defaultDomain
