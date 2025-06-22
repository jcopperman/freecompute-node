#!/bin/bash

# Script to clean up duplicate monitoring services in docker-compose.yml

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Enable debug mode if requested
if [[ "$1" == "--debug" ]]; then
  set -x
  DEBUG=true
else
  DEBUG=false
fi

# Define base directory using relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_DIR="${BASE_DIR}/bootstrap"
COMPOSE_FILE="${BOOTSTRAP_DIR}/docker-compose.yml"
TEMP_FILE="${BOOTSTRAP_DIR}/docker-compose.yml.tmp"
BACKUP_FILE="${BOOTSTRAP_DIR}/docker-compose.yml.bak.$(date +%Y%m%d%H%M%S)"

echo -e "${YELLOW}Starting docker-compose.yml cleanup...${NC}"

# Check if docker-compose.yml exists
if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo -e "${RED}Error: docker-compose.yml not found at $COMPOSE_FILE${NC}"
  exit 1
fi

# Create a backup of the original file
echo -e "${GREEN}Backing up current docker-compose.yml to $BACKUP_FILE...${NC}"
cp "$COMPOSE_FILE" "$BACKUP_FILE"

# Define monitoring services to look for
MONITORING_SERVICES=(
  "prometheus"
  "loki"
  "grafana"
  "promtail"
  "node-exporter"
  "cadvisor"
  "nginx-exporter"
)

# Create a temporary file
cat "$COMPOSE_FILE" > "$TEMP_FILE"

# Initialize variables
DUPLICATE_FOUND=false

echo -e "${YELLOW}Checking for duplicate monitoring services...${NC}"

# Process each monitoring service
for service in "${MONITORING_SERVICES[@]}"; do
  # Count occurrences of the service
  SERVICE_COUNT=$(grep -c "^  $service:" "$TEMP_FILE")
  
  if [[ $SERVICE_COUNT -gt 1 ]]; then
    DUPLICATE_FOUND=true
    echo -e "${YELLOW}Found $SERVICE_COUNT instances of $service service. Removing duplicates...${NC}"
    
    # Create a new temp file with only the first occurrence of each service
    awk -v service="  $service:" '
    BEGIN { skip=false; found=false; }
    {
      if ($0 ~ "^" service) {
        if (found) {
          skip=true;
        } else {
          found=true;
          skip=false;
          print;
        }
      } 
      else if (skip && ($0 ~ /^  [a-zA-Z0-9_-]+:/ || $0 ~ /^networks:/)) {
        # We reached the next service or networks section, stop skipping
        skip=false;
        if ($0 !~ /^networks:/) {
          print;
        } else {
          print;
        }
      }
      else if (!skip) {
        print;
      }
    }' "$TEMP_FILE" > "${TEMP_FILE}.new"
    
    mv "${TEMP_FILE}.new" "$TEMP_FILE"
  elif $DEBUG; then
    echo -e "${GREEN}No duplicates found for $service service${NC}"
  fi
done

# Check for repeated MONITORING SECTION ADDED comments
SECTION_COUNT=$(grep -c "# MONITORING SECTION ADDED" "$TEMP_FILE")
if [[ $SECTION_COUNT -gt 1 ]]; then
  DUPLICATE_FOUND=true
  echo -e "${YELLOW}Found $SECTION_COUNT monitoring section markers. Removing duplicates...${NC}"
  
  # Keep only the first monitoring section marker
  awk '
  BEGIN { seen=0; }
  {
    if ($0 ~ /# MONITORING SECTION ADDED/) {
      if (seen == 0) {
        seen=1;
        print;
      }
    } else {
      print;
    }
  }' "$TEMP_FILE" > "${TEMP_FILE}.new"
  
  mv "${TEMP_FILE}.new" "$TEMP_FILE"
fi

# Ensure there's only one "End of services" comment
END_SERVICES_COUNT=$(grep -c "# End of services" "$TEMP_FILE")
if [[ $END_SERVICES_COUNT -gt 1 ]]; then
  DUPLICATE_FOUND=true
  echo -e "${YELLOW}Found $END_SERVICES_COUNT 'End of services' markers. Removing duplicates...${NC}"
  
  # Keep only the last "End of services" marker
  awk '
  {
    if ($0 ~ /# End of services/) {
      line = $0;
      next;
    } else {
      if (line != "") {
        print line;
        line = "";
      }
      print;
    }
  }
  END {
    if (line != "") print line;
  }' "$TEMP_FILE" > "${TEMP_FILE}.new"
  
  mv "${TEMP_FILE}.new" "$TEMP_FILE"
fi

# Apply changes if duplicates were found
if $DUPLICATE_FOUND; then
  echo -e "${GREEN}Applying changes to docker-compose.yml${NC}"
  mv "$TEMP_FILE" "$COMPOSE_FILE"
  echo -e "${GREEN}Duplicate services removed successfully!${NC}"
else
  echo -e "${GREEN}No duplicate services found. No changes needed.${NC}"
  rm "$TEMP_FILE"
fi

echo -e "${GREEN}Cleanup complete!${NC}"
