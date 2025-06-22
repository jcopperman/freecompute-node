#!/bin/bash
# update-mesh.sh - Update mesh configuration and sync with other nodes

set -e

# Function to log messages
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Load environment from .env file
if [ -f "../bootstrap/.env" ]; then
  source ../bootstrap/.env
else
  log "ERROR: .env file not found"
  exit 1
fi

# Set default values
ROUTER_PORT=${ROUTER_PORT:-3000}
ROUTER_AUTH_KEY=${ROUTER_AUTH_KEY:-change_this_key}
MESH_ENABLED=${MESH_ENABLED:-false}

if [ "$MESH_ENABLED" != "true" ]; then
  log "Mesh federation is disabled in .env. Set MESH_ENABLED=true to enable."
  exit 0
fi

log "Updating mesh configuration..."

# Get the current node info
NODE_INFO=$(curl -s -H "X-API-Key: $ROUTER_AUTH_KEY" "http://localhost:$ROUTER_PORT/api/node/info")
NODE_NAME=$(echo $NODE_INFO | grep -o '"name":"[^"]*' | cut -d'"' -f4)

log "Current node: $NODE_NAME"

# Get all registered nodes
NODES=$(curl -s -H "X-API-Key: $ROUTER_AUTH_KEY" "http://localhost:$ROUTER_PORT/api/mesh/nodes")
NODE_COUNT=$(echo $NODES | grep -o '"url"' | wc -l)

log "Connected nodes: $NODE_COUNT"

# Create or update mesh.json file
if [ -f "mesh.json" ]; then
  # Update existing file
  log "Updating existing mesh.json file"
  TMP_FILE=$(mktemp)
  jq --arg lastUpdated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" '.lastUpdated = $lastUpdated' mesh.json > $TMP_FILE
  mv $TMP_FILE mesh.json
else
  # Create new file
  log "Creating new mesh.json file"
  echo '{
    "meshName": "FreeCompute Mesh",
    "meshVersion": "0.1.0",
    "lastUpdated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
    "nodes": [],
    "routes": [],
    "policies": {
      "storage": {
        "replication": 1
      },
      "ai": {},
      "compute": {
        "loadBalancing": "round-robin"
      }
    }
  }' > mesh.json
fi

log "Mesh configuration updated successfully"

# Optional: Sync with hub node if configured
if [ -n "$MESH_HUB" ] && [ -n "$MESH_TOKEN" ]; then
  log "Syncing with mesh hub: $MESH_HUB"
  
  HUB_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MESH_TOKEN" \
    -d @mesh.json \
    "$MESH_HUB/api/mesh/sync")
  
  log "Hub response: $HUB_RESPONSE"
fi

log "Mesh update completed"
