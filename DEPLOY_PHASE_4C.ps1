# Phase 4C Deployment Script
# Run this script to deploy the DID ecosystem to Azure

param(
    [string]$ResourceGroupName = "did-ecosystem-rg",
    [string]$Location = "eastus",
    [string]$EnvironmentName = "prod",
    [string]$AppName = "did-ecosystem"
)

Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          DID ECOSYSTEM - PHASE 4C DEPLOYMENT SCRIPT                ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Step 1: Create Resource Group
Write-Host "Step 1: Creating Azure Resource Group..." -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroupName"
Write-Host "  Location: $Location"

az group create `
  --name $ResourceGroupName `
  --location $Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create resource group" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Resource group created successfully" -ForegroundColor Green
Write-Host ""

# Step 2: Deploy Infrastructure with Bicep
Write-Host "Step 2: Deploying infrastructure with Bicep..." -ForegroundColor Cyan
$deploymentName = "did-deployment-$(Get-Date -Format 'yyyyMMddHHmmss')"

az deployment group create `
  --name $deploymentName `
  --resource-group $ResourceGroupName `
  --template-file infra/main.bicep `
  --parameters location=$Location `
               environmentName=$EnvironmentName `
               appName=$AppName

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to deploy infrastructure" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Infrastructure deployed successfully" -ForegroundColor Green
Write-Host ""

# Step 3: Get Deployment Outputs
Write-Host "Step 3: Retrieving deployment outputs..." -ForegroundColor Cyan

$deployment = az deployment group show `
  --name $deploymentName `
  --resource-group $ResourceGroupName `
  --query "properties.outputs" | ConvertFrom-Json

$functionAppName = $deployment.functionAppName.value
$keyVaultName = $deployment.keyVaultName.value
$appInsightsId = $deployment.appInsightsId.value

Write-Host "  Function App: $functionAppName" -ForegroundColor Yellow
Write-Host "  Key Vault: $keyVaultName" -ForegroundColor Yellow
Write-Host ""

# Step 4: Configure Key Vault Secrets
Write-Host "Step 4: Configuring Azure Key Vault..." -ForegroundColor Cyan
Write-Host "  ⚠️  IMPORTANT: You need to update these secrets with actual values:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Replace these placeholders:"
Write-Host "    1. OpenAI API Key"
Write-Host "    2. GitHub OAuth Token"
Write-Host "    3. IPFS Gateway URL"
Write-Host "    4. Database Connection String"
Write-Host ""

Write-Host "Run these commands to update secrets:" -ForegroundColor Cyan
Write-Host "az keyvault secret set --vault-name $keyVaultName --name 'openai-api-key' --value 'YOUR_KEY_HERE'"
Write-Host "az keyvault secret set --vault-name $keyVaultName --name 'github-oauth-token' --value 'YOUR_TOKEN_HERE'"
Write-Host "az keyvault secret set --vault-name $keyVaultName --name 'ipfs-gateway-url' --value 'YOUR_URL_HERE'"
Write-Host "az keyvault secret set --vault-name $keyVaultName --name 'database-connection-string' --value 'YOUR_CONNECTION_STRING_HERE'"
Write-Host ""

# Step 5: Deploy Azure Functions
Write-Host "Step 5: Deploying Azure Functions..." -ForegroundColor Cyan
Write-Host "  This requires local setup of Functions runtime" -ForegroundColor Yellow
Write-Host ""
Write-Host "To deploy functions locally:"
Write-Host "  1. cd functions"
Write-Host "  2. npm install"
Write-Host "  3. npm run build"
Write-Host "  4. func azure functionapp publish $functionAppName --build remote --force"
Write-Host ""

# Step 6: Display Summary
Write-Host "═════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Resource Group Created" -ForegroundColor Green
Write-Host "   URL: https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroupName" -ForegroundColor Yellow
Write-Host ""
Write-Host "✅ Infrastructure Deployed" -ForegroundColor Green
Write-Host "   Deployment: $deploymentName" -ForegroundColor Yellow
Write-Host ""
Write-Host "📦 Azure Resources Created:" -ForegroundColor Cyan
Write-Host "   ✓ Key Vault: $keyVaultName"
Write-Host "   ✓ Function App: $functionAppName"
Write-Host "   ✓ Application Insights"
Write-Host "   ✓ API Management"
Write-Host "   ✓ Storage Account"
Write-Host ""
Write-Host "⏳ NEXT STEPS:" -ForegroundColor Yellow
Write-Host "   1. Update Key Vault secrets with actual values"
Write-Host "   2. Deploy Azure Functions (see commands above)"
Write-Host "   3. Run smoke tests"
Write-Host "   4. Proceed to Phase 5: Production Monitoring"
Write-Host ""
Write-Host "═════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
