param location string
param compositeName string


param keyVaultName string

param administratorLogin string

@secure()
param administratorLoginPassword string

var firewallrules = [
  {
    Name: 'rule1'
    StartIpAddress: '0.0.0.0'
    EndIpAddress: '255.255.255.255'
  }
]


resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource basicAuthUserSecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: 'postGresAdministratorLogin'
  properties: {
    value: administratorLogin
  }
}

resource basicAuthPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: 'postGresAdministratorLoginPassword'
  properties: {
    value: administratorLoginPassword
  }
}

resource server 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: '${compositeName}-pdb'
  location: location
  sku: {
    name: 'GP_Gen5_2'
    tier: 'GeneralPurpose'
    capacity: 2
    size: '51200'
    family: 'Gen5'
  }
  properties: {
    createMode: 'Default'
    version: '11'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageProfile: {
      storageMB: 51200
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    publicNetworkAccess: 'Enabled'
  }
}

@batchSize(1)
resource firewallRules 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = [for rule in firewallrules: {
  name: '${server.name}/${rule.Name}'
  properties: {
    startIpAddress: rule.StartIpAddress
    endIpAddress: rule.EndIpAddress
  }
}]

output name string = server.name
output fqdn string = server.properties.fullyQualifiedDomainName
