param location string
param appServicePlanId string
param storageAccountName string
param webAppName string

@secure()
param foundryUsername string

@secure()
param foundryPassword string

@secure()
param foundryAdminKey string

var linuxFxVersion = 'DOCKER|felddy/foundryvtt:release'

resource webApp 'Microsoft.Web/sites@2021-01-15' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: linuxFxVersion
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: ''
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://index.docker.io/v1'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: ''
        }
        {
          name: 'FOUNDRY_USERNAME'
          value: foundryUsername
        }
        {
          name: 'FOUNDRY_PASSWORD'
          value: foundryPassword
        }
        {
          name: 'FOUNDRY_ADMIN_KEY'
          value: foundryAdminKey
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
    }
  }

  resource config 'config@2021-01-15' = {
    name: 'web'
    properties: {
      linuxFxVersion: linuxFxVersion
      azureStorageAccounts: {
        foundrydata: {
          type: 'AzureFiles'
          accountName: storageAccountName
          shareName: 'foundryvttdata'
          mountPath: '/data'
        }
      }
    }
  }

}

output url string = 'https://${webAppName}.azurewebsites.net'
