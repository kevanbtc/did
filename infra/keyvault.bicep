param location string
param keyVaultName string
param environmentName string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }

  tags: {
    environment: environmentName
    project: 'did-ecosystem'
    createdDate: utcNow('u')
  }
}

// Secret placeholders (to be filled in Step 3)
resource openaiSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openai-api-key'
  properties: {
    value: 'placeholder-update-in-step-3'
    attributes: {
      enabled: true
    }
  }
}

resource githubSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'github-oauth-token'
  properties: {
    value: 'placeholder-update-in-step-3'
    attributes: {
      enabled: true
    }
  }
}

resource ipfsSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'ipfs-gateway-url'
  properties: {
    value: 'placeholder-update-in-step-3'
    attributes: {
      enabled: true
    }
  }
}

resource databaseSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'database-connection-string'
  properties: {
    value: 'placeholder-update-in-step-3'
    attributes: {
      enabled: true
    }
  }
}

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUrl string = keyVault.properties.vaultUri
