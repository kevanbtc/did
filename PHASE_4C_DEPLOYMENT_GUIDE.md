# 🚀 PHASE 4C: AZURE FUNCTIONS & SECRETS DEPLOYMENT

**Status**: IN PROGRESS  
**Date**: November 1, 2025  
**Objective**: Deploy DID ecosystem to Azure production environment

---

## 📋 PHASE 4C OVERVIEW

This phase deploys the complete DID ecosystem to Azure with:
- ✅ **Infrastructure as Code** (Bicep templates)
- ✅ **Azure Key Vault** (Secrets management)
- ✅ **Azure Functions** (Serverless backend)
- ✅ **API Management** (Endpoint management)
- ✅ **Monitoring & Diagnostics** (Application Insights)

---

## 🎯 PHASE 4C EXECUTION PLAN

```
Phase 4C: Functions & Secrets Deployment
═════════════════════════════════════════════════════════════

Step 1: Create Infrastructure Files (Bicep)
  └─ Create: main.bicep (orchestration)
  └─ Create: functions.bicep (Azure Functions)
  └─ Create: keyvault.bicep (Key Vault)
  └─ Create: monitoring.bicep (Application Insights)
  └─ Estimated Time: 15 minutes

Step 2: Create Azure Resource Group & Deploy Infrastructure
  └─ Create resource group: did-ecosystem-rg
  └─ Deploy Bicep templates
  └─ Validate deployment
  └─ Estimated Time: 10 minutes

Step 3: Configure Azure Key Vault Secrets
  └─ OpenAI API keys
  └─ GitHub OAuth tokens
  └─ IPFS credentials
  └─ Database connection strings
  └─ Estimated Time: 10 minutes

Step 4: Deploy Azure Functions
  └─ Deploy authenticate function
  └─ Deploy verify-credential function
  └─ Deploy issue-credential function
  └─ Deploy resolve-did function
  └─ Verify deployment status
  └─ Estimated Time: 15 minutes

Step 5: Run Smoke Tests
  └─ Test authentication endpoint
  └─ Test credential verification
  └─ Test Key Vault access
  └─ Verify logging & monitoring
  └─ Estimated Time: 10 minutes

TOTAL ESTIMATED TIME: 60 minutes (1 hour)
```

---

## 📊 ARCHITECTURE DIAGRAM

```
┌────────────────────────────────────────────────────────────┐
│              AZURE DID ECOSYSTEM ARCHITECTURE               │
└────────────────────────────────────────────────────────────┘

                    Internet / GitHub
                           │
                           ▼
                    ┌──────────────┐
                    │   GitHub     │
                    │  Repository  │
                    └──────┬───────┘
                           │
                           ▼
            ┌──────────────────────────────────┐
            │     Azure API Management         │
            │  (Public endpoint /api/did/*)    │
            └──────┬───────────────────────────┘
                   │
        ┌──────────┼──────────┬──────────┐
        ▼          ▼          ▼          ▼
    ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
    │Authen- │ │Verify  │ │ Issue  │ │Resolve │
    │ticate  │ │Cred    │ │ Cred   │ │  DID   │
    │Function│ │Function│ │Function│ │Function│
    └────┬───┘ └────┬───┘ └────┬───┘ └────┬───┘
         │         │         │         │
         └────────────┬──────────────┘
                      ▼
              ┌──────────────────┐
              │   Key Vault      │
              │  (Secrets)       │
              │  - API Keys      │
              │  - OAuth Tokens  │
              │  - Creds         │
              └──────┬───────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
    ┌─────────┐ ┌─────────┐ ┌──────────┐
    │ OpenAI  │ │ GitHub  │ │ Database │
    │  API    │ │ OAuth   │ │          │
    └─────────┘ └─────────┘ └──────────┘

        ▼
    ┌──────────────────┐
    │ Application      │
    │ Insights         │
    │ (Monitoring)     │
    └──────────────────┘
```

---

## 🔧 STEP 1: CREATE INFRASTRUCTURE FILES

### 1.1 Main Bicep Template

**Location**: `infra/main.bicep`

```bicep
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
```

### 1.2 Key Vault Bicep Template

**Location**: `infra/keyvault.bicep`

```bicep
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

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUrl string = keyVault.properties.vaultUri
```

### 1.3 Azure Functions Bicep Template

**Location**: `infra/functions.bicep`

```bicep
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

// App Service Plan
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
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
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
          name: 'KeyVaultUri'
          value: reference(keyVaultId).vaultUri
        }
        {
          name: 'NODE_ENV'
          value: environmentName
        }
      ]
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
  tags: {
    environment: environmentName
  }
}

output functionAppId string = functionApp.id
output functionAppName string = functionApp.name
output functionsUrl string = 'https://${functionApp.properties.defaultHostName}'
```

### 1.4 Monitoring Bicep Template

**Location**: `infra/monitoring.bicep`

```bicep
param location string
param appName string
param environmentName string

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${appName}-insights-${environmentName}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 90
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    environment: environmentName
    project: 'did-ecosystem'
  }
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${appName}-logs-${environmentName}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
  tags: {
    environment: environmentName
  }
}

output appInsightsId string = appInsights.id
output appInsightsKey string = appInsights.properties.InstrumentationKey
output logAnalyticsId string = logAnalytics.id
```

---

## 📝 STEP 2: DEPLOY INFRASTRUCTURE TO AZURE

### 2.1 Prerequisites Check

Run these commands to verify prerequisites:

```powershell
# Check Azure CLI
az --version

# Check authentication
az account show

# Check resource group location availability
az account list-locations --query "[?displayName=='East US']" -o table
```

### 2.2 Create Resource Group

```powershell
$resourceGroupName = "did-ecosystem-rg"
$location = "eastus"

az group create `
  --name $resourceGroupName `
  --location $location

# Verify
az group show --name $resourceGroupName
```

### 2.3 Deploy Bicep Templates

```powershell
$deploymentName = "did-deployment-$(Get-Date -Format 'yyyyMMddHHmmss')"

az deployment group create `
  --name $deploymentName `
  --resource-group $resourceGroupName `
  --template-file infra/main.bicep `
  --parameters location=$location `
               environmentName=prod `
               appName=did-ecosystem

# Check deployment status
az deployment group show `
  --name $deploymentName `
  --resource-group $resourceGroupName `
  --query "properties.provisioningState"
```

---

## 🔐 STEP 3: CONFIGURE KEY VAULT SECRETS

### 3.1 Get Key Vault Name

```powershell
$keyVaultName = az keyvault list `
  --resource-group $resourceGroupName `
  --query "[0].name" -o tsv

Write-Host "Key Vault: $keyVaultName"
```

### 3.2 Add Secrets

```powershell
# OpenAI API Key
az keyvault secret set `
  --vault-name $keyVaultName `
  --name "openai-api-key" `
  --value "sk-proj-YOUR_OPENAI_KEY_HERE"

# GitHub OAuth Token
az keyvault secret set `
  --vault-name $keyVaultName `
  --name "github-oauth-token" `
  --value "ghp_YOUR_GITHUB_TOKEN_HERE"

# IPFS Gateway URL
az keyvault secret set `
  --vault-name $keyVaultName `
  --name "ipfs-gateway-url" `
  --value "https://gateway.pinata.cloud"

# Database Connection String
az keyvault secret set `
  --vault-name $keyVaultName `
  --name "database-connection-string" `
  --value "Server=YOUR_SERVER;Database=YOUR_DB;User Id=YOUR_USER;Password=YOUR_PASS"
```

### 3.3 Verify Secrets

```powershell
# List all secrets
az keyvault secret list --vault-name $keyVaultName

# Get specific secret (for verification only)
az keyvault secret show `
  --vault-name $keyVaultName `
  --name "openai-api-key"
```

---

## 🚀 STEP 4: DEPLOY AZURE FUNCTIONS

### 4.1 Get Function App Name

```powershell
$functionAppName = az functionapp list `
  --resource-group $resourceGroupName `
  --query "[0].name" -o tsv

Write-Host "Function App: $functionAppName"
```

### 4.2 Build Functions Locally

```powershell
cd functions

# Install dependencies
npm install

# Build
npm run build

# Package
func pack --build-worker-deps
```

### 4.3 Deploy Functions

```powershell
# Deploy to Azure
func azure functionapp publish $functionAppName `
  --build remote `
  --force

# Verify deployment
az functionapp function list `
  --resource-group $resourceGroupName `
  --name $functionAppName `
  --output table
```

### 4.4 Verify Function URLs

```powershell
# Get all function URLs
az functionapp function show-keys `
  --name $functionAppName `
  --resource-group $resourceGroupName `
  --function-name authenticate `
  --output json

# Expected endpoints:
# https://<functionAppName>.azurewebsites.net/api/authenticate
# https://<functionAppName>.azurewebsites.net/api/verify-credential
# https://<functionAppName>.azurewebsites.net/api/issue-credential
# https://<functionAppName>.azurewebsites.net/api/resolve-did
```

---

## ✅ STEP 5: RUN SMOKE TESTS

### 5.1 Test Authentication Endpoint

```powershell
$functionAppUrl = "https://$functionAppName.azurewebsites.net"

# Test authenticate endpoint
$response = Invoke-WebRequest `
  -Uri "$functionAppUrl/api/authenticate" `
  -Method POST `
  -ContentType "application/json" `
  -Body @{
    username = "test@example.com"
    password = "test-password"
  } | Select-Object -ExpandProperty Content | ConvertFrom-Json

Write-Host "Authentication Response: $response"
```

### 5.2 Test Credential Verification

```powershell
# Test verify-credential endpoint
$credentialPayload = @{
  credential = @{
    type = "VerifiableCredential"
    issuer = "did:example:issuer"
    credentialSubject = @{
      name = "John Doe"
    }
  }
} | ConvertTo-Json

$response = Invoke-WebRequest `
  -Uri "$functionAppUrl/api/verify-credential" `
  -Method POST `
  -ContentType "application/json" `
  -Body $credentialPayload | Select-Object -ExpandProperty Content | ConvertFrom-Json

Write-Host "Verification Response: $response"
```

### 5.3 Test Key Vault Access

```powershell
# Test that functions can access Key Vault
$response = Invoke-WebRequest `
  -Uri "$functionAppUrl/api/health" `
  -Method GET | Select-Object -ExpandProperty Content | ConvertFrom-Json

Write-Host "Health Check: $response"

# Verify Key Vault connection
if ($response.keyVaultStatus -eq "connected") {
    Write-Host "✅ Key Vault connection successful"
} else {
    Write-Host "❌ Key Vault connection failed"
}
```

### 5.4 Monitor Logs

```powershell
# View recent logs
az functionapp log tail `
  --name $functionAppName `
  --resource-group $resourceGroupName

# Or view in Application Insights
$appInsightsName = az resource list `
  --resource-group $resourceGroupName `
  --resource-type "Microsoft.Insights/components" `
  --query "[0].name" -o tsv

Write-Host "Application Insights: $appInsightsName"
Write-Host "View at: https://portal.azure.com/#@/resource/subscriptions/SUBSCRIPTION_ID/resourceGroups/$resourceGroupName/providers/microsoft.insights/components/$appInsightsName"
```

---

## 📊 VERIFICATION CHECKLIST

```
✅ Infrastructure Deployment
  ☐ Resource group created
  ☐ Key Vault deployed
  ☐ Function App deployed
  ☐ App Service Plan created
  ☐ Storage Account created
  ☐ Application Insights created
  ☐ All resources in correct region

✅ Secrets Configuration
  ☐ OpenAI API key stored
  ☐ GitHub OAuth token stored
  ☐ IPFS gateway URL stored
  ☐ Database connection string stored
  ☐ Function App has access to Key Vault
  ☐ Secrets marked as enabled

✅ Azure Functions Deployment
  ☐ Authenticate function deployed
  ☐ Verify-credential function deployed
  ☐ Issue-credential function deployed
  ☐ Resolve-did function deployed
  ☐ All functions accessible
  ☐ Correct trigger type (HTTP)

✅ Monitoring & Diagnostics
  ☐ Application Insights active
  ☐ Logs flowing to Application Insights
  ☐ Health endpoint responding
  ☐ Error tracking enabled
  ☐ Performance metrics visible

✅ Security & Access
  ☐ HTTPS enforced
  ☐ Minimum TLS 1.2
  ☐ Key Vault access restricted
  ☐ Function App identity configured
  ☐ IP restrictions (if applicable)
```

---

## 🎯 SUCCESS INDICATORS

When Phase 4C is complete, you'll have:

✅ **Infrastructure as Code**
- Bicep templates for reproducible deployments
- Version control for all infrastructure

✅ **Secure Secrets Management**
- Azure Key Vault with all credentials
- Function App connected to Key Vault
- Automatic secret rotation capability

✅ **Scalable Backend**
- Azure Functions for serverless computing
- Automatic scaling based on demand
- Built-in authentication

✅ **Production Monitoring**
- Application Insights tracking
- Real-time performance metrics
- Error tracking and alerts

✅ **Public API Endpoints**
- 4 HTTP endpoints for DID operations
- HTTPS with TLS 1.2+
- API Management for rate limiting

---

## 📞 TROUBLESHOOTING

### Issue: Deployment Failed
```
Solution:
1. Check resource group exists: az group show --name did-ecosystem-rg
2. Check subscription is active: az account show
3. Verify quota: az vm usage list --output table
4. Check Azure CLI version: az --version
```

### Issue: Functions Not Accessible
```
Solution:
1. Verify function app running: az functionapp list --resource-group did-ecosystem-rg
2. Check function app status: az functionapp show --resource-group did-ecosystem-rg --name <app-name>
3. View logs: az functionapp log tail --name <app-name> --resource-group did-ecosystem-rg
4. Check HTTPS: az functionapp show --resource-group did-ecosystem-rg --name <app-name> --query properties.httpsOnly
```

### Issue: Key Vault Access Denied
```
Solution:
1. Check access policies: az keyvault show-deleted --name <vault-name>
2. Verify function identity: az functionapp identity show --resource-group did-ecosystem-rg --name <app-name>
3. Add access policy: az keyvault set-policy --name <vault-name> --object-id <identity-id> --secret-permissions get
```

---

## 🚀 NEXT STEPS AFTER PHASE 4C

After successful deployment:

1. **Phase 5: Production Monitoring** (Starting next)
   - Monitor for 7 days
   - Track performance metrics
   - Optimize costs
   - Plan 2026 roadmap

2. **Ongoing Operations**
   - Daily health checks
   - Weekly performance review
   - Monthly cost analysis
   - Quarterly security audit

---

**Status**: Ready to execute Phase 4C  
**Next Command**: Begin Step 1 (Create Infrastructure Files)  
**Estimated Total Time**: 60 minutes

