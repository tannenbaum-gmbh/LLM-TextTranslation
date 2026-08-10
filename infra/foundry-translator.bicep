targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = 'swedencentral'

@description('Base prefix used to generate globally unique resource names.')
param namePrefix string = 'llmfoundry${uniqueString(resourceGroup().id)}'

@description('Name of the Azure AI Foundry (AIServices) resource.')
param foundryName string = '${namePrefix}-foundry'

@description('AIServices SKU.')
@allowed([
  'S0'
])
param foundrySkuName string = 'S0'

@description('Whether to create a model deployment in the Foundry resource.')
param deployModel bool = true

@description('Model deployment name used by Translator LLM category/deploymentName.')
param foundryModelDeploymentName string = 'gpt-5.1'

@description('Model name to deploy.')
param foundryModelName string = 'gpt-5.1'

@description('Model version to deploy.')
param foundryModelVersion string = '2025-11-13'

@description('Deployment capacity units for the model deployment. Capacity maps to TPM based on model-specific quota ratios.')
@minValue(1)
param foundryModelCapacity int = 10

var foundrySubdomain = toLower(replace(foundryName, '_', '-'))

resource foundry 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: foundryName
  location: location
  kind: 'AIServices'
  sku: {
    name: foundrySkuName
  }
  properties: {
    customSubDomainName: foundrySubdomain
    publicNetworkAccess: 'Enabled'
  }
}

resource foundryModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = if (deployModel) {
  parent: foundry
  name: foundryModelDeploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: foundryModelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: foundryModelName
      version: foundryModelVersion
    }
  }
}

output foundryName string = foundry.name
output foundryResourceId string = foundry.id
output foundryEndpoint string = 'https://${foundrySubdomain}.cognitiveservices.azure.com'
output foundryTranslatorEndpoint string = 'https://${foundrySubdomain}.cognitiveservices.azure.com'
output foundryRegion string = location
output foundryModelDeploymentName string = deployModel ? foundryModelDeployment.name : foundryModelDeploymentName
