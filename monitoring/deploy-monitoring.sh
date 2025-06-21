#!/bin/bash
# deploy-monitoring.sh - Deploy the monitoring stack for Free Compute Node

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages with colors
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
    error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if the freecompute network exists
if ! docker network inspect freecompute-network > /dev/null 2>&1; then
    error "The freecompute-network does not exist. Please deploy the main stack first."
    exit 1
fi

# Create data directories if they don't exist
MONITORING_DATA_DIR="/opt/freecompute-data/monitoring"
PROMETHEUS_DATA_DIR="$MONITORING_DATA_DIR/prometheus"
LOKI_DATA_DIR="$MONITORING_DATA_DIR/loki"
GRAFANA_DATA_DIR="$MONITORING_DATA_DIR/grafana"

mkdir -p "$PROMETHEUS_DATA_DIR" "$LOKI_DATA_DIR" "$GRAFANA_DATA_DIR"

# Set permissions
chmod -R 755 "$MONITORING_DATA_DIR"

# Create .env file for monitoring if it doesn't exist
MONITORING_ENV_FILE="$(dirname "$0")/../monitoring/.env"

if [ ! -f "$MONITORING_ENV_FILE" ]; then
    cat > "$MONITORING_ENV_FILE" << EOF
# Monitoring Configuration
PROMETHEUS_PORT=9090
LOKI_PORT=3100
GRAFANA_PORT=3000
CADVISOR_PORT=8081
GRAFANA_USER=admin
GRAFANA_PASSWORD=FreeCompute2024!Secure
NODE_NAME=freecompute-node
LOKI_ENABLED=true
EOF
    log "Created monitoring .env file at $MONITORING_ENV_FILE"
fi

# Deploy the monitoring stack
cd "$(dirname "$0")/../monitoring"
docker-compose up -d

log "✅ Monitoring stack deployed successfully!"
info "Grafana is available at http://localhost:3000"
info "Prometheus is available at http://localhost:9090"
info "Loki is available at http://localhost:3100"
info "cAdvisor is available at http://localhost:8081"
info "Default Grafana credentials: admin / FreeCompute2024!Secure"
warn "⚠️ IMPORTANT: Change the Grafana password after first login!"

# Create a script to rollback the monitoring stack
ROLLBACK_SCRIPT="/opt/freecompute-data/rollback-monitoring.sh"
cat > "$ROLLBACK_SCRIPT" << EOF
#!/bin/bash
# rollback-monitoring.sh - Rollback script for monitoring stack

echo "Rolling back monitoring stack..."
cd "$(pwd)"
docker-compose down -v
echo "Monitoring stack rolled back successfully!"
EOF

chmod +x "$ROLLBACK_SCRIPT"
log "✅ Created rollback script at $ROLLBACK_SCRIPT"
