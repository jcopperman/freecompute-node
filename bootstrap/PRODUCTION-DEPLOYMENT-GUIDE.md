# Free Compute Node - Production Deployment Guide

This guide provides step-by-step instructions for safely deploying Free Compute Node on a production Ubuntu 24.04.2 LTS server with existing services.

## 🚨 Safety First

This deployment is designed to be **non-intrusive** and **fully reversible**. It will:
- ✅ Use non-conflicting ports (8080, 9002, 9003, 11435)
- ✅ Store data in isolated directory (`/opt/freecompute-data`)
- ✅ Skip Tailscale setup (since it's already running)
- ✅ Provide automatic rollback capability
- ✅ Perform pre-flight safety checks

## 📋 Prerequisites

Your server should have:
- ✅ Ubuntu 24.04.2 LTS
- ✅ Docker and Docker Compose installed and running
- ✅ Tailscale installed and running
- ✅ Existing services on ports: 80, 8001, 8095, 8090, 8070

## 🚀 Quick Deployment

### Step 1: Navigate to Bootstrap Directory
```bash
cd ~/Repos/freecompute-node/bootstrap
```

### Step 2: Run the Production Deployment Script
```bash
./deploy-production.sh
```

The script will:
1. ✅ Check for port conflicts
2. ✅ Verify Docker is running
3. ✅ Create isolated data directory
4. ✅ Deploy services with safe configuration
5. ✅ Verify deployment
6. ✅ Create rollback script

### Step 3: Test the Deployment
```bash
./test-deployment.sh
```

## 🔧 Configuration Details

### Port Mapping (Safe Configuration)
| Service | Default Port | Production Port | URL |
|---------|-------------|----------------|-----|
| Dashboard | 80 | **8080** | http://localhost:8080 |
| MinIO API | 9000 | **9002** | http://localhost:9002 |
| MinIO Console | 9001 | **9003** | http://localhost:9003 |
| Ollama API | 11434 | **11435** | http://localhost:11435 |

### Data Storage
- **Root Directory**: `/opt/freecompute-data`
- **MinIO Data**: `/opt/freecompute-data/minio`
- **Ollama Data**: `/opt/freecompute-data/ollama` (if enabled)

### Default Credentials
- **MinIO Username**: `admin`
- **MinIO Password**: `FreeCompute2024!Secure`

⚠️ **IMPORTANT**: Change the MinIO password after first login!

## 🔍 Verification Steps

### 1. Check Service Status
```bash
# View running containers
docker ps | grep freecompute

# Check service logs
docker-compose logs -f nginx
docker-compose logs -f minio
```

### 2. Test Service Access
```bash
# Test dashboard
curl -f http://localhost:8080

# Test MinIO API
curl -f http://localhost:9002/minio/health/live

# Test MinIO Console
curl -f http://localhost:9003
```

### 3. Verify Data Directory
```bash
# Check data directory structure
ls -la /opt/freecompute-data/

# Check permissions
ls -la /opt/freecompute-data/minio/
```

## 🔄 Rollback Plan

If you need to completely remove the deployment:

### Option 1: Use the Rollback Script
```bash
./rollback-freecompute.sh
```

### Option 2: Manual Rollback
```bash
# Stop and remove containers
docker-compose down -v

# Remove data directory
sudo rm -rf /opt/freecompute-data

# Remove Docker network
docker network rm freecompute-network
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Check what's using the port
ss -tuln | grep :8080

# Kill the process if needed
sudo kill -9 $(lsof -t -i:8080)
```

#### 2. Permission Denied
```bash
# Fix data directory permissions
sudo chown -R $(whoami):$(whoami) /opt/freecompute-data
sudo chmod -R 755 /opt/freecompute-data
```

#### 3. Container Won't Start
```bash
# Check container logs
docker-compose logs nginx
docker-compose logs minio

# Restart services
docker-compose restart
```

#### 4. Dashboard Not Accessible
```bash
# Check if nginx container is running
docker ps | grep freecompute-nginx

# Check nginx logs
docker-compose logs nginx

# Test nginx configuration
docker exec freecompute-nginx nginx -t
```

### Debug Commands

```bash
# View all container logs
docker-compose logs -f

# Check container resource usage
docker stats

# Inspect container configuration
docker inspect freecompute-nginx

# Access container shell
docker exec -it freecompute-nginx sh
```

## 📊 Monitoring

### System Resources
```bash
# Check disk usage
df -h /opt/freecompute-data

# Check memory usage
free -h

# Check Docker disk usage
docker system df
```

### Service Health
```bash
# Run comprehensive test
./test-deployment.sh

# Check service status
docker-compose ps
```

## 🔐 Security Considerations

### 1. Change Default Passwords
- MinIO admin password
- Any other service credentials

### 2. Network Security
- Services are only accessible on localhost by default
- Consider firewall rules if exposing externally

### 3. Data Backup
```bash
# Create backup
sudo cp -r /opt/freecompute-data /opt/freecompute-data.backup.$(date +%Y%m%d)

# Restore backup
sudo cp -r /opt/freecompute-data.backup.YYYYMMDD /opt/freecompute-data
```

## 📝 Configuration Files

### Environment Configuration
- **File**: `env.production`
- **Purpose**: Production-safe configuration
- **Location**: `bootstrap/env.production`

### Docker Compose
- **File**: `docker-compose.yml`
- **Purpose**: Service orchestration
- **Location**: `bootstrap/docker-compose.yml`

## 🎯 Next Steps

After successful deployment:

1. **Change MinIO Password**: Access http://localhost:9003 and update credentials
2. **Configure Backup**: Set up regular backups of `/opt/freecompute-data`
3. **Monitor Resources**: Watch disk and memory usage
4. **Enable Ollama** (Optional): Edit `.env` and set `OLLAMA_ENABLED=true`
5. **Join Federation**: Consider connecting to the Free Compute mesh network

## 📞 Support

If you encounter issues:

1. Run `./test-deployment.sh` for diagnostics
2. Check container logs: `docker-compose logs -f`
3. Verify system resources and permissions
4. Use the rollback script if needed: `./rollback-freecompute.sh`

---

**Remember**: This deployment is designed to be safe and reversible. Your existing services will continue to run without interruption. 