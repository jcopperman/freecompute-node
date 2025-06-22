#!/bin/bash
# deploy-production.sh - Safe deployment script for Free Compute Node on production server
# This script ensures safe deployment without interfering with existing services

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

# Function to check if a port is in use
check_port() {
    local port=$1
    local service_name=$2
    if ss -tuln | grep -q ":$port "; then
        error "Port $port is already in use by $service_name"
        return 1
    else
        log "Port $port is available"
        return 0
    fi
}

# Function to perform pre-flight checks
preflight_checks() {
    log "Performing pre-flight checks..."
    
    # Check if we're running as root or with sudo
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Check if we're in the right directory
    if [[ ! -f "docker-compose.yml" ]]; then
        error "Please run this script from the bootstrap directory"
        exit 1
    fi
    
    # Check for port conflicts
    log "Checking for port conflicts..."
    check_port 8080 "Free Compute Dashboard" || exit 1
    check_port 9002 "MinIO API" || exit 1
    check_port 9003 "MinIO Console" || exit 1
    check_port 11435 "Ollama API" || exit 1
    
    # Check if data directory already exists
    if [[ -d "/opt/freecompute-data" ]]; then
        warn "Data directory /opt/freecompute-data already exists"
        read -p "Do you want to backup and remove the existing data? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Creating backup of existing data..."
            sudo cp -r /opt/freecompute-data /opt/freecompute-data.backup.$(date +%Y%m%d_%H%M%S)
            sudo rm -rf /opt/freecompute-data
        else
            error "Deployment cancelled. Please handle existing data manually."
            exit 1
        fi
    fi
    
    log "Pre-flight checks completed successfully"
}

# Function to setup environment
setup_environment() {
    log "Setting up environment configuration..."
    
    # Copy production config to .env
    if [[ -f "env.production" ]]; then
        cp env.production .env
        log "Production configuration copied to .env"
    else
        error "Production configuration file (env.production) not found"
        exit 1
    fi
    
    # Create data directory with proper permissions
    log "Creating data directory..."
    sudo mkdir -p /opt/freecompute-data
    sudo chown $(whoami):$(whoami) /opt/freecompute-data
    sudo chmod 755 /opt/freecompute-data
    
    log "Environment setup completed"
}

# Function to deploy services
deploy_services() {
    log "Deploying Free Compute Node services..."
    
    # Make scripts executable
    chmod +x install.sh register-node.sh
    
    # Run the installation script
    log "Running installation script..."
    ./install.sh
    
    log "Services deployed successfully"
}

# Function to verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Wait a moment for services to start
    sleep 10
    
    # Check if containers are running
    if docker ps | grep -q "freecompute-nginx"; then
        log "✓ Nginx container is running"
    else
        error "✗ Nginx container is not running"
        return 1
    fi
    
    if docker ps | grep -q "freecompute-minio"; then
        log "✓ MinIO container is running"
    else
        error "✗ MinIO container is not running"
        return 1
    fi
    
    # Test dashboard access
    if curl -s -f http://localhost:8080 >/dev/null; then
        log "✓ Dashboard is accessible at http://localhost:8080"
    else
        warn "✗ Dashboard may not be accessible yet (retrying in 30 seconds)"
        sleep 30
        if curl -s -f http://localhost:8080 >/dev/null; then
            log "✓ Dashboard is now accessible at http://localhost:8080"
        else
            error "✗ Dashboard is not accessible"
            return 1
        fi
    fi
    
    # Test MinIO console access
    if curl -s -f http://localhost:9003 >/dev/null; then
        log "✓ MinIO Console is accessible at http://localhost:9003"
    else
        warn "✗ MinIO Console may not be accessible yet"
    fi
    
    log "Deployment verification completed"
}

# Function to display access information
display_access_info() {
    echo
    log "=== FREE COMPUTE NODE DEPLOYMENT COMPLETE ==="
    echo
    info "Access your Free Compute Node services at:"
    echo "  • Dashboard: http://localhost:8080"
    echo "  • MinIO API: http://localhost:9002"
    echo "  • MinIO Console: http://localhost:9003"
    echo "  • Ollama API: http://localhost:11435 (if enabled)"
    echo
    info "MinIO Console Credentials:"
    echo "  • Username: admin"
    echo "  • Password: FreeCompute2024!Secure"
    echo
    info "Data Storage Location:"
    echo "  • /opt/freecompute-data"
    echo
    warn "IMPORTANT: Change the MinIO password after first login!"
    echo
}

# Function to create rollback script
create_rollback_script() {
    log "Creating rollback script..."
    
    cat > rollback-freecompute.sh << 'EOF'
#!/bin/bash
# rollback-freecompute.sh - Rollback script for Free Compute Node deployment

set -e

echo "=== FREE COMPUTE NODE ROLLBACK ==="
echo "This will completely remove the Free Compute Node deployment"
echo

read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Rollback cancelled"
    exit 0
fi

echo "Stopping and removing containers..."
cd "$(dirname "$0")"
docker-compose down -v

echo "Removing data directory..."
sudo rm -rf /opt/freecompute-data

echo "Removing Docker network..."
docker network rm freecompute-network 2>/dev/null || true

echo "Rollback completed successfully"
echo "Note: If you had a backup at /opt/freecompute-data.backup.*, you can restore it manually"
EOF

    chmod +x rollback-freecompute.sh
    log "Rollback script created: rollback-freecompute.sh"
}

# Main deployment process
main() {
    echo "=== FREE COMPUTE NODE - PRODUCTION DEPLOYMENT ==="
    echo "This script will safely deploy Free Compute Node on your production server"
    echo "with non-conflicting ports and isolated data storage."
    echo
    
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled"
        exit 0
    fi
    
    # Run deployment steps
    preflight_checks
    setup_environment
    deploy_services
    verify_deployment
    create_rollback_script
    display_access_info
    
    log "Deployment completed successfully!"
    log "To rollback, run: ./rollback-freecompute.sh"
}

# Run main function
main 