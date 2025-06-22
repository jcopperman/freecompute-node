# Free Compute Node - Quick Reference

## Service URLs

| Service | URL | Credentials | Purpose |
|---------|-----|-------------|---------|
| **Dashboard** | http://localhost:8080 | None | Main control panel |
| **MinIO Console** | http://localhost:9003 | admin / FreeCompute2024!Secure | Storage management |
| **MinIO API** | http://localhost:9002 | S3 API | Object storage API |
| **Grafana** | http://localhost:3000 | admin / FreeCompute2024!Secure | Monitoring dashboards |
| **Prometheus** | http://localhost:9090 | None | Metrics collection |
| **Loki** | http://localhost:3100 | None | Log aggregation |
| **cAdvisor** | http://localhost:8081 | None | Container monitoring |

## Quick Commands

### Deployment
```bash
# Start the stack
docker-compose up -d

# Stop the stack
docker-compose down

# View status
docker-compose ps

# View logs
docker-compose logs -f
```

### Health Checks
```bash
# Overall system status
curl http://localhost:8080/api/system/status | jq .

# Individual services
curl -I http://localhost:8080          # Dashboard
curl http://localhost:9002/minio/health/live  # MinIO
curl -I http://localhost:3000          # Grafana
curl -I http://localhost:9090          # Prometheus
```

### Troubleshooting
```bash
# Check container logs
docker logs freecompute-nginx
docker logs freecompute-router
docker logs freecompute-minio

# Restart services
docker restart freecompute-nginx
docker restart freecompute-router

# Nuclear reset
docker-compose down -v
sudo rm -rf data/
docker-compose up -d
```

### Data Management
```bash
# Backup data
tar -czf backup-$(date +%Y%m%d).tar.gz data/

# Check disk usage
du -sh data/

# Clean up Docker
docker system prune -f
```

## Port Configuration

| Service | Default Port | Production Port | Configurable |
|---------|--------------|-----------------|--------------|
| Dashboard | 80 | 8080 | Yes (NGINX_PORT) |
| MinIO API | 9000 | 9002 | Yes (MINIO_PORT) |
| MinIO Console | 9001 | 9003 | Yes (MINIO_CONSOLE_PORT) |
| Router API | 3000 | 8090 | Yes (ROUTER_PORT) |
| Grafana | 3000 | 3000 | Yes |
| Prometheus | 9090 | 9090 | Yes |
| Ollama | 11434 | 11435 | Yes (OLLAMA_PORT) |

## Environment Variables

### Core Configuration
```bash
NODE_NAME=production-freecompute-node
NODE_ROLE=general
DATA_ROOT=/opt/freecompute-data
```

### Service Toggles
```bash
NGINX_ENABLED=true
MINIO_ENABLED=true
OLLAMA_ENABLED=false
TAILSCALE_ENABLED=false
```

### Security
```bash
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=FreeCompute2024!Secure
ROUTER_AUTH_KEY=change_this_key
```

## File Locations

| Component | Location | Purpose |
|-----------|----------|---------|
| Configuration | `bootstrap/.env` | Environment variables |
| Data | `bootstrap/data/` | Persistent storage |
| Logs | `bootstrap/data/*/logs/` | Service logs |
| Backups | `bootstrap/backups/` | Backup storage |
| Docker Compose | `bootstrap/docker-compose.yml` | Service definitions |
| Nginx Config | `bootstrap/nginx/nginx.conf` | Web server config |

## API Endpoints

### Router API (Internal: http://localhost:8090)
```bash
GET /api/health              # Simple health check
GET /api/system/status       # Full system status (public)
GET /api/system/status/detailed  # Detailed status (auth required)
GET /api/node/info           # Node information (auth required)
GET /api/mesh/nodes          # Mesh network nodes (auth required)
POST /api/mesh/register      # Register with mesh (auth required)
GET /metrics                 # Prometheus metrics
```

### Dashboard API (Public: http://localhost:8080/api/*)
All router endpoints are proxied through nginx for CORS compatibility.

## Common Issues

| Issue | Quick Fix |
|-------|-----------|
| Dashboard 404 | `docker restart freecompute-nginx` |
| CORS errors | Check router: `docker logs freecompute-router` |
| Network conflicts | `docker-compose down && docker-compose up -d` |
| Storage full | Clean up: `docker system prune -f` |
| Container won't start | Check logs: `docker-compose logs [service]` |

## Security Notes

### Default Passwords (Change These!)
- MinIO: admin / FreeCompute2024!Secure
- Grafana: admin / FreeCompute2024!Secure
- Router API Key: change_this_key

### Network Security
- All services run on isolated Docker network
- External access only through configured ports
- API authentication required for sensitive operations

### Data Security
- All data stored in `/opt/freecompute-data`
- Regular backups recommended
- File permissions isolated to running user

## Support

### Documentation
- Main README: `README.md`
- Deployment Guide: `bootstrap/PRODUCTION-DEPLOYMENT-GUIDE.md`
- Troubleshooting: `docs/TROUBLESHOOTING.md`
- Monitoring Guide: `docs/monitoring-system.md`

### Getting Help
1. Check logs: `docker-compose logs -f`
2. Run health checks: `curl http://localhost:8080/api/system/status`
3. Review troubleshooting guide
4. Create GitHub issue with debug information

---

**Last Updated**: June 2025  
**Version**: Current deployment with IPv6 fix, nginx proxy, and router improvements
