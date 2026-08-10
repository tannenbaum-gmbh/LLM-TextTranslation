# LLM-TextTranslation

Sample repository for LLM assisted Text Translation with Azure AI Translator and Azure OpenAI.

## Development container

Open the repository in VS Code and choose **Reopen in Container**. The dev container installs:

- .NET 8 SDK for the C# sample
- Azure CLI with Bicep support
- VS Code extensions for C#, Azure resources, Azure account sign-in, and Bicep

## Deploy Azure resources

The Bicep template in `infra/main.bicep` creates:

- an Azure AI Translator resource (`Microsoft.CognitiveServices/accounts`, kind `TextTranslation`)
- an Azure OpenAI resource plus an optional chat model deployment for LLM translation experiments

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

export AZURE_OPENAI_ENDPOINT=$(az deployment group show -g rg-llm-translation -n main --query properties.outputs.openAiEndpoint.value -o tsv)
export AZURE_OPENAI_DEPLOYMENT=$(az deployment group show -g rg-llm-translation -n main --query properties.outputs.openAiDeploymentName.value -o tsv)
export AZURE_OPENAI_KEY=$(az cognitiveservices account keys list -g rg-llm-translation -n myllmtrans-openai --query key1 -o tsv)
```

## Try translation endpoints

Translator Text REST API:

```bash
TEXT="Good morning" TARGET_LANGUAGE=de ./scripts/translate-text.sh
```

Azure OpenAI chat completion as an LLM translation endpoint:

```bash
TEXT="Good morning" TARGET_LANGUAGE=German ./scripts/llm-translate-openai.sh
```

## Run the C# sample

The sample app uses `Azure.AI.Translation.Text` 2.0.0 and reads `TRANSLATOR_ENDPOINT`, `TRANSLATOR_KEY`, and `TRANSLATOR_REGION` from the environment.

```bash
dotnet restore LLM-TextTranslation.sln
dotnet run --project src/LlmTextTranslation.Sample -- de "Good morning"
```
