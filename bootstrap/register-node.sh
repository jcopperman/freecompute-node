#!/bin/bash
# register-node.sh - Records node information for the Free Compute Network

set -e

# Load environment variables
if [ -f .env ]; then
  source .env
else
  echo "Error: .env file not found"
  echo "Please copy .env.example to .env and configure it"
  exit 1
fi

# Create info directory if it doesn't exist
INFO_DIR="${DATA_ROOT:-/data}/node-info"
mkdir -p "$INFO_DIR"
NODE_INFO_FILE="$INFO_DIR/node-info.txt"

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get Tailscale IP if available
if command -v tailscale >/dev/null 2>&1; then
  TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "Not connected")
else
  TAILSCALE_IP="Tailscale not installed"
fi

# Get system information
HOSTNAME=${TAILSCALE_HOSTNAME:-$(hostname)}
CPU_INFO=$(grep "model name" /proc/cpuinfo | head -1 | cut -d ':' -f2 | sed 's/^[ \t]*//')
MEMORY_TOTAL=$(free -h | grep Mem | awk '{print $2}')
DISK_SPACE=$(df -h ${DATA_ROOT:-/data} | awk 'NR==2 {print $2}')

# Check for required variables and set defaults
NODE_NAME=${NODE_NAME:-"unnamed-node"}
NODE_ROLE=${NODE_ROLE:-"unspecified"}
NODE_TIMEZONE=${NODE_TIMEZONE:-$(timedatectl show --property=Timezone --value 2>/dev/null || echo "unknown")}

# Write to node info file
cat > "$NODE_INFO_FILE" << EOF
# Free Compute Node Information
# Last updated: $TIMESTAMP

NODE_NAME=$NODE_NAME
NODE_ROLE=$NODE_ROLE
NODE_TIMEZONE=$NODE_TIMEZONE
HOSTNAME=$HOSTNAME
TAILSCALE_IP=$TAILSCALE_IP

# Hardware Information
CPU=$CPU_INFO
MEMORY=$MEMORY_TOTAL
DISK_SPACE=$DISK_SPACE

# Running Services
EOF

# Add running services info
if docker ps &>/dev/null; then
  echo "# Docker containers running:" >> "$NODE_INFO_FILE"
  docker ps --format "# - {{.Names}} ({{.Image}})" >> "$NODE_INFO_FILE"
else
  echo "# Docker not running or not installed" >> "$NODE_INFO_FILE"
fi

echo -e "\nNode information saved to $NODE_INFO_FILE"
echo "Node registered as: $NODE_NAME (Role: $NODE_ROLE)"
echo "Tailscale IP: $TAILSCALE_IP"

# Optional: Send registration to a central repository if specified
if [ -n "$REGISTER_URL" ]; then
  echo "Sending registration to $REGISTER_URL..."
  # This is where you would implement sending the data to a central repository
  # Example using curl (commented out for now):
  # curl -s -X POST -d @"$NODE_INFO_FILE" "$REGISTER_URL"
fi

exit 0
