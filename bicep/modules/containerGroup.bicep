param location string
param storageAccountName string
param shareName string = 'foundryvttdata'
param containerGroupName string
param containerDnsName string

@allowed([
  'Small'
  'Medium'
  'Large'
])
param containerConfiguration string = 'Small'

@secure()
param foundryUsername string

@secure()
param foundryPassword string

@secure()
param foundryAdminKey string

var containerConfigurationMap = {
  Small: {
    memoryInGB: '3'
    cpu: 1
  }
  Medium: {
    memoryInGB: '2'
    cpu: 2
  }
  Large: {
    memoryInGB: '3'
    cpu: 4
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource caddystorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: 'gatfvttcaddy'
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-03-01' = {
  name: containerGroupName
  location: location
  properties: {
    containers: [
      {
        name: 'foundryvtt'
        properties: {
          image: 'felddy/foundryvtt:10'
          ports: [
            {
              protocol: 'TCP'
              port: 30000
            }
          ]
          environmentVariables: [
            {
              name: 'FOUNDRY_USERNAME'
              secureValue: foundryUsername
            }
            {
              name: 'FOUNDRY_PASSWORD'
              secureValue: foundryPassword
            }
            {
              name: 'FOUNDRY_ADMIN_KEY'
              secureValue: foundryAdminKey
            }
          ]
          resources: {
            requests: {
              memoryInGB: any(containerConfigurationMap[containerConfiguration].memoryInGB)
              cpu: containerConfigurationMap[containerConfiguration].cpu
            }
          }
          volumeMounts: [
            {
              name: 'foundrydata'
              mountPath: '/data'
            }
          ]
        }
      }
      {
        name: 'foundryvttcaddy'
        properties: {
          image: 'caddy:latest'
          ports: [
            {
              protocol: 'TCP'
              port: 80
            }
            {
              protocol: 'TCP'
              port: 443
            }
          ]
          command:[
            'caddy'
            'reverse-proxy'
            '--from'
            'foundry.gathrawno.co.uk'
            '--to'
            'localhost:30000'
          ]
          resources: {
            requests: {
              memoryInGB: any(containerConfigurationMap[containerConfiguration].memoryInGB)
              cpu: containerConfigurationMap[containerConfiguration].cpu
            }
          }
          volumeMounts: [
            {
              name: 'caddydata'
              mountPath: '/data'
            }
          ]
        }
      }
    ]
    restartPolicy: 'OnFailure'
    ipAddress: {
      ports: [
        {
          protocol: 'TCP'
          port: 80
        }
        {
          protocol: 'TCP'
          port: 443
        }
      ]
      type: 'Public'
      dnsNameLabel: containerDnsName
    }
    osType: 'Linux'
    volumes: [
      {
        name: 'foundrydata'
        azureFile: {
          shareName: shareName
          storageAccountName: storageAccountName
          storageAccountKey: storageAccount.listKeys().keys[0].value
        }
      }
      {
        name: 'caddydata'
        azureFile: {
          shareName: 'caddydata'
          storageAccountName: 'gatfvttcaddy'
          storageAccountKey: caddystorageAccount.listKeys().keys[0].value
        }
      }
    ]
    sku: 'Standard'
  }
}

output url string = 'http://${containerGroup.properties.ipAddress.fqdn}:30000'
