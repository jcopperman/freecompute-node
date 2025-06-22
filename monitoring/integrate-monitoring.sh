#!/bin/bash

# Script to integrate the monitoring stack with the full FreeCompute Node stack

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the base directory of the project
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
BOOTSTRAP_DIR="$BASE_DIR/bootstrap"

echo -e "${YELLOW}Starting FreeCompute Node Monitoring Integration...${NC}"

# Step 1: Copy monitoring configurations to the bootstrap directory
echo -e "${GREEN}Copying monitoring configurations to bootstrap directory...${NC}"
mkdir -p "$BOOTSTRAP_DIR/monitoring/prometheus"
mkdir -p "$BOOTSTRAP_DIR/monitoring/loki"
mkdir -p "$BOOTSTRAP_DIR/monitoring/promtail"
mkdir -p "$BOOTSTRAP_DIR/monitoring/grafana/provisioning/dashboards"
mkdir -p "$BOOTSTRAP_DIR/monitoring/grafana/provisioning/datasources"

# Copy configuration files
cp "$SCRIPT_DIR/prometheus/prometheus.yml" "$BOOTSTRAP_DIR/monitoring/prometheus/"
cp "$SCRIPT_DIR/loki/loki-config.yml" "$BOOTSTRAP_DIR/monitoring/loki/"
cp "$SCRIPT_DIR/promtail/promtail-config.yml" "$BOOTSTRAP_DIR/monitoring/promtail/"
cp "$SCRIPT_DIR/grafana/provisioning/dashboards/"*.* "$BOOTSTRAP_DIR/monitoring/grafana/provisioning/dashboards/"
cp "$SCRIPT_DIR/grafana/provisioning/datasources/"*.* "$BOOTSTRAP_DIR/monitoring/grafana/provisioning/datasources/"

# Step 2: Create data directories with correct permissions
echo -e "${GREEN}Creating data directories with correct permissions...${NC}"
mkdir -p "$BOOTSTRAP_DIR/data/prometheus"
mkdir -p "$BOOTSTRAP_DIR/data/loki"
mkdir -p "$BOOTSTRAP_DIR/data/grafana"

# Set correct permissions
chmod -R 777 "$BOOTSTRAP_DIR/data/loki"
chmod -R 777 "$BOOTSTRAP_DIR/data/prometheus"
chmod -R 777 "$BOOTSTRAP_DIR/data/grafana"

# Step 3: Create a monitoring section in the docker-compose.yml
echo -e "${GREEN}Creating monitoring section in docker-compose.yml...${NC}"
cat << 'EOF' > "$BOOTSTRAP_DIR/monitoring-section.yml"
  # Monitoring Stack
  prometheus:
    image: prom/prometheus:latest
    container_name: freecompute-prometheus
    restart: unless-stopped
    ports:
      - "${PROMETHEUS_PORT:-9090}:9090"
    volumes:
      - ./monitoring/prometheus:/etc/prometheus
      - ./data/prometheus:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
    networks:
      - freecompute
    labels:
      - "freecompute.service=prometheus"
      - "freecompute.node=${NODE_NAME:-freecompute-node}"

  loki:
    image: grafana/loki:2.9.3
    container_name: freecompute-loki
    restart: unless-stopped
    ports:
      - "3100:3100"
    volumes:
      - ./monitoring/loki:/etc/loki
      - ./data/loki:/loki
    command: -config.file=/etc/loki/loki-config.yml
    networks:
      - freecompute
    labels:
      - "freecompute.service=loki"
      - "freecompute.node=${NODE_NAME:-freecompute-node}"

  grafana:
    image: grafana/grafana:latest
    container_name: freecompute-grafana
    restart: unless-stopped
    ports:
      - "${GRAFANA_PORT:-3000}:3000"
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
      - ./data/grafana:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_USER:-admin}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD:-FreeCompute2024!Secure}
      - GF_USERS_ALLOW_SIGN_UP=false
    networks:
      - freecompute
    labels:
      - "freecompute.service=grafana"
      - "freecompute.node=${NODE_NAME:-freecompute-node}"
    depends_on:
      - prometheus
      - loki

  promtail:
    image: grafana/promtail:2.9.3
    container_name: freecompute-promtail
    restart: unless-stopped
    volumes:
      - ./monitoring/promtail:/etc/promtail
      - /var/log:/var/log
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command: -config.file=/etc/promtail/promtail-config.yml
    networks:
      - freecompute
    labels:
      - "freecompute.service=promtail"
      - "freecompute.node=${NODE_NAME:-freecompute-node}"
    depends_on:
      - loki

  node-exporter:
    image: prom/node-exporter:latest
    container_name: freecompute-node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
      - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - "9100:9100"
    networks:
      - freecompute
    labels:
      - "freecompute.service=node-exporter"
      - "freecompute.node=${NODE_NAME:-freecompute-node}"
EOF

echo -e "${GREEN}Successfully prepared monitoring integration.${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Add the monitoring section to your docker-compose.yml"
echo -e "2. Update the router and nginx configurations to work with the monitoring stack"
echo -e "3. Start the full stack with 'docker-compose up -d'"

echo -e "\n${YELLOW}Would you like to automatically integrate the monitoring section into docker-compose.yml? (y/n)${NC}"
read -p "> " AUTO_INTEGRATE

if [[ $AUTO_INTEGRATE == "y" ]]; then
  # Check if monitoring services are already present
  MONITORING_SERVICES=("prometheus" "loki" "grafana" "promtail" "node-exporter")
  SERVICES_EXIST=false
  
  for service in "${MONITORING_SERVICES[@]}"; do
    if grep -q "^  $service:" "$BOOTSTRAP_DIR/docker-compose.yml"; then
      SERVICES_EXIST=true
      echo -e "${YELLOW}Monitoring services already exist in docker-compose.yml${NC}"
      break
    fi
  done
  
  if [[ "$SERVICES_EXIST" == "true" ]]; then
    echo -e "${YELLOW}Would you like to run the cleanup script to remove any duplicate services? (y/n)${NC}"
    read -p "> " RUN_CLEANUP
    
    if [[ "$RUN_CLEANUP" == "y" ]]; then
      echo -e "${GREEN}Running cleanup script...${NC}"
      bash "$SCRIPT_DIR/cleanup-compose.sh"
      
      # Double-check if all duplicates were removed
      DUPLICATES_REMAIN=false
      for service in "${MONITORING_SERVICES[@]}"; do
        SERVICE_COUNT=$(grep -c "^  $service:" "$BOOTSTRAP_DIR/docker-compose.yml")
        if [[ $SERVICE_COUNT -gt 1 ]]; then
          DUPLICATES_REMAIN=true
          break
        fi
      done
      
      if [[ "$DUPLICATES_REMAIN" == "true" ]]; then
        echo -e "${RED}Warning: Some duplicate services remain in docker-compose.yml${NC}"
        echo -e "${YELLOW}Skipping integration to avoid further duplicates. Please manually review your docker-compose.yml${NC}"
        exit 1
      fi
      
      # Check if user wants to continue with integration
      echo -e "${YELLOW}Would you like to continue with integration? (y/n)${NC}"
      read -p "> " CONTINUE_INTEGRATION
      
      if [[ "$CONTINUE_INTEGRATION" != "y" ]]; then
        echo -e "${YELLOW}Integration skipped. Your docker-compose.yml has been cleaned up.${NC}"
        exit 0
      fi
    else
      echo -e "${YELLOW}Skipping integration to avoid duplicates. Please manually review your docker-compose.yml${NC}"
      exit 0
    fi
  fi
  
  echo -e "${GREEN}Backing up current docker-compose.yml...${NC}"
  cp "$BOOTSTRAP_DIR/docker-compose.yml" "$BOOTSTRAP_DIR/docker-compose.yml.bak.$(date +%Y%m%d%H%M%S)"
  
  echo -e "${GREEN}Integrating monitoring section into docker-compose.yml...${NC}"
  
  # Check if "End of services" marker exists
  if grep -q "# End of services" "$BOOTSTRAP_DIR/docker-compose.yml"; then
    # Add before the "End of services" marker
    sed -i '/# End of services/i # MONITORING SECTION ADDED\n' "$BOOTSTRAP_DIR/docker-compose.yml"
    sed -i '/# MONITORING SECTION ADDED/r '"$BOOTSTRAP_DIR/monitoring-section.yml" "$BOOTSTRAP_DIR/docker-compose.yml"
  else
    # Add before the networks section
    sed -i '/^networks:/i # End of services\n\n# MONITORING SECTION ADDED\n' "$BOOTSTRAP_DIR/docker-compose.yml"
    sed -i '/# MONITORING SECTION ADDED/r '"$BOOTSTRAP_DIR/monitoring-section.yml" "$BOOTSTRAP_DIR/docker-compose.yml"
  fi
  
  echo -e "${GREEN}Integration complete!${NC}"
  echo -e "${YELLOW}Please review the docker-compose.yml file before starting the stack.${NC}"
else
  echo -e "${YELLOW}Please manually integrate the monitoring section from monitoring-section.yml into your docker-compose.yml file.${NC}"
fi
