# Mesh Federation Guide

This guide explains how to connect multiple Free Compute Nodes into a federated mesh network.

## Overview

The Free Compute Node mesh allows multiple nodes to discover each other, share resources, and route requests across the network. This enables distributed applications, redundant storage, and collaborative compute capabilities.

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Node A    │◄────►│   Node B    │◄────►│   Node C    │
│ (Home Lab)  │      │ (Office)    │      │ (Cloud VPS) │
└─────┬───────┘      └─────┬───────┘      └─────┬───────┘
      │                    │                    │
      │                    ▼                    │
      │             ┌─────────────┐             │
      └────────────►│   Node D    │◄────────────┘
                    │ (Mesh Hub)  │
                    └─────────────┘
```

## Mesh Modes

### Direct Node-to-Node

In this mode, nodes directly connect to each other in a peer-to-peer fashion. This is ideal for small deployments or private networks.

### Hub and Spoke

In this mode, nodes connect to a central "hub" node that facilitates service discovery and request routing. This is ideal for larger deployments or when nodes are behind NATs.

## Configuration

To enable mesh networking, set the following in your `.env` file:

```
MESH_ENABLED=true
MESH_HUB=https://hub.example.com    # Optional, for hub and spoke mode
MESH_TOKEN=your_secure_token        # For authenticating with the hub
```

## Connecting Nodes

### Using the Helper Script

The simplest way to connect nodes is using the provided script:

```bash
./mesh-connect.sh http://192.168.1.100:3000 homelab-node storage,compute
```

This connects to the node at the specified URL and registers it with your local node.

### Manual Connection

You can also manually connect nodes using API calls:

```bash
# Register remote node with your local node
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your_api_key" \
  -d '{"nodeUrl":"http://192.168.1.100:3000","nodeName":"homelab-node","capabilities":"storage,compute"}' \
  http://localhost:3000/api/mesh/register

# Register your node with the remote node
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: remote_api_key" \
  -d '{"nodeUrl":"http://your-ip:3000","nodeName":"your-node","capabilities":"ai,storage"}' \
  http://192.168.1.100:3000/api/mesh/register
```

## Viewing Connected Nodes

To see all nodes in your mesh:

```bash
curl -H "X-API-Key: your_api_key" http://localhost:3000/api/mesh/nodes
```

## Mesh Capabilities

When connecting nodes, you can specify their capabilities, such as:

- `storage`: Node has significant storage capacity
- `compute`: Node has powerful compute resources
- `ai`: Node runs AI models
- `gateway`: Node serves as an internet gateway
- `archive`: Node provides long-term archival storage

## Security Considerations

- Always use secure API keys
- Consider using Tailscale or VPN for node-to-node communication
- Implement IP restrictions for sensitive nodes
- Regularly audit connected nodes

## Troubleshooting

If nodes cannot connect:

1. Ensure both nodes have router service running
2. Check that API keys match expectations
3. Verify network connectivity between nodes
4. Check firewall rules to ensure port 3000 is open
5. Review router logs with `docker-compose logs router`
