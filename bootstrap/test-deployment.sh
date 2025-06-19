#!/bin/bash
# test-deployment.sh - Test script for Free Compute Node deployment
# This script tests each component individually for troubleshooting

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

# Function to test port connectivity
test_port() {
    local port=$1
    local service_name=$2
    local url=$3
    
    echo "Testing $service_name on port $port..."
    
    if curl -s -f --connect-timeout 5 "$url" >/dev/null; then
        log "✓ $service_name is accessible at $url"
        return 0
    else
        error "✗ $service_name is not accessible at $url"
        return 1
    fi
}

# Function to test Docker containers
test_containers() {
    echo "Testing Docker containers..."
    
    local containers=("freecompute-nginx" "freecompute-minio")
    local all_running=true
    
    for container in "${containers[@]}"; do
        if docker ps | grep -q "$container"; then
            log "✓ Container $container is running"
        else
            error "✗ Container $container is not running"
            all_running=false
        fi
    done
    
    if [[ "$all_running" == "true" ]]; then
        log "✓ All containers are running"
        return 0
    else
        error "✗ Some containers are not running"
        return 1
    fi
}

# Function to test data directories
test_data_directories() {
    echo "Testing data directories..."
    
    local data_root="/opt/freecompute-data"
    local minio_data="$data_root/minio"
    
    if [[ -d "$data_root" ]]; then
        log "✓ Data root directory exists: $data_root"
    else
        error "✗ Data root directory does not exist: $data_root"
        return 1
    fi
    
    if [[ -d "$minio_data" ]]; then
        log "✓ MinIO data directory exists: $minio_data"
    else
        error "✗ MinIO data directory does not exist: $minio_data"
        return 1
    fi
    
    # Check permissions
    if [[ -w "$data_root" ]]; then
        log "✓ Data root directory is writable"
    else
        error "✗ Data root directory is not writable"
        return 1
    fi
    
    log "✓ All data directories are properly configured"
    return 0
}

# Function to test MinIO functionality
test_minio() {
    echo "Testing MinIO functionality..."
    
    # Test MinIO API
    if curl -s -f --connect-timeout 5 "http://localhost:9002/minio/health/live" >/dev/null; then
        log "✓ MinIO API health check passed"
    else
        error "✗ MinIO API health check failed"
        return 1
    fi
    
    # Test MinIO Console
    if curl -s -f --connect-timeout 5 "http://localhost:9003" >/dev/null; then
        log "✓ MinIO Console is accessible"
    else
        error "✗ MinIO Console is not accessible"
        return 1
    fi
    
    log "✓ MinIO functionality is working"
    return 0
}

# Function to test dashboard functionality
test_dashboard() {
    echo "Testing dashboard functionality..."
    
    # Test main dashboard
    if curl -s -f --connect-timeout 5 "http://localhost:8080" >/dev/null; then
        log "✓ Dashboard is accessible"
    else
        error "✗ Dashboard is not accessible"
        return 1
    fi
    
    # Test status API
    if curl -s -f --connect-timeout 5 "http://localhost:8080/api/status" >/dev/null; then
        log "✓ Dashboard status API is working"
    else
        warn "✗ Dashboard status API is not working"
    fi
    
    log "✓ Dashboard functionality is working"
    return 0
}

# Function to check system resources
check_resources() {
    echo "Checking system resources..."
    
    # Check disk space
    local disk_usage=$(df /opt/freecompute-data | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $disk_usage -lt 90 ]]; then
        log "✓ Sufficient disk space available ($disk_usage% used)"
    else
        warn "⚠ Low disk space ($disk_usage% used)"
    fi
    
    # Check memory usage
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [[ $mem_usage -lt 90 ]]; then
        log "✓ Sufficient memory available ($mem_usage% used)"
    else
        warn "⚠ High memory usage ($mem_usage% used)"
    fi
    
    # Check Docker disk usage
    local docker_usage=$(docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}" | grep Images | awk '{print $3}')
    log "✓ Docker images using: $docker_usage"
}

# Function to display test summary
display_summary() {
    echo
    log "=== DEPLOYMENT TEST SUMMARY ==="
    echo
    
    info "Service Access URLs:"
    echo "  • Dashboard: http://localhost:8080"
    echo "  • MinIO API: http://localhost:9002"
    echo "  • MinIO Console: http://localhost:9003"
    echo "  • Ollama API: http://localhost:11435 (if enabled)"
    echo
    
    info "MinIO Console Credentials:"
    echo "  • Username: admin"
    echo "  • Password: FreeCompute2024!Secure"
    echo
    
    info "Data Location:"
    echo "  • /opt/freecompute-data"
    echo
    
    info "Useful Commands:"
    echo "  • View logs: docker-compose logs -f"
    echo "  • Stop services: docker-compose down"
    echo "  • Restart services: docker-compose restart"
    echo "  • Rollback: ./rollback-freecompute.sh"
    echo
}

# Main testing process
main() {
    echo "=== FREE COMPUTE NODE - DEPLOYMENT TESTING ==="
    echo "This script will test each component of your deployment"
    echo
    
    local all_tests_passed=true
    
    # Run tests
    test_containers || all_tests_passed=false
    echo
    
    test_data_directories || all_tests_passed=false
    echo
    
    test_port 8080 "Dashboard" "http://localhost:8080" || all_tests_passed=false
    echo
    
    test_port 9002 "MinIO API" "http://localhost:9002/minio/health/live" || all_tests_passed=false
    echo
    
    test_port 9003 "MinIO Console" "http://localhost:9003" || all_tests_passed=false
    echo
    
    test_minio || all_tests_passed=false
    echo
    
    test_dashboard || all_tests_passed=false
    echo
    
    check_resources
    echo
    
    display_summary
    
    if [[ "$all_tests_passed" == "true" ]]; then
        log "🎉 All tests passed! Your Free Compute Node is working correctly."
    else
        error "❌ Some tests failed. Please check the logs and troubleshoot."
        echo
        info "Troubleshooting tips:"
        echo "  1. Check container logs: docker-compose logs [service_name]"
        echo "  2. Restart services: docker-compose restart"
        echo "  3. Check port conflicts: ss -tuln | grep [port]"
        echo "  4. Verify data permissions: ls -la /opt/freecompute-data"
    fi
}

# Run main function
main 