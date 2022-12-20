param location string
param compositeName string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${compositeName}-kv'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enableSoftDelete: false
    accessPolicies: [
    ]
  }
}

output keyVaultName string = keyVault.name
