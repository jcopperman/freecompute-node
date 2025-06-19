# Free Compute Node Bootstrap

This directory contains everything you need to set up your own Free Compute Node - a local-first micro data center that runs essential services without cloud dependencies or monthly fees.

## What's Included

- **`.env.example`**: Template for configuration with sensible defaults
- **`docker-compose.yml`**: Container setup for core services (MinIO and optional Ollama)
- **`install.sh`**: Main installation script that sets up everything
- **`register-node.sh`**: Generates node information for local reference

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
   - Set a strong password for MinIO
   - Add your Tailscale auth key (if using mesh networking)
   - Adjust the `DATA_ROOT` path if needed

3. Make the scripts executable (if they aren't already):
   ```bash
   chmod +x install.sh register-node.sh
   ```

4. Run the installation script:
   ```bash
   ./install.sh
   ```

The script will:
- Install Docker and Docker Compose if needed
- Set up Tailscale with your auth key (if provided)
- Create necessary data directories
- Start the configured services
- Pull Ollama model (only if Ollama is enabled)
- Register your node information

## Configuration Options

### Node Metadata
- `NODE_NAME`: Human-readable name for your node
- `NODE_ROLE`: Purpose of this node (general, storage, compute, ai)
- `NODE_TIMEZONE`: Local timezone for logs and scheduling

### Tailscale Mesh Networking
- `TAILSCALE_AUTH_KEY`: Authentication key from Tailscale admin console
- `TAILSCALE_HOSTNAME`: How this node appears on the Tailscale network
- `TAILSCALE_TAGS`: Optional tags for node identification and ACLs

### MinIO Object Storage
- `MINIO_ENABLED`: Set to false to disable
- `MINIO_ROOT_USER`: Admin username
- `MINIO_ROOT_PASSWORD`: Admin password (change from default!)
- `MINIO_PORT`: API port (default: 9000)
- `MINIO_CONSOLE_PORT`: Web console port (default: 9001)

### Ollama AI Service (Optional)
- `OLLAMA_ENABLED`: Set to true to enable (disabled by default)
- `OLLAMA_PORT`: API port (default: 11434)
- `OLLAMA_MODEL`: Default AI model to pull if enabled

### Storage
- `DATA_ROOT`: Base directory for all persistent data

## Manual Node Registration

You can run the registration script separately at any time:

```bash
./register-node.sh
```

This creates a `node-info.txt` file with details about your node, which can be useful for:
- Local inventory management
- Troubleshooting
- Sharing node capabilities with others

## Adding More Services

To add additional services:
1. Add appropriate variables to your `.env` file
2. Edit the `docker-compose.yml` file to include the new service
3. Restart with `docker-compose up -d`

## Troubleshooting

If you encounter issues:
1. Check the service logs: `docker-compose logs -f [service_name]`
2. Verify port availability: `ss -tuln | grep [port_number]`
3. Ensure storage directories are properly mounted: `docker-compose config`
4. Check Tailscale connectivity: `tailscale status`

## Part of the Free Compute Stack

This bootstrap setup is part of the Free Compute Movement - a sovereign, local-first stack for South Africa and the Global South.

For more information, see the main project documentation.
