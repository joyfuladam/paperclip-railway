#!/bin/sh
set -e
# When Railway mounts a volume at /paperclip it is often not writable by the node user.
# Create dirs Paperclip needs and ensure the whole tree is owned by node.
mkdir -p /paperclip/instances/default/logs

# Seed Hermes config on first boot.
# HOME=/paperclip per Paperclip Dockerfile, so ~/.hermes == /paperclip/.hermes.
HERMES_HOME="/paperclip/.hermes"
mkdir -p "$HERMES_HOME"
chmod 700 "$HERMES_HOME"

# Write .env with ANTHROPIC_API_KEY if not already present.
HERMES_ENV="$HERMES_HOME/.env"
if [ ! -f "$HERMES_ENV" ] && [ -n "$ANTHROPIC_API_KEY" ]; then
  printf 'ANTHROPIC_API_KEY=%s\n' "$ANTHROPIC_API_KEY" > "$HERMES_ENV"
  chmod 600 "$HERMES_ENV"
fi

# Write config.yaml with Anthropic as default provider if not already present.
HERMES_CONFIG="$HERMES_HOME/config.yaml"
if [ ! -f "$HERMES_CONFIG" ]; then
  cat > "$HERMES_CONFIG" <<'YAML'
model:
  provider: "anthropic"
  default: "claude-sonnet-4-6"
YAML
fi

chown -R node:node /paperclip

# Preserve the hermes venv PATH so the node user can find the `hermes` binary.
export PATH="/opt/hermes-venv/bin:$PATH"

exec gosu node "$@"
