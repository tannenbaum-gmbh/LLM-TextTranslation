# LLM-TextTranslation

Sample repository for LLM-assisted text translation with Azure AI Translator.

## Development container

Open the repository in VS Code and choose **Reopen in Container**. The dev container installs:

- .NET 8 SDK for the C# sample
- Azure CLI with Bicep support
- VS Code extensions for C#, Azure resources, Azure account sign-in, and Bicep

## Deploy Azure resources

Use one of the two complete deployment options below.

| Option | Template | What it creates | Endpoint used for translation |
|---|---|---|---|
| A: Split resources | `infra/main.bicep` | Text Translator + separate Azure OpenAI (+ optional model deployment) | Translator endpoint from Text Translator resource |
| B: Foundry integrated | `infra/foundry-translator.bicep` | Single Azure AI Foundry (AIServices) resource + optional model deployment | Translator endpoint from the Foundry resource |

### Option A: Split Translator + OpenAI resources

This path is useful when you want explicit, separate Translator and OpenAI resources.

```bash
az login
az group create --name rg-llm-translation --location swedencentral
az deployment group create \
  --name main \
  --resource-group rg-llm-translation \
  --template-file infra/main.bicep \
  --parameters namePrefix=myllmtrans deployOpenAiModel=true
```

Assign your signed-in user the least-privilege role for translation:

```bash
TRANSLATOR_ID=$(az deployment group show -g rg-llm-translation -n main --query properties.outputs.translatorResourceId.value -o tsv)
USER_ID=$(az ad signed-in-user show --query id -o tsv)
az role assignment create \
  --assignee-object-id "$USER_ID" \
  --assignee-principal-type User \
  --role "Cognitive Services User" \
  --scope "$TRANSLATOR_ID"
```

Export the resource-specific endpoint. Role assignments can take several minutes
to propagate.

```bash
export TRANSLATOR_ENDPOINT=$(az deployment group show -g rg-llm-translation -n main --query properties.outputs.translatorEndpoint.value -o tsv)
export TRANSLATOR_DEPLOYMENT_NAME=$(az deployment group show -g rg-llm-translation -n main --query properties.outputs.openAiDeploymentName.value -o tsv)
```

### Option B: Foundry integrated resource + model deployment

This path avoids split, unrelated endpoints by using a single Foundry (AIServices)
resource for both translation endpoint and model deployment.

```bash
az login
az group create --name rg-llm-translation --location swedencentral
az deployment group create \
  --name foundry \
  --resource-group rg-llm-translation \
  --template-file infra/foundry-translator.bicep \
  --parameters namePrefix=myllmfoundry deployModel=true
```

Set runtime variables from Foundry outputs:

```bash
export TRANSLATOR_ENDPOINT=$(az deployment group show -g rg-llm-translation -n foundry --query properties.outputs.foundryTranslatorEndpoint.value -o tsv)
export TRANSLATOR_DEPLOYMENT_NAME=$(az deployment group show -g rg-llm-translation -n foundry --query properties.outputs.foundryModelDeploymentName.value -o tsv)
export TRANSLATOR_REGION=$(az deployment group show -g rg-llm-translation -n foundry --query properties.outputs.foundryRegion.value -o tsv)
```

### RBAC for both deployment options

Use least privilege and assign roles at the resource scope you actually use.

For calling translation (C# sample with `DefaultAzureCredential`):

- `Cognitive Services User` on the Translator resource (Option A)
- `Cognitive Services User` on the Foundry resource (Option B)

For creating or updating model deployments:

- `Cognitive Services OpenAI Contributor` on the OpenAI/Foundry resource

Example for Option B (Foundry resource scope):

```bash
FOUNDRY_ID=$(az deployment group show -g rg-llm-translation -n foundry --query properties.outputs.foundryResourceId.value -o tsv)
USER_ID=$(az ad signed-in-user show --query id -o tsv)

az role assignment create \
  --assignee-object-id "$USER_ID" \
  --assignee-principal-type User \
  --role "Cognitive Services User" \
  --scope "$FOUNDRY_ID"

az role assignment create \
  --assignee-object-id "$USER_ID" \
  --assignee-principal-type User \
  --role "Cognitive Services OpenAI Contributor" \
  --scope "$FOUNDRY_ID"
```

## Try translation endpoints

Translator Text REST API:

```bash
TEXT="Good morning" TARGET_LANGUAGE=de ./scripts/translate-text.sh
```

Azure AI Translator LLM translation (equivalent to SDK `deploymentName` usage from the `Translation using LLM` sample):

```bash
TEXT="Good morning" TARGET_LANGUAGE=de TRANSLATOR_DEPLOYMENT_NAME=gpt-5.1 ./scripts/llm-translate-openai.sh
```

## Run the C# sample

The sample app uses `Azure.AI.Translation.Text` 2.0.0 with
`DefaultAzureCredential`. For local development, run `az login` and set
`TRANSLATOR_ENDPOINT` to the resource-specific endpoint. To use Translator LLM
translation, also set `TRANSLATOR_DEPLOYMENT_NAME` (or pass it as the third
argument).

```bash
dotnet restore LLM-TextTranslation.sln
env -u TRANSLATOR_DEPLOYMENT_NAME dotnet run --project src/LlmTextTranslation.Sample -- de "Good morning"
dotnet run --project src/LlmTextTranslation.Sample -- de "Good morning" gpt-5.1
```

To compare both translation routes with a more substantial input, translate this
README first without and then with an LLM deployment:

```bash
env -u TRANSLATOR_DEPLOYMENT_NAME dotnet run --project src/LlmTextTranslation.Sample -- de "$(cat README.md)"
dotnet run --project src/LlmTextTranslation.Sample -- de "$(cat README.md)" "$TRANSLATOR_DEPLOYMENT_NAME"
```

## Troubleshooting

### Failed to get information on deployment gpt-5.1

If you see this error:

```text
Unhandled exception. Azure.RequestFailedException: Failed to get information on deployment gpt-5.1. Please double check that the deployment exists.
Status: 400 (Bad Request)
ErrorCode: 400

Content:
{"code":"400","message":"Failed to get information on deployment gpt-5.1. Please double check that the deployment exists."}
```

The Translator LLM call is reaching your Translator endpoint, but the
deployment name cannot be resolved for that Translator setup.

Common causes:

- `TRANSLATOR_DEPLOYMENT_NAME` is set to a value that does not exist.
- The model deployment exists in a different OpenAI/Foundry resource than the
  one your Translator setup is using.
- You are mixing endpoints from separate resources that are not interconnected.

Fix checklist:

1. Re-export values from your deployment outputs and avoid hardcoding
  `gpt-5.1` unless that exact deployment name exists.

  Option A (`infra/main.bicep`):

  ```bash
  export TRANSLATOR_ENDPOINT=$(az deployment group show -g rg-llm-translation -n main --query properties.outputs.translatorEndpoint.value -o tsv)
  export TRANSLATOR_DEPLOYMENT_NAME=$(az deployment group show -g rg-llm-translation -n main --query properties.outputs.openAiDeploymentName.value -o tsv)
  ```

  Option B (`infra/foundry-translator.bicep`):

  ```bash
  export TRANSLATOR_ENDPOINT=$(az deployment group show -g rg-llm-translation -n foundry --query properties.outputs.foundryTranslatorEndpoint.value -o tsv)
  export TRANSLATOR_DEPLOYMENT_NAME=$(az deployment group show -g rg-llm-translation -n foundry --query properties.outputs.foundryModelDeploymentName.value -o tsv)
  ```

2. Confirm the Bicep deployment created the model deployment (or deploy one)
  by setting `deployOpenAiModel=true` (Option A) or `deployModel=true`
  (Option B).

3. Ensure you are using a Translator resource and model deployment that are
  connected in the same Foundry/OpenAI integration path. If you use separate,
  unrelated AOAI and Cognitive Services endpoints, Translator cannot resolve
  the deployment name.

4. Retry after role assignment propagation (can take several minutes).
