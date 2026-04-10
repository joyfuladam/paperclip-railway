#!/bin/sh
set -e
# When Railway mounts a volume at /paperclip it is often not writable by the node user.
# Create dirs Paperclip needs and ensure the whole tree is owned by node.
mkdir -p /paperclip/instances/default/logs

HERMES_VENV="/paperclip/hermes-venv"
HERMES_HOME="/paperclip/.hermes"

# Seed Hermes config directory now (fast, blocking — just mkdir + file writes).
mkdir -p "$HERMES_HOME"
chmod 700 "$HERMES_HOME"

if [ ! -f "$HERMES_HOME/.env" ] && [ -n "$ANTHROPIC_API_KEY" ]; then
  printf 'ANTHROPIC_API_KEY=%s\n' "$ANTHROPIC_API_KEY" > "$HERMES_HOME/.env"
  chmod 600 "$HERMES_HOME/.env"
fi

if [ ! -f "$HERMES_HOME/config.yaml" ]; then
  cat > "$HERMES_HOME/config.yaml" <<'YAML'
model:
  provider: "anthropic"
  default: "claude-sonnet-4-6"
YAML
fi

# Fix volume ownership.
chown -R node:node /paperclip

# Install hermes-agent in the background so the server starts immediately.
# pip install takes ~2-4 min; it completes on the volume before any agent runs.
if [ ! -f "$HERMES_VENV/bin/hermes" ]; then
  echo "[entrypoint] Starting hermes-agent background install into $HERMES_VENV..."
  (python3 -m venv "$HERMES_VENV" \
    && "$HERMES_VENV/bin/pip" install --no-cache-dir --quiet hermes-agent \
    && chown -R node:node "$HERMES_VENV" \
    && echo "[entrypoint] hermes-agent install complete.") &
fi

export PATH="$HERMES_VENV/bin:$PATH"

exec gosu node "$@"
