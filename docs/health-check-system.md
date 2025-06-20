# Health Check System

The Free Compute Node includes a health check system that monitors the status of all services and provides real-time information about the node's health and performance.

## Overview

The health check system consists of:

1. A health check module in the router service
2. Periodic checks of all services
3. System resource monitoring
4. A dynamic dashboard that displays real-time status

## How It Works

The health check system performs the following tasks:

- **Service Status Checks**: Periodically checks if each service (Nginx, MinIO, Ollama, Router) is responding
- **Container Status Checks**: Verifies Docker container status
- **Resource Monitoring**: Tracks CPU, memory, and disk usage
- **Ollama Model Detection**: Discovers and lists available AI models
- **Registry Updates**: Maintains an up-to-date service registry
- **Dashboard Integration**: Feeds real-time data to the dashboard

## Configuration

Health checks can be configured through environment variables in the `.env` file:

```bash
# Health Check Configuration
HEALTH_CHECK_INTERVAL=60000  # Interval in milliseconds (default: 60 seconds)
```

## API Endpoints

The router service provides several endpoints for accessing health information:

- `GET /api/health` - Basic health check (no authentication required)
- `GET /api/system/status` - Comprehensive system status (requires authentication)
- `GET /api/services` - List of all services and their status (requires authentication)
- `GET /api/node/info` - Node information including resources (requires authentication)

## Dashboard Integration

The dashboard now dynamically fetches data from the router API to display real-time status information. This includes:

- Current service status (active/inactive)
- System resource utilization
- Node information
- Mesh network status

## Authentication

To access the dashboard's dynamic features, you'll need to provide the Router API key. This is the same key configured in your `.env` file as `ROUTER_AUTH_KEY`.

## Troubleshooting

If services are incorrectly reported as inactive:

1. Check if the service is actually running with `docker ps`
2. Verify the service is accessible at the expected port
3. Check the router logs for any connection errors
4. Ensure your firewall allows connections to the service ports

## Technical Details

The health check system works by:

1. Making HTTP requests to service endpoints
2. Checking Docker container status
3. Running system commands to gather resource information
4. Storing status in the router's registry.json file
5. Updating the registry at configurable intervals

For developers, the health check module is extensible and can be modified to add custom checks for additional services.
