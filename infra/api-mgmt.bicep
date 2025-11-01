param location string
param appName string
param environmentName string
param functionsBaseUrl string

// API Management (Consumption tier for cost efficiency)
resource apiManagement 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: '${appName}-apim-${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  properties: {
    publisherName: 'DID Ecosystem'
    publisherEmail: 'admin@did-ecosystem.local'
    notificationSenderEmail: 'admin@did-ecosystem.local'
  }
  tags: {
    environment: environmentName
    project: 'did-ecosystem'
  }
}

// API - DID Operations
resource didApi 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  parent: apiManagement
  name: 'did-api'
  properties: {
    displayName: 'DID Operations API'
    description: 'API for DID authentication, verification, and credential management'
    apiRevision: '1'
    path: 'did'
    protocols: [
      'https'
    ]
  }
}

// API Operation - Authenticate
resource authenticateOperation 'Microsoft.ApiManagement/service/apis/operations@2023-03-01-preview' = {
  parent: didApi
  name: 'authenticate'
  properties: {
    displayName: 'Authenticate'
    description: 'Authenticate a user and issue a credential'
    method: 'POST'
    urlTemplate: '/authenticate'
  }
}

// API Operation - Verify Credential
resource verifyOperation 'Microsoft.ApiManagement/service/apis/operations@2023-03-01-preview' = {
  parent: didApi
  name: 'verify-credential'
  properties: {
    displayName: 'Verify Credential'
    description: 'Verify a verifiable credential'
    method: 'POST'
    urlTemplate: '/verify-credential'
  }
}

// API Operation - Issue Credential
resource issueOperation 'Microsoft.ApiManagement/service/apis/operations@2023-03-01-preview' = {
  parent: didApi
  name: 'issue-credential'
  properties: {
    displayName: 'Issue Credential'
    description: 'Issue a new verifiable credential'
    method: 'POST'
    urlTemplate: '/issue-credential'
  }
}

// API Operation - Resolve DID
resource resolveOperation 'Microsoft.ApiManagement/service/apis/operations@2023-03-01-preview' = {
  parent: didApi
  name: 'resolve-did'
  properties: {
    displayName: 'Resolve DID'
    description: 'Resolve a DID to its document'
    method: 'GET'
    urlTemplate: '/resolve-did/{did}'
  }
}

// Backend for Functions
resource functionsBackend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  parent: apiManagement
  name: 'did-functions-backend'
  properties: {
    title: 'DID Functions'
    description: 'Azure Functions backend for DID operations'
    type: 'http'
    url: functionsBaseUrl
    protocol: 'http'
    circuitBreaker: {
      rules: [
        {
          name: 'circuitBreakerRule'
          failureCondition: {
            count: 3
            interval: 'PT30S'
            statusCodeRanges: [
              {
                min: 500
                max: 599
              }
            ]
          }
          tripDuration: 'PT1M'
        }
      ]
    }
  }
}

// Policy - Rate Limiting
resource rateLimitPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-03-01-preview' = {
  parent: didApi
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: '''
<policies>
  <inbound>
    <rate-limit-by-key calls="100" renewal-period="60" counter-key="@(context.Request.ClientIP)" />
    <cors>
      <allowed-origins>
        <origin>*</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
      <expose-headers>
        <header>*</header>
      </expose-headers>
    </cors>
    <set-backend-service base-url="@{
      string baseUrl = context.Api.ServiceUrl;
      return baseUrl;
    }" />
  </inbound>
  <backend>
    <forward-request />
  </backend>
  <outbound>
    <set-header name="X-Powered-By" exists-action="override">
      <value>DID-Ecosystem</value>
    </set-header>
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
'''
  }
}

output apiManagementId string = apiManagement.id
output apiManagementName string = apiManagement.name
output apiUrl string = 'https://${apiManagement.properties.gatewayUrl}/did'
output portalUrl string = 'https://${apiManagement.properties.portalUrl}'
