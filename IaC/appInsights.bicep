@description('Name of Application Insights resource.')
param name string

@description('The location where the app insights will reside in.')
param rgLocation string = resourceGroup().location

// App Insights resource
resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: name
  location: rgLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output appInsightsKey string = reference(appInsights.id).InstrumentationKey
output appInsightsConnectionString string = reference(appInsights.id).ConnectionString
