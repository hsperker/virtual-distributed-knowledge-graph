param location string
param compositeName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: '${compositeName}-vnet'
  location: location
  properties: {
     addressSpace: {
       addressPrefixes: [
        '10.10.0.0/16'
       ]
     }
     subnets: [
      {
        name: 'InfrastructureSubnet'
        properties: {
          addressPrefix: '10.10.0.0/23'
        }
      }
     ]
  }
}

output virtualNetworkInfrastructureSubnetId string = virtualNetwork.properties.subnets[0].id
