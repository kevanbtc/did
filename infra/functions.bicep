param location string
param appName string
param environmentName string
param keyVaultId string
param appInsightsId string

// Storage Account for Functions
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${replace(appName, '-', '')}sa${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
  }
  tags: {
    environment: environmentName
  }
}

// App Service Plan (Consumption - Serverless)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${appName}-plan-${environmentName}'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'functionapp'
  tags: {
    environment: environmentName
  }
}

// Function App
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: '${appName}-func-${environmentName}'
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: 'did-functions'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(appInsightsId, '2020-02-02').InstrumentationKey
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'default'
        }
        {
          name: 'KeyVaultUri'
          value: reference(keyVaultId, '2023-07-01').vaultUri
        }
        {
          name: 'NODE_ENV'
          value: environmentName
        }
        {
          name: 'ENABLE_MSAL_LOGGING'
          value: 'false'
        }
      ]
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      cors: {
        allowedOrigins: [
          '*'
        ]
        supportCredentials: false
      }
    }
    httpsOnly: true
    clientAffinityEnabled: false
  }
  tags: {
    environment: environmentName
    project: 'did-ecosystem'
  }
}

// Enable system-assigned managed identity
resource functionAppAuth 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, functionApp.id, 'contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86a8031')
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output functionAppId string = functionApp.id
output functionAppName string = functionApp.name
output functionsUrl string = 'https://${functionApp.properties.defaultHostName}'
output storageName string = storageAccount.name
