param location string
param appName string
param environmentName string

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${appName}-logs-${environmentName}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    environment: environmentName
    project: 'did-ecosystem'
  }
}

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
    WorkspaceResourceId: logAnalytics.id
  }
  tags: {
    environment: environmentName
    project: 'did-ecosystem'
  }
}

// Alert Rule - High Error Rate
resource errorAlertRule 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${appName}-high-error-rate'
  location: 'global'
  properties: {
    description: 'Alert when error rate exceeds 5%'
    severity: 2
    enabled: true
    scopes: [
      appInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Failed requests'
          metricName: 'failedRequests'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Total'
        }
      ]
    }
  }
  tags: {
    environment: environmentName
  }
}

output appInsightsId string = appInsights.id
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output logAnalyticsId string = logAnalytics.id
output logAnalyticsWorkspaceId string = logAnalytics.properties.customerId
