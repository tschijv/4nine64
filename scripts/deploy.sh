#!/bin/bash
#
# 4nine64.nl uitrollen naar de Hetzner. Statische site, dus geen build: de map site/ gaat met
# rsync naar /srv/4nine64, nginx serveert hem, Caddy zet er TLS voor. Opnieuw draaien is veilig.
#
# De eerste keer zet dit script ook het Caddy-blok (deploy/4nine64.caddy) in Caddyfile.local van
# de voorzieningencatalogus en laat Caddy herladen — daarna staat het er en wordt het met rust
# gelaten. Zie README.md voor DNS.
#
# Gebruik:  bash scripts/deploy.sh
set -euo pipefail
cd "$(dirname "$0")/.."

SERVER="${SITE_SSH:-root@178.104.240.234}"
DOEL="${SITE_PAD:-/srv/4nine64}"
HOST="4nine64.nl"
CADDYDIR="/srv/ldcms/modules/voorzieningencatalogus/deploy"

echo "→ bestanden naar $SERVER:$DOEL"
ssh "$SERVER" "mkdir -p $DOEL"
rsync -az --delete site/ "$SERVER:$DOEL/site/"
rsync -az docker-compose.yml nginx.conf deploy/4nine64.caddy "$SERVER:$DOEL/"

echo "→ nginx starten"
ssh "$SERVER" "cd $DOEL && docker compose up -d --quiet-pull 2>&1 | grep -v '^$' || true"

echo "→ Caddy"
ssh "$SERVER" bash -s <<EOF
set -e
cd $CADDYDIR
if grep -q '4nine64-web' Caddyfile.local; then
  echo "  blok staat al in Caddyfile.local"
else
  cat $DOEL/4nine64.caddy >> Caddyfile.local
  cp Caddyfile.local Caddyfile
  docker exec deploy-caddy-1 caddy reload --config /etc/caddy/Caddyfile
  echo "  blok toegevoegd en Caddy herladen"
fi
EOF

echo "→ controleren"
# Eerst binnendoor: kan Caddy de nginx bereiken en staat de nieuwe html erop?
if ssh "$SERVER" "docker exec deploy-caddy-1 wget -qO- http://4nine64-web/" | grep -q "30243619"; then
  echo "  ✓ 4nine64-web antwoordt op het Caddy-netwerk"
else
  echo "  ✗ 4nine64-web antwoordt niet; kijk met: ssh $SERVER 'cd $DOEL && docker compose logs --tail 30'"
  exit 1
fi
# Dan buitenom, maar alleen als DNS al naar deze server wijst.
SERVER_IP="${SERVER#*@}"
if [ "$(dig +short A "$HOST" | tail -1)" = "$SERVER_IP" ]; then
  for i in $(seq 1 6); do
    if curl -fs --max-time 10 "https://$HOST/" | grep -q "30243619"; then
      echo "  ✓ https://$HOST/ draait"
      exit 0
    fi
    sleep 10
  done
  echo "  ✗ https://$HOST/ antwoordt nog niet; certificaat komt meestal binnen een minuut. Kijk met: ssh $SERVER 'docker logs --tail 40 deploy-caddy-1'"
  exit 1
else
  echo "  DNS van $HOST wijst nog niet naar $SERVER_IP (nu: $(dig +short A "$HOST" | tr '\n' ' ')). Zodra het A-record is omgezet haalt Caddy vanzelf het certificaat."
fi
