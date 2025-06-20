# Mesh Federation

This directory contains configuration and scripts for setting up a federated mesh of Free Compute Nodes.

## What is Federation?

Federation allows multiple Free Compute Nodes to discover each other, share resources, and route requests across the network. This enables distributed applications, redundant storage, and collaborative compute capabilities.

## Files

- `mesh.json`: Example mesh configuration showing node relationships
- `update-mesh.sh`: Script to update mesh information and sync with other nodes

## Mesh Structure

A Free Compute mesh can be configured in different topologies:

### Peer-to-Peer Mesh

In this topology, all nodes connect directly to each other:

```
    Node A <-----> Node B
      ↑              ↑
      |              |
      ↓              ↓
    Node D <-----> Node C
```

### Hub and Spoke

In this topology, nodes connect through a central hub:

```
         Node A
           ↑
           |
           ↓
Node B <-> Hub <-> Node D
           ↑
           |
           ↓
         Node C
```

## Getting Started

To join your node to an existing mesh:

1. Use the provided `mesh-connect.sh` script in the bootstrap directory:
   ```
   ./mesh-connect.sh http://other-node-ip:3000 other-node-name
   ```

2. Or manually register with another node:
   ```
   curl -X POST \
     -H "Content-Type: application/json" \
     -H "X-API-Key: your_api_key" \
     -d '{"nodeUrl":"http://your-ip:3000","nodeName":"your-node"}' \
     http://other-node-ip:3000/api/mesh/register
   ```

## Node Capabilities

Nodes can advertise different capabilities:

- `storage`: Large storage capacity
- `compute`: High CPU/memory resources
- `ai`: AI model hosting and inference
- `gateway`: Internet connectivity
- `archive`: Long-term data archiving

## Security Considerations

- Use API keys for authentication
- Consider using Tailscale or a VPN for sensitive deployments
- Regularly audit connected nodes
- Restrict sensitive services to trusted nodes only

## Further Reading

See the [Mesh Federation Guide](../docs/mesh-federation.md) for more detailed information about configuring and managing your mesh network.
