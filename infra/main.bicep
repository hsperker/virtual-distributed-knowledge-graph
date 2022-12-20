targetScope = 'subscription'

param project string
param env string
param location string = 'westeurope'

var rgName = '${project}-${env}-rg'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}
