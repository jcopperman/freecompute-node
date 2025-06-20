# Router & API Integration for Free Compute Node

This document outlines the architecture for adding router logic, API endpoints, and service registration to the Free Compute Node project.

## Architecture Overview

```
                    ┌───────────────┐
                    │   Dashboard   │
                    │    (Nginx)    │
                    └───────┬───────┘
                            │
                            ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  API Gateway  │◄────┤  Node Router  │────►│ Service Registry│
│   (Nginx)     │     │   (Express)   │     │    (JSON DB)   │
└───────┬───────┘     └───────┬───────┘     └───────────────┘
        │                     │
        ▼                     ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│ MinIO Service │     │ Ollama Service│     │ Other Services│
└───────────────┘     └───────────────┘     └───────────────┘
```

## Components

1. **Node Router**: 
   - Express.js application that handles routing between services
   - Service discovery and health checks
   - Load balancing for federated requests

2. **API Gateway**: 
   - Nginx configuration to expose standardized API endpoints
   - Authentication and rate limiting
   - Request/response logging

3. **Service Registry**:
   - Simple JSON-based storage for node and service information
   - Service capabilities and metadata
   - Node health and connectivity status

4. **Mesh Federation**:
   - Node discovery across the mesh
   - Capability sharing and advertisement
   - Request routing between nodes

## Implementation Steps

1. Create router service with Express.js
2. Extend Nginx configuration for API gateway
3. Implement service registry
4. Add service auto-registration
5. Create federation protocol for inter-node communication
6. Extend dashboard to visualize node mesh

## API Endpoints

### Node Management
- `GET /api/node/info` - Return node information
- `GET /api/node/health` - Health check endpoint
- `GET /api/node/services` - List available services

### Service Routing
- `GET /api/services` - List all services
- `GET /api/services/:serviceId` - Get service details
- `POST /api/services/:serviceId/register` - Register a new service

### Mesh Federation
- `GET /api/mesh/nodes` - List all nodes in the mesh
- `GET /api/mesh/capabilities` - List all capabilities across the mesh
- `POST /api/mesh/register` - Register this node with the mesh

## Configuration

The router and API gateway will use the existing environment variables from `.env` with additional options:

```
# Router Configuration
ROUTER_ENABLED=true
ROUTER_PORT=3000
ROUTER_AUTH_KEY=your_secure_key

# Mesh Federation
MESH_ENABLED=true
MESH_HUB=https://hub.example.com
MESH_TOKEN=your_mesh_token
```

## Security Considerations

- All API endpoints will require authentication
- Service-to-service communication will use API keys
- External mesh communication will be encrypted and authenticated
- Rate limiting will be applied to prevent abuse
