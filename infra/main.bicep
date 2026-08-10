targetScope = 'resourceGroup'

@description('Azure region for all resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Base prefix used to generate globally unique resource names.')
param namePrefix string = 'llmtrans${uniqueString(resourceGroup().id)}'

@description('Name of the Azure AI Translator resource.')
param translatorName string = '${namePrefix}-translator'

@description('Translator SKU. Use F0 for experimentation when available in the selected region.')
@allowed([
  'F0'
  'S1'
  'S2'
  'S3'
  'S4'
])
param translatorSkuName string = 'S1'

@description('Name of the Azure OpenAI resource used for LLM-based translation experiments.')
param openAiName string = '${namePrefix}-openai'

@description('Azure OpenAI SKU.')
@allowed([
  'S0'
])
param openAiSkuName string = 'S0'

@description('Whether to create an Azure OpenAI chat model deployment. Set to false if the model is unavailable in your region/subscription.')
param deployOpenAiModel bool = true

@description('Azure OpenAI deployment name used by the sample scripts.')
param openAiDeploymentName string = 'gpt-4o-mini'

@description('Azure OpenAI model name to deploy.')
param openAiModelName string = 'gpt-4o-mini'

@description('Azure OpenAI model version to deploy.')
param openAiModelVersion string = '2024-07-18'

var translatorSubdomain = toLower(replace(translatorName, '_', '-'))
var openAiSubdomain = toLower(replace(openAiName, '_', '-'))

resource translator 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: translatorName
  location: location
  kind: 'TextTranslation'
  sku: {
    name: translatorSkuName
  }
  properties: {
    customSubDomainName: translatorSubdomain
    publicNetworkAccess: 'Enabled'
  }
}

resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAiName
  location: location
  kind: 'OpenAI'
  sku: {
    name: openAiSkuName
  }
  properties: {
    customSubDomainName: openAiSubdomain
    publicNetworkAccess: 'Enabled'
  }
}

resource openAiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = if (deployOpenAiModel) {
  parent: openAi
  name: openAiDeploymentName
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: openAiModelName
      version: openAiModelVersion
    }
  }
}

output translatorName string = translator.name
output translatorEndpoint string = translator.properties.endpoint
output translatorRegion string = location
output translatorResourceId string = translator.id
output openAiName string = openAi.name
output openAiEndpoint string = openAi.properties.endpoint
output openAiDeploymentName string = deployOpenAiModel ? openAiDeployment.name : openAiDeploymentName
