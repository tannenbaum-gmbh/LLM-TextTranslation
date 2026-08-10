#!/usr/bin/env bash
set -euo pipefail

: "${TRANSLATOR_ENDPOINT:=https://api.cognitive.microsofttranslator.com}"
: "${TRANSLATOR_KEY:?Set TRANSLATOR_KEY to a Translator resource key.}"
: "${TRANSLATOR_REGION:?Set TRANSLATOR_REGION to the Translator resource region, for example westeurope.}"
: "${TARGET_LANGUAGE:=de}"
: "${TEXT:=Hello from Azure AI Translator.}"

SOURCE_LANGUAGE="${SOURCE_LANGUAGE:-}"
TRANSLATOR_CATEGORY="${TRANSLATOR_CATEGORY:-}"
endpoint="${TRANSLATOR_ENDPOINT%/}"
url="${endpoint}/translate?api-version=3.0&to=${TARGET_LANGUAGE}"

if [[ -n "${SOURCE_LANGUAGE}" ]]; then
  url="${url}&from=${SOURCE_LANGUAGE}"
fi

if [[ -n "${TRANSLATOR_CATEGORY}" ]]; then
  url="${url}&category=${TRANSLATOR_CATEGORY}"
fi

body=$(TEXT="${TEXT}" python3 - <<'PY'
import json
import os
print(json.dumps([{"Text": os.environ["TEXT"]}]))
PY
)

curl --fail-with-body --silent --show-error \
  --request POST "${url}" \
  --header "Ocp-Apim-Subscription-Key: ${TRANSLATOR_KEY}" \
  --header "Ocp-Apim-Subscription-Region: ${TRANSLATOR_REGION}" \
  --header "Content-Type: application/json; charset=UTF-8" \
  --data "${body}"

echo
