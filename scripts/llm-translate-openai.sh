#!/usr/bin/env bash
set -euo pipefail

: "${AZURE_OPENAI_ENDPOINT:?Set AZURE_OPENAI_ENDPOINT to your Azure OpenAI endpoint.}"
: "${AZURE_OPENAI_KEY:?Set AZURE_OPENAI_KEY to an Azure OpenAI resource key.}"
: "${AZURE_OPENAI_DEPLOYMENT:?Set AZURE_OPENAI_DEPLOYMENT to the chat model deployment name.}"
: "${AZURE_OPENAI_API_VERSION:=2024-10-21}"
: "${TARGET_LANGUAGE:=German}"
: "${TEXT:=Hello from Azure OpenAI translation.}"

endpoint="${AZURE_OPENAI_ENDPOINT%/}"
url="${endpoint}/openai/deployments/${AZURE_OPENAI_DEPLOYMENT}/chat/completions?api-version=${AZURE_OPENAI_API_VERSION}"

body=$(TEXT="${TEXT}" TARGET_LANGUAGE="${TARGET_LANGUAGE}" python3 - <<'PY'
import json
import os
print(json.dumps({
    "messages": [
        {
            "role": "system",
            "content": "Translate the user's text accurately. Return only the translation."
        },
        {
            "role": "user",
            "content": f"Translate to {os.environ['TARGET_LANGUAGE']}: {os.environ['TEXT']}"
        }
    ],
    "temperature": 0.2,
    "max_tokens": 800
}))
PY
)

curl --fail-with-body --silent --show-error \
  --request POST "${url}" \
  --header "api-key: ${AZURE_OPENAI_KEY}" \
  --header "Content-Type: application/json" \
  --data "${body}"

echo
