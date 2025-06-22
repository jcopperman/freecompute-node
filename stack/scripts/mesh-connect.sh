#!/bin/bash
# mesh-connect.sh - Connect to another Free Compute Node

set -e

# Function to log messages
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check if arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <node-url> <node-name> [capabilities]"
    echo "Example: $0 http://192.168.1.100:3000 homelab-node storage,compute"
    exit 1
fi

NODE_URL=$1
NODE_NAME=$2
CAPABILITIES=${3:-""}

# Load environment from .env file
source .env

# Set default values
ROUTER_PORT=${ROUTER_PORT:-3000}
ROUTER_AUTH_KEY=${ROUTER_AUTH_KEY:-change_this_key}
LOCAL_NODE_NAME=${NODE_NAME:-freecompute-node}

log "Connecting to remote node: $NODE_NAME at $NODE_URL"

# Register with remote node
REMOTE_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $ROUTER_AUTH_KEY" \
    -d "{\"nodeUrl\":\"http://$(hostname -I | awk '{print $1}'):$ROUTER_PORT\",\"nodeName\":\"$LOCAL_NODE_NAME\",\"capabilities\":\"$CAPABILITIES\"}" \
    "$NODE_URL/api/mesh/register")

log "Remote node response: $REMOTE_RESPONSE"

# Register remote node with local node
LOCAL_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $ROUTER_AUTH_KEY" \
    -d "{\"nodeUrl\":\"$NODE_URL\",\"nodeName\":\"$NODE_NAME\",\"capabilities\":\"$CAPABILITIES\"}" \
    "http://localhost:$ROUTER_PORT/api/mesh/register")

log "Local node response: $LOCAL_RESPONSE"

log "Mesh connection established between $LOCAL_NODE_NAME and $NODE_NAME"
log "You can now access services across both nodes"
