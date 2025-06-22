#!/bin/bash
# update-status.sh - Updates dashboard status.json with real system information

set -e

# Load environment variables
if [ -f /app/.env ]; then
  source /app/.env
else
  echo "Warning: .env file not found, using default values"
fi

# Set defaults for any missing variables
NODE_NAME=${NODE_NAME:-"freecompute-node"}
NODE_ROLE=${NODE_ROLE:-"general"}
NGINX_PORT=${NGINX_PORT:-80}
MINIO_ENABLED=${MINIO_ENABLED:-true}
MINIO_PORT=${MINIO_PORT:-9000}
MINIO_CONSOLE_PORT=${MINIO_CONSOLE_PORT:-9001}
OLLAMA_ENABLED=${OLLAMA_ENABLED:-false}
OLLAMA_PORT=${OLLAMA_PORT:-11434}

# Get system information
UPTIME=$(uptime -p)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')"%"
MEMORY_TOTAL=$(free -h | grep Mem | awk '{print $2}')
MEMORY_USED=$(free -h | grep Mem | awk '{print $3}')
MEMORY_USAGE="$MEMORY_USED / $MEMORY_TOTAL"
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_USAGE="$DISK_USED / $DISK_TOTAL"

# Get network information
LAN_IP=$(hostname -I | awk '{print $1}')
TAILSCALE_CONNECTED=false
TAILSCALE_IP=""

if command -v tailscale >/dev/null 2>&1; then
  if tailscale status >/dev/null 2>&1; then
    TAILSCALE_CONNECTED=true
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
  fi
fi

# Check services status
check_service() {
  local service_name=$1
  local container_name="freecompute-$service_name"
  
  if docker ps --format '{{.Names}}' | grep -q "^$container_name$"; then
    echo "active"
  else
    echo "inactive"
  fi
}

MINIO_STATUS=$(check_service "minio")
OLLAMA_STATUS=$(check_service "ollama")
NGINX_STATUS=$(check_service "nginx")

# Get Ollama models if available
OLLAMA_MODELS="[]"
if [ "$OLLAMA_STATUS" = "active" ]; then
  if docker exec freecompute-ollama ollama list >/dev/null 2>&1; then
    OLLAMA_MODELS=$(docker exec freecompute-ollama ollama list -j | jq '[.[].name]')
  fi
fi

# Create the status JSON
cat > /app/html/status.json << EOF
{
  "node": {
    "name": "$NODE_NAME",
    "role": "$NODE_ROLE",
    "version": "0.1.0",
    "uptime": "$UPTIME",
    "lastUpdated": "$TIMESTAMP"
  },
  "services": {
    "nginx": {
      "status": "$NGINX_STATUS",
      "port": $NGINX_PORT,
      "url": "/"
    },
    "minio": {
      "status": "$MINIO_STATUS",
      "port": $MINIO_PORT,
      "consolePort": $MINIO_CONSOLE_PORT,
      "url": "/minio/"
    },
    "ollama": {
      "status": "$OLLAMA_STATUS",
      "port": $OLLAMA_PORT,
      "url": "/ollama/",
      "models": $OLLAMA_MODELS
    }
  },
  "resources": {
    "cpu": "$CPU_USAGE",
    "memory": "$MEMORY_USAGE",
    "disk": "$DISK_USAGE"
  },
  "network": {
    "tailscale": {
      "connected": $TAILSCALE_CONNECTED,
      "ip": "$TAILSCALE_IP"
    },
    "lan": {
      "ip": "$LAN_IP"
    }
  }
}
EOF

echo "Status updated at $TIMESTAMP"
