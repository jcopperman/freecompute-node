# Free Compute Node - Troubleshooting Guide

This guide covers common issues and their solutions when deploying and running Free Compute Node.

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Common Issues](#common-issues)
- [Network Issues](#network-issues)
- [Container Issues](#container-issues)
- [Service-Specific Issues](#service-specific-issues)
- [Log Analysis](#log-analysis)
- [Complete Reset](#complete-reset)

## Quick Diagnostics

### Check Container Status
```bash
cd bootstrap
docker-compose ps
```

### Check Service Health
```bash
# Dashboard
curl -I http://localhost:8080

# API Status
curl http://localhost:8080/api/system/status | jq .

# MinIO Health
curl http://localhost:9002/minio/health/live

# Container logs
docker logs freecompute-nginx
docker logs freecompute-router
docker logs freecompute-minio
```

### Check Network Connectivity
```bash
# Check Docker network
docker network inspect freecompute-network

# Test internal connectivity
docker exec freecompute-nginx curl http://freecompute-router:8090/api/health
```

## Common Issues

### 1. Dashboard Shows 404 Not Found

**Symptoms:**
- http://localhost:8080 returns nginx 404 error
- Dashboard files not loading

**Causes & Solutions:**

#### A. Nginx Configuration Issue
```bash
# Check nginx logs
docker logs freecompute-nginx --tail 20

# Restart nginx
docker restart freecompute-nginx
```

#### B. Dashboard Files Not Mounted
```bash
# Check if dashboard files exist
ls -la ../dashboard/

# Verify mount in container
docker exec freecompute-nginx ls -la /usr/share/nginx/html/
```

#### C. Multiple Server Blocks Conflict
This was a common issue where nginx had conflicting server configurations.

**Solution:** The nginx.conf has been updated to use a single server block. If you see this issue:
```bash
# Check for default.conf conflicts
docker exec freecompute-nginx ls /etc/nginx/conf.d/
# Should only show our nginx.conf, no default.conf
```

### 2. API Calls Failing with CORS Errors

**Symptoms:**
- Browser console shows CORS policy errors
- Dashboard can't fetch data from API
- "Access to fetch blocked by CORS policy" messages

**Causes & Solutions:**

#### A. Router Connection Issues
```bash
# Check if router is accessible from nginx
docker exec freecompute-nginx curl http://freecompute-router:8090/api/health

# Check router logs
docker logs freecompute-router --tail 20
```

#### B. Port Mismatch
The router runs on port 8090 internally, nginx must proxy to the correct port:
```bash
# Verify nginx config points to correct router port
docker exec freecompute-nginx grep -A 5 "proxy_pass.*router" /etc/nginx/nginx.conf
# Should show: http://freecompute-router:8090/api/
```

#### C. Dashboard Using Wrong API URL
```bash
# Check dashboard configuration
grep "API_URL" ../dashboard/dashboard.js
# Should use relative URLs through nginx proxy, not direct router URLs
```

### 3. Docker Network Recreation Error

**Symptoms:**
```
ERROR: Network "freecompute-network" needs to be recreated - option "com.docker.network.enable_ipv6" has changed
```

**Solution:**
```bash
# Stop containers and remove network
docker-compose down

# Remove the problematic network
docker network rm freecompute-network

# Restart with fixed configuration
docker-compose up -d
```

The docker-compose.yml now includes explicit IPv6 configuration to prevent this issue.

### 4. Router Not Starting / Connection Refused

**Symptoms:**
- nginx logs show "Connection refused" to router
- Router container exits immediately
- API endpoints return 502/404 errors

**Causes & Solutions:**

#### A. Missing Environment Variables
```bash
# Check router environment
docker exec freecompute-router env | grep -E "(ROUTER_PORT|HEALTH_CHECK_INTERVAL)"

# Should show:
# ROUTER_PORT=8090
# HEALTH_CHECK_INTERVAL=30000
```

#### B. Router Server Not Listening
```bash
# Check if router process is running
docker exec freecompute-router ps aux

# Check network listeners
docker exec freecompute-router netstat -tlnp
```

#### C. Missing app.listen() Call
This was fixed in the router server.js. The server now properly starts with:
```javascript
app.listen(PORT, '0.0.0.0', () => {
  logger.info(`Server running on port ${PORT}`);
});
```

## Network Issues

### Docker Network Problems
```bash
# Inspect network configuration
docker network inspect freecompute-network

# Check for IP conflicts
docker network ls | grep freecompute

# Remove and recreate network
docker network rm freecompute-network
docker-compose up -d
```

### Port Conflicts
```bash
# Check what's using your ports
sudo netstat -tlnp | grep -E "(8080|9002|9003|8090|3000)"

# If ports are in use, update .env file
nano .env
# Change conflicting ports
```

### Service Discovery Issues
```bash
# Test service name resolution
docker exec freecompute-nginx nslookup freecompute-router
docker exec freecompute-nginx ping -c 3 freecompute-router
```

## Container Issues

### Container Won't Start
```bash
# Check container status
docker-compose ps

# Check specific container logs
docker logs freecompute-[service-name]

# Restart specific service
docker-compose restart [service-name]
```

### Out of Memory
```bash
# Check container resource usage
docker stats

# Check system resources
free -h
df -h
```

### Permission Issues
```bash
# Check data directory permissions
ls -la data/

# Fix permissions if needed
sudo chown -R $USER:$USER data/
```

## Service-Specific Issues

### MinIO Issues
```bash
# Check MinIO health
curl http://localhost:9002/minio/health/live

# Access MinIO console
open http://localhost:9003
# Default credentials: admin / FreeCompute2024!Secure

# Check MinIO logs
docker logs freecompute-minio
```

### Grafana Issues
```bash
# Check Grafana status
curl -I http://localhost:3000

# Reset Grafana admin password
docker exec freecompute-grafana grafana-cli admin reset-admin-password newpassword

# Check Grafana logs
docker logs freecompute-grafana
```

### Prometheus Issues
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check Prometheus config
docker exec freecompute-prometheus cat /etc/prometheus/prometheus.yml
```

## Log Analysis

### Centralized Logging
```bash
# View all container logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f nginx
docker-compose logs -f router
docker-compose logs -f minio
```

### Common Log Patterns

#### Router Healthy Startup
```
Service check for http://nginx:80/: OK
Service check for http://minio:9000/minio/health/live: OK
Health checks will run every 30 seconds
Server running on port 8090
```

#### Nginx Successful Proxy
```
172.20.0.1 - - [22/Jun/2025:07:09:55 +0000] "GET /api/system/status HTTP/1.1" 200 585
```

#### Common Error Patterns
```bash
# Connection refused (router not running)
connect() failed (111: Connection refused) while connecting to upstream

# File not found (mount issue)
"/usr/share/nginx/html/index.html" is not found

# CORS preflight failure
Response to preflight request doesn't pass access control check
```

## Complete Reset

### Nuclear Option - Full Reset
```bash
# Stop all containers
docker-compose down -v

# Remove all data
sudo rm -rf data/

# Remove containers and images
docker-compose down --rmi all

# Clean up networks
docker network prune -f

# Start fresh
docker-compose up -d
```

### Selective Reset
```bash
# Reset just the web services
docker-compose restart nginx router

# Reset just storage
docker-compose stop minio
sudo rm -rf data/minio/
docker-compose up -d minio

# Reset monitoring
docker-compose stop grafana prometheus loki
sudo rm -rf data/grafana/ data/prometheus/ data/loki/
docker-compose up -d grafana prometheus loki
```

## Getting Help

### Collect Debug Information
```bash
# System info
uname -a
docker --version
docker-compose --version

# Container status
docker-compose ps
docker stats --no-stream

# Network info
docker network ls
docker network inspect freecompute-network

# Service health
curl -s http://localhost:8080/api/system/status | jq .
```

### Report Issues
When reporting issues, please include:
1. Output from debug information above
2. Relevant container logs
3. Steps to reproduce the issue
4. Expected vs actual behavior

### Community Support
- **GitHub Issues**: Report bugs and feature requests
- **Documentation**: Check other docs/ files for specific topics
- **Discord/Matrix**: [Community links coming soon]

---

## Prevention

### Regular Maintenance
```bash
# Update containers (when new versions available)
docker-compose pull
docker-compose up -d

# Clean up unused resources
docker system prune -f

# Backup important data
tar -czf backup-$(date +%Y%m%d).tar.gz data/
```

### Monitoring
- Check Grafana dashboards regularly
- Set up alerting for critical services
- Monitor disk space and resource usage

### Configuration Management
- Keep backups of working configurations
- Document any custom changes
- Use version control for configuration files
