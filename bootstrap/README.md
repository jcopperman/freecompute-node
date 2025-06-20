# Bootstrap – Free Compute Node

This directory contains everything you need to set up your own Free Compute Node – a local-first micro data center that runs essential services without cloud dependencies or monthly fees.

## What's Included

* **`.env.example`**: Template for configuration with sensible defaults
* **`docker-compose.yml`**: Container setup for core services (MinIO and optional Ollama)
* **`install.sh`**: Main installation script that sets up everything
* **`register-node.sh`**: Generates node information for local reference
* **`scripts/`**: Optional folder for additional setup helpers

### Services Included

* Nginx (dashboard and service proxy)
* MinIO (object storage)
* Router (API gateway and mesh networking)
* Ollama (AI inference, optional)
* Tailscale (mesh networking)

---

## Quick Start

1. Copy the example environment file:

   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file to match your requirements:

   ```bash
   nano .env  # or use any text editor
   ```

   At minimum, you should:

   * Set a strong password for MinIO
   * Add your Tailscale auth key (if using mesh networking)
   * Adjust the `DATA_ROOT` path if needed

3. Make the scripts executable (if they aren't already):

   ```bash
   chmod +x install.sh register-node.sh
   ```

4. Create local data directories (for Docker compatibility):

   ```bash
   mkdir -p ./data/minio ./data/ollama
   ```

5. Run the installation script:

   ```bash
   ./install.sh
   ```

   You may be prompted for your sudo password during setup.

The script will:

* Install Docker and Docker Compose if needed
* Set up Tailscale with your auth key (if provided)
* Create necessary data directories
* Start the configured services
* Pull Ollama model (only if Ollama is enabled)
* Register your node information

---

## Configuration Options

### Node Metadata

* `NODE_NAME`: Human-readable name for your node
* `NODE_ROLE`: Purpose of this node (general, storage, compute, ai)
* `NODE_TIMEZONE`: Local timezone for logs and scheduling

### Tailscale Mesh Networking

* `TAILSCALE_AUTH_KEY`: Authentication key from Tailscale admin console
* `TAILSCALE_HOSTNAME`: How this node appears on the Tailscale network
* `TAILSCALE_TAGS`: Optional tags for node identification and ACLs

### MinIO Object Storage

* `MINIO_ENABLED`: Set to false to disable
* `MINIO_ROOT_USER`: Admin username
* `MINIO_ROOT_PASSWORD`: Admin password (change from default!)
* `MINIO_PORT`: API port (default: 9002)
* `MINIO_CONSOLE_PORT`: Web console port (default: 9003)
* `MINIO_DATA_DIR`: Data directory (default: `./data/minio`)

### Nginx Dashboard

* `NGINX_ENABLED`: Set to false to disable
* `NGINX_PORT`: Web dashboard port (default: 8080)

### Ollama AI Service (Optional)

* `OLLAMA_ENABLED`: Set to true to enable (disabled by default)
* `OLLAMA_PORT`: API port (default: 11435)
* `OLLAMA_MODEL`: Default AI model to pull if enabled
* `OLLAMA_DATA_DIR`: Data directory (default: `./data/ollama`)

### Router & API Gateway

* `ROUTER_ENABLED`: Set to false to disable
* `ROUTER_PORT`: API port (default: 3000)
* `ROUTER_AUTH_KEY`: Authentication key for API access

### Mesh Federation

* `MESH_ENABLED`: Set to true to enable mesh networking
* `MESH_HUB`: URL of mesh hub (if using a centralized hub)
* `MESH_TOKEN`: Authentication token for mesh hub

### Storage

* `DATA_ROOT`: Base directory for all persistent data (now uses local `./data` directory by default)

> **Note:** The system now uses local data directories (`./data/minio` and `./data/ollama`) by default for better Docker compatibility. This eliminates permission issues that can occur with absolute paths outside the project directory.

---

## Manual Node Registration

You can run the registration script separately at any time:

```bash
./register-node.sh
```

This creates a `node-info.txt` file with details about your node, which can be useful for:

* Local inventory management
* Troubleshooting
* Sharing node capabilities with others

---

## Adding More Services

To add additional services:

1. Add appropriate variables to your `.env` file
2. Edit the `docker-compose.yml` file to include the new service
3. Restart with `docker-compose up -d`

## Mesh Federation

Free Compute Nodes can form a federated mesh network, allowing multiple nodes to discover each other, share resources, and route requests across the network.

### Connecting Nodes

To connect two nodes:

```bash
./mesh-connect.sh http://other-node-ip:3000 other-node-name
```

### Managing the Mesh

You can view and manage your mesh network using the Router API:

```bash
# View all nodes in your mesh
curl -H "X-API-Key: your_api_key" http://localhost:3000/api/mesh/nodes

# Get service information
curl -H "X-API-Key: your_api_key" http://localhost:3000/api/services
```

For more information, see the [Mesh Federation Guide](../docs/mesh-federation.md).

---

## Troubleshooting

If you encounter issues:

1. Check the service logs: `docker-compose logs -f [service_name]`
2. Verify port availability: `ss -tuln | grep [port_number]`
3. Ensure storage directories are properly mounted: `docker-compose config`
4. Check Tailscale connectivity: `tailscale status`

### Common Issues and Solutions

#### Docker Mount Issues

If you see an error like:
```
Cannot start service minio: Mounts denied: The path /opt/... is not shared from the host and is not known to Docker.
```

Solution: 
- Make sure you're using local paths in your `.env` file (e.g., `./data/minio` instead of `/opt/freecompute-data/minio`)
- Run `mkdir -p ./data/minio ./data/ollama` to create the required local directories
- Update your `.env` file to use these local paths

#### Service Access

- Dashboard: Accessible at `http://localhost:8080` (or whatever port you set in `NGINX_PORT`)
- MinIO Console: Directly accessible at `http://localhost:9003` (or whatever port you set in `MINIO_CONSOLE_PORT`)
- MinIO API: Accessible at `http://localhost:9002` (or whatever port you set in `MINIO_PORT`)

---

## Part of the Free Compute Stack

This bootstrap setup is part of the Free Compute Movement – a sovereign, local-first stack for South Africa and the Global South.

This repo is just the beginning. Your node, your rules.