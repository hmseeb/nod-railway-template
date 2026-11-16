#!/bin/sh
# Boots the Nod server as user node after preparing what Railway cannot express:
# volume ownership, a canonical vault key, and the relay config for the docker shim.
set -eu
: "${NOD_RELAY_TOKEN:?NOD_RELAY_TOKEN is required}"
: "${NOD_WORKSPACE_RELAY:?NOD_WORKSPACE_RELAY is required (host:port)}"
: "${NOD_BROWSER_RELAY:?NOD_BROWSER_RELAY is required (host:port)}"
data=${NOD_DATA_ROOT:-/var/lib/nod}
mkdir -p "$data/workspaces"
chown node:node "$data" "$data/workspaces"
chmod 700 "$data"
# Nod wants exactly 32 bytes as canonical base64. Railway's secret() cannot emit
# that, so derive it from a stable random seed. Same seed, same key, every boot.
if [ -z "${NOD_VAULT_KEY:-}" ]; then
  : "${NOD_VAULT_SEED:?Set NOD_VAULT_SEED or NOD_VAULT_KEY}"
  NOD_VAULT_KEY=$(node -e 'process.stdout.write(require("crypto").createHash("sha256").update(process.env.NOD_VAULT_SEED).digest("base64"))')
  export NOD_VAULT_KEY
fi
mkdir -p /etc/nod-relay
umask 077
node -e 'require("fs").writeFileSync("/etc/nod-relay/nod-relay.json", JSON.stringify({token: process.env.NOD_RELAY_TOKEN, workspace: process.env.NOD_WORKSPACE_RELAY, browser: process.env.NOD_BROWSER_RELAY}))'
chown -R node:node /etc/nod-relay
umask 022
export DOCKER_CONFIG=/etc/nod-relay
unset NOD_RELAY_TOKEN NOD_VAULT_SEED
cd /app
exec setpriv --reuid=node --regid=node --init-groups env HOME=/home/node node --import tsx src/server/index.ts
