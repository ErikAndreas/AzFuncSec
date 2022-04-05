param location string = resourceGroup().location
param name string
param env string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.signalrservice/signalr?tabs=bicep

resource signalR 'Microsoft.SignalRService/SignalR@2021-06-01-preview' = {
  name: name
  location: location
  sku: {
    capacity: 1 // free 1, standard 1,2,5,10,20,50,100 change for prod
    name: ('p' == env) ? 'Standard_S1' : 'Free_F1' // Standard_S1
    tier: ('p' == env) ? 'Standard' : 'Free' // Standard
  }
  properties: {
    disableLocalAuth: true // disable auth via connection string, only allow for aad auth
    features: [
      {
        flag: 'ServiceMode'
        value: 'Serverless'
      }
    ]
    cors: {
      allowedOrigins: [
        '*' // default but should be explicitly set for prod
      ]
    }
  }
}


