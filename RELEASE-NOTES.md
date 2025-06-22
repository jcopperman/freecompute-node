# Free Compute Node - Release Notes

## Latest Fixes (June 22, 2025)

### Major Issues Resolved ✅

#### 1. Docker Network IPv6 Conflict
- **Issue**: `Network "freecompute-network" needs to be recreated - option "com.docker.network.enable_ipv6" has changed`
- **Fix**: Added explicit IPv6 configuration in docker-compose.yml
- **Impact**: Eliminates network recreation errors on deployment

#### 2. Dashboard 404 Not Found
- **Issue**: http://localhost:8080 returned nginx 404 error
- **Root Cause**: Multiple nginx server blocks and default.conf conflicts
- **Fix**: Consolidated nginx configuration into single server block
- **Impact**: Dashboard now loads correctly

#### 3. API CORS Errors
- **Issue**: Dashboard couldn't fetch data due to CORS policy blocks
- **Root Cause**: 
  - Router port mismatch (nginx proxying to port 3000, router on 8090)
  - Dashboard making direct API calls instead of using proxy
- **Fix**: 
  - Updated nginx proxy to correct router port (8090)
  - Modified dashboard to use relative API URLs through nginx
- **Impact**: All API calls now work through nginx proxy

#### 4. Router Service Startup Failures
- **Issue**: Router container failed to start or wasn't accessible
- **Root Causes**: 
  - Missing `HEALTH_CHECK_INTERVAL` environment variable
  - Missing `app.listen()` call in server.js
- **Fix**: 
  - Added `HEALTH_CHECK_INTERVAL=30000` to docker-compose
  - Added proper `app.listen()` call to router initialization
- **Impact**: Router now starts reliably and serves API requests

### Configuration Improvements

#### Network Configuration
```yaml
networks:
  freecompute:
    name: freecompute-network
    driver: bridge
    driver_opts:
      com.docker.network.enable_ipv6: "false"
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
```

#### Nginx Proxy Configuration
- Fixed proxy target: `http://freecompute-router:8090/api/`
- Consolidated server blocks for better routing
- Added proper error page handling

#### Router API Updates
- Added public `/api/system/status` endpoint (no auth required)
- Moved detailed status to `/api/system/status/detailed` (auth required)
- Fixed environment variable handling

### Service Status After Fixes

| Service | Status | URL | Notes |
|---------|--------|-----|-------|
| Dashboard | ✅ Working | http://localhost:8080 | Loads correctly, API calls work |
| Router API | ✅ Working | http://localhost:8090 | All endpoints accessible |
| MinIO | ✅ Working | http://localhost:9002/9003 | Storage and console accessible |
| Nginx Proxy | ✅ Working | Routes /api/* to router | CORS issues resolved |
| Grafana | ✅ Working | http://localhost:3000 | Monitoring dashboards |
| Prometheus | ✅ Working | http://localhost:9090 | Metrics collection |

### API Endpoints Working

```bash
# Public endpoints (no auth)
GET /api/health                 # Simple health check
GET /api/system/status         # Basic system status

# Authenticated endpoints
GET /api/system/status/detailed # Comprehensive status
GET /api/node/info             # Node information
GET /api/mesh/nodes            # Mesh network status
```

### Breaking Changes
- None - all changes are backward compatible
- Existing deployments will automatically pick up fixes on restart

### Known Issues Resolved
- ❌ Dashboard 404 errors
- ❌ CORS policy blocks
- ❌ Router connection refused errors
- ❌ Docker network recreation errors
- ❌ API endpoint timeouts

### Documentation Updates
- Added comprehensive troubleshooting guide
- Updated production deployment guide
- Created quick reference card
- Updated service URLs and port mappings

## Previous Releases

### Initial Release
- Basic Docker Compose stack
- MinIO object storage
- Nginx web server
- Router API gateway
- Optional Ollama AI service
- Monitoring with Grafana/Prometheus

---

## Upgrade Instructions

### From Previous Version
```bash
# Pull latest changes
git pull origin main

# Stop services
docker-compose down

# Remove old network (if needed)
docker network rm freecompute-network

# Start with new configuration
docker-compose up -d

# Verify services
curl http://localhost:8080/api/system/status
```

### Clean Installation
```bash
# Use the production deployment script
cd bootstrap
./deploy-production.sh
```

## Support

- **Troubleshooting**: See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- **Quick Reference**: See [docs/QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md)
- **Deployment Guide**: See [bootstrap/PRODUCTION-DEPLOYMENT-GUIDE.md](bootstrap/PRODUCTION-DEPLOYMENT-GUIDE.md)
