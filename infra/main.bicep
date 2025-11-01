param location string = resourceGroup().location
param environmentName string = 'prod'
param appName string = 'did-ecosystem'

// Deploy Key Vault
module keyVault 'keyvault.bicep' = {
  name: 'keyVaultDeploy'
  params: {
    location: location
    keyVaultName: '${appName}-kv-${uniqueString(resourceGroup().id)}'
    environmentName: environmentName
  }
}

// Deploy Application Insights
module monitoring 'monitoring.bicep' = {
  name: 'monitoringDeploy'
  params: {
    location: location
    appName: appName
    environmentName: environmentName
  }
}

// Deploy Azure Functions
module functions 'functions.bicep' = {
  name: 'functionsDeploy'
  params: {
    location: location
    appName: appName
    environmentName: environmentName
    keyVaultId: keyVault.outputs.keyVaultId
    appInsightsId: monitoring.outputs.appInsightsId
  }
}

// Deploy API Management
module apiManagement 'api-mgmt.bicep' = {
  name: 'apiMgmtDeploy'
  params: {
    location: location
    appName: appName
    environmentName: environmentName
    functionsBaseUrl: functions.outputs.functionsUrl
  }
}

output functionAppId string = functions.outputs.functionAppId
output keyVaultUrl string = keyVault.outputs.keyVaultUrl
output appInsightsId string = monitoring.outputs.appInsightsId
output apiManagementUrl string = apiManagement.outputs.apiUrl
output functionAppName string = functions.outputs.functionAppName
output keyVaultName string = keyVault.outputs.keyVaultName
