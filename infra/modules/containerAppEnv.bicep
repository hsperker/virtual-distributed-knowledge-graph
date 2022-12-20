param location string
param compositeName string
param lawCustomerId string
@secure()
param lawSharedKeySecret string


resource env 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: '${compositeName}-appenv'
  location: location 
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: lawCustomerId
        sharedKey: lawSharedKeySecret
      }
    }
  }
}
