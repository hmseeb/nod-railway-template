#!/bin/sh
# Runs upstream's browser worker as node and the relay agent as root.
# If either exits, the container exits so Railway restarts it.
set -eu
chown node:node /data
chmod 700 /data
rm -f /data/control.sock
env -u NOD_RELAY_TOKEN setpriv --reuid=node --regid=node --init-groups env HOME=/home/node node /app/worker.mjs &
worker=$!
node /opt/nod-relay/nod-relay-agent.mjs &
agent=$!
trap 'kill $worker $agent 2>/dev/null; exit 0' TERM INT
while kill -0 $worker 2>/dev/null && kill -0 $agent 2>/dev/null; do sleep 5; done
kill $worker $agent 2>/dev/null || true
exit 1
