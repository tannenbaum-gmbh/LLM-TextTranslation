# LLM-TextTranslation

Sample repository for LLM-assisted text translation with Azure AI Translator.

## Development container

Open the repository in VS Code and choose **Reopen in Container**. The dev container installs:

- .NET 8 SDK for the C# sample
- Azure CLI with Bicep support
- VS Code extensions for C#, Azure resources, Azure account sign-in, and Bicep

## Deploy Azure resources

The Bicep template in `infra/main.bicep` creates:

- an Azure AI Translator resource (`Microsoft.CognitiveServices/accounts`, kind `TextTranslation`)
- an Azure OpenAI resource plus an optional model deployment that can be referenced by Translator LLM translation

```bash
az login
az group create --name rg-llm-translation --location westeurope
az deployment group create \
  --resource-group rg-llm-translation \
  --template-file infra/main.bicep \
  --parameters namePrefix=myllmtrans deployOpenAiModel=true
```

Get keys for local samples without committing them:

```bash
export TRANSLATOR_ENDPOINT=$(az deployment group show -g rg-llm-translation -n main --query properties.outputs.translatorEndpoint.value -o tsv)
export TRANSLATOR_REGION=$(az deployment group show -g rg-llm-translation -n main --query properties.outputs.translatorRegion.value -o tsv)
export TRANSLATOR_KEY=$(az cognitiveservices account keys list -g rg-llm-translation -n myllmtrans-translator --query key1 -o tsv)
export TRANSLATOR_DEPLOYMENT_NAME=$(az deployment group show -g rg-llm-translation -n main --query properties.outputs.openAiDeploymentName.value -o tsv)
```

## Try translation endpoints

Translator Text REST API:

```bash
TEXT="Good morning" TARGET_LANGUAGE=de ./scripts/translate-text.sh
```

Azure AI Translator LLM translation (equivalent to SDK `deploymentName` usage from the `Translation using LLM` sample):

```bash
TEXT="Good morning" TARGET_LANGUAGE=de TRANSLATOR_DEPLOYMENT_NAME=gpt-4o-mini ./scripts/llm-translate-openai.sh
```

## Run the C# sample

The sample app uses `Azure.AI.Translation.Text` 2.0.0 and reads `TRANSLATOR_ENDPOINT`, `TRANSLATOR_KEY`, and `TRANSLATOR_REGION` from the environment. To use Translator LLM translation, also set `TRANSLATOR_DEPLOYMENT_NAME` (or pass it as the third argument).

```bash
dotnet restore LLM-TextTranslation.sln
dotnet run --project src/LlmTextTranslation.Sample -- de "Good morning"
dotnet run --project src/LlmTextTranslation.Sample -- de "Good morning" gpt-4o-mini
```
