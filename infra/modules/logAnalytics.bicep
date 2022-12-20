param location string
param compositeName string
param keyVaultName string

var sharedKeySecretName = 'log-analytics-shared-key'

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource law 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: '${compositeName}-law'
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource sharedKeySecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: sharedKeySecretName
  parent: keyVault
  properties: {
    value: law.listKeys().primarySharedKey
  }
}

output customerId string = law.properties.customerId
output sharedKeySecretName string = sharedKeySecretName
