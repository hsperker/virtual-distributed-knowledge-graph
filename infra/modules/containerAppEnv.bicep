param location string
param compositeName string

resource laws 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: '${compositeName}-law'
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
}
