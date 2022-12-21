
param location string
param compositeName string

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: replace('${compositeName}-sa', '-', '')
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}   

resource files 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: '${storage.name}/default/${compositeName}-appenv'
}

output storageAccountName string = storage.name
output shareName string = files.name
