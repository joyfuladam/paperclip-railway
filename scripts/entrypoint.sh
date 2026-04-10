#!/bin/sh
set -e
# When Railway mounts a volume at /paperclip it is often not writable by the node user.
# Create dirs Paperclip needs and ensure the whole tree is owned by node.
mkdir -p /paperclip/instances/default/logs
chown -R node:node /paperclip
# Preserve the hermes venv PATH so the node user can find the `hermes` binary.
export PATH="/opt/hermes-venv/bin:$PATH"

exec gosu node "$@"
