targetScope = 'subscription'

param project string
param env string
param location string = 'westeurope'

var rgName = '${project}-${env}-rg'
var lawsName = '${project}-${env}-law'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module lawsModule './laws.bicep' = {
  name: 'logs'
  scope: resourceGroup(rg.name)
  params:{
    location: location
    name: lawsName
  }
}
