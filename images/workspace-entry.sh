#!/bin/sh
# Prepares the single /workspace volume, then runs the relay agent as root.
# Commands it executes drop to node (uid 1000) or a connected-CLI uid.
set -eu
mkdir -p /workspace/.nod-home
if [ ! -e /workspace/.nod-home/.local ]; then
  cp -a /opt/nod-home-skel/. /workspace/.nod-home/
fi
chown node:node /workspace /workspace/.nod-home
chmod 755 /workspace
chmod 700 /workspace/.nod-home
exec node /opt/nod-relay/nod-relay-agent.mjs
