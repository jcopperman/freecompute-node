#!/bin/bash
# install.sh - Setup script for Free Compute Node
# This script installs and configures all necessary components

set -e

# Function to log messages
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to prompt for .env creation if it doesn't exist
setup_env_file() {
  if [ ! -f .env ]; then
    if [ -f .env.example ]; then
      log "Creating .env file from example..."
      cp .env.example .env
      log "Please edit the .env file with your configuration"
      log "Then run this script again"
      exit 0
    else
      log "ERROR: .env.example file not found"
      exit 1
    fi
  fi
}

# Function to install Docker and Docker Compose
install_docker() {
  if ! command_exists docker; then
    log "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    usermod -aG docker "$(whoami)"
    log "Docker installed successfully"
  else
    log "Docker already installed"
  fi

  # Check for Docker Compose (either standalone or plugin)
  if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
    log "Installing Docker Compose..."
    mkdir -p ~/.docker/cli-plugins/
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o ~/.docker/cli-plugins/docker-compose
    chmod +x ~/.docker/cli-plugins/docker-compose
    log "Docker Compose installed successfully"
  else
    log "Docker Compose already installed"
  fi
}

# Function to install and configure Tailscale
install_tailscale() {
  # Source .env again in case we just created it
  source .env

  if ! command_exists tailscale; then
    log "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    log "Tailscale installed successfully"
  else
    log "Tailscale already installed"
  fi

  # Check if Tailscale auth key is provided and authenticate if needed
  if [ -n "${TAILSCALE_AUTH_KEY}" ]; then
    if ! tailscale status >/dev/null 2>&1; then
      log "Authenticating Tailscale with provided auth key..."
      tailscale up --authkey="${TAILSCALE_AUTH_KEY}" \
                  --hostname="${TAILSCALE_HOSTNAME:-freecompute-node}" \
                  ${TAILSCALE_TAGS:+--advertise-tags="${TAILSCALE_TAGS}"}
      log "Tailscale authenticated successfully"
    else
      log "Tailscale already authenticated"
    fi
  else
    log "WARNING: No Tailscale auth key provided in .env file"
    log "Tailscale authentication skipped"
  fi
}

# Function to create required directories
create_directories() {
  source .env
  
  # Create data root directory
  DATA_ROOT=${DATA_ROOT:-/data}
  log "Creating data directory: $DATA_ROOT"
  mkdir -p "$DATA_ROOT"
  
  # Create service-specific directories
  if [ "${MINIO_ENABLED:-true}" != "false" ]; then
    MINIO_DATA_DIR=${MINIO_DATA_DIR:-$DATA_ROOT/minio}
    log "Creating MinIO data directory: $MINIO_DATA_DIR"
    mkdir -p "$MINIO_DATA_DIR"
  fi
  
  if [ "${OLLAMA_ENABLED:-true}" != "false" ]; then
    OLLAMA_DATA_DIR=${OLLAMA_DATA_DIR:-$DATA_ROOT/ollama}
    log "Creating Ollama data directory: $OLLAMA_DATA_DIR"
    mkdir -p "$OLLAMA_DATA_DIR"
  fi
}

# Function to start services with Docker Compose
start_services() {
  source .env
  
  log "Starting services with Docker Compose..."
  
  # Build profile list based on enabled services
  PROFILES=""
  
  if [ "${MINIO_ENABLED:-true}" != "false" ]; then
    log "MinIO service enabled"
  else
    log "MinIO service disabled"
  fi
  
  if [ "${OLLAMA_ENABLED:-true}" != "false" ]; then
    log "Ollama service enabled"
    
    # If Ollama is enabled and a model is specified, pull it
    if [ -n "${OLLAMA_MODEL}" ]; then
      log "Will pull Ollama model: ${OLLAMA_MODEL} after services start"
    fi
  else
    log "Ollama service disabled"
  fi
  
  # Start the services
  docker-compose up -d
  
  # Pull Ollama model if specified
  if [ "${OLLAMA_ENABLED:-true}" != "false" ] && [ -n "${OLLAMA_MODEL}" ]; then
    log "Pulling Ollama model: ${OLLAMA_MODEL}..."
    sleep 5  # Give Ollama a moment to start up
    docker exec freecompute-ollama ollama pull "${OLLAMA_MODEL}"
    log "Ollama model ${OLLAMA_MODEL} pulled successfully"
  fi
}

# Main installation process
main() {
  log "Starting Free Compute Node installation..."
  
  # Make sure we're in the right directory
  cd "$(dirname "$0")" || exit 1
  
  # Check for .env file or create from example
  setup_env_file
  
  # Source the .env file
  source .env
  
  # Install prerequisites
  install_docker
  
  # Create required directories
  create_directories
  
  # Install and configure Tailscale
  install_tailscale
  
  # Start services
  start_services
  
  # Register node information
  if [ -x ./register-node.sh ]; then
    log "Registering node information..."
    ./register-node.sh
  else
    log "Making register-node.sh executable..."
    chmod +x ./register-node.sh
    log "Registering node information..."
    ./register-node.sh
  fi
  
  log "Installation complete!"
  log "You can access your Free Compute Node services at:"
  
  # Display access information
  if [ "${MINIO_ENABLED:-true}" != "false" ]; then
    log "- MinIO API: http://localhost:${MINIO_PORT:-9000}"
    log "- MinIO Console: http://localhost:${MINIO_CONSOLE_PORT:-9001}"
  fi
  
  if [ "${OLLAMA_ENABLED:-true}" != "false" ]; then
    log "- Ollama API: http://localhost:${OLLAMA_PORT:-11434}"
  fi
  
  # Get Tailscale IP if available
  if command_exists tailscale && tailscale status >/dev/null 2>&1; then
    TAILSCALE_IP=$(tailscale ip -4)
    log "Your node is accessible on the Tailscale network at: $TAILSCALE_IP"
  fi
}

# Run main function
main
