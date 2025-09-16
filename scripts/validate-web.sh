#!/usr/bin/env bash
set -euo pipefail

NS="${NS:-default}"
RELEASE="${RELEASE:-web-nginx}"
TIMEOUT="${TIMEOUT:-300}"
SLEEP="${SLEEP:-5}"

log(){ echo "[validate] $(date +%H:%M:%S) $*"; }

command -v kubectl >/dev/null || { echo "kubectl requerido"; exit 1; }
command -v curl >/dev/null || { echo "curl requerido"; exit 1; }
command -v jq >/dev/null || { echo "jq requerido"; exit 1; }

log "Verificando Deployment"
kubectl -n "$NS" get deploy "$RELEASE" >/dev/null

log "Esperando rollout (${TIMEOUT}s)"
kubectl -n "$NS" rollout status deploy/"$RELEASE" --timeout="${TIMEOUT}s"

log "Obteniendo endpoint externo"
SVC_JSON=$(kubectl -n "$NS" get svc "$RELEASE" -o json)
HOST=$(echo "$SVC_JSON" | jq -r '.status.loadBalancer.ingress[0].hostname // empty')
IP=$(echo "$SVC_JSON"   | jq -r '.status.loadBalancer.ingress[0].ip       // empty')

if [[ -z "${HOST}${IP}" ]]; then
  DEADLINE=$(( $(date +%s) + TIMEOUT ))
  while [[ $(date +%s) -lt $DEADLINE ]]; do
    sleep "$SLEEP"
    SVC_JSON=$(kubectl -n "$NS" get svc "$RELEASE" -o json || true)
    HOST=$(echo "$SVC_JSON" | jq -r '.status.loadBalancer.ingress[0].hostname // empty')
    IP=$(echo "$SVC_JSON"   | jq -r '.status.loadBalancer.ingress[0].ip       // empty')
    [[ -n "${HOST}${IP}" ]] && break
  done
fi

URL="http://${HOST:-$IP}"
[[ -z "$URL" || "$URL" == "http://" ]] && { echo "Sin endpoint externo"; exit 1; }
log "Endpoint: $URL"

log "Chequeando HTTP 200 + contenido 'Pod:'"
DEADLINE=$(( $(date +%s) + TIMEOUT ))
while [[ $(date +%s) -lt $DEADLINE ]]; do
  CODE=$(curl -sS -o /dev/null -w "%{http_code}" "$URL" || true)
  HTML=$(curl -sS "$URL" || true)
  if [[ "$CODE" == "200" ]] && echo "$HTML" | grep -qiE "Pod:[[:space:]]*[A-Za-z0-9-]+"; then
    READY=$(kubectl -n "$NS" get deploy "$RELEASE" -o jsonpath='{.status.readyReplicas}')
    DESIRED=$(kubectl -n "$NS" get deploy "$RELEASE" -o jsonpath='{.spec.replicas}')
    log "Deployment OK: $READY/$DESIRED ready"
    exit 0
  fi
  sleep "$SLEEP"
done

echo "Validación falló"; exit 1
