param location string
param compositeName string

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
