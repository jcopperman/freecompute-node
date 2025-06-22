# Monitoring Stack for FreeCompute Node

This directory contains the monitoring stack for the FreeCompute Node, providing comprehensive logging, metrics collection, and visualization capabilities.

## Components

The monitoring stack includes the following components:

- **Prometheus**: Time-series database for metrics collection
- **Loki**: Log aggregation system
- **Grafana**: Visualization platform for metrics and logs
- **Promtail**: Log collector for Loki
- **Node Exporter**: System metrics collector

## Deployment

### Simplified Stack (For Testing)

The simplified monitoring stack can be deployed independently for testing:

```bash
cd ~/Repos/freecompute-node/monitoring
docker-compose -f simplified-compose.yml up -d
```

### Integration with Full Stack

To integrate the monitoring stack with the main FreeCompute Node:

```bash
cd ~/Repos/freecompute-node/monitoring
./integrate-monitoring.sh
```

Then navigate to the bootstrap directory and start the full stack:

```bash
cd ~/Repos/freecompute-node/bootstrap
docker-compose up -d
```

## Access Information

| Component | URL | Default Credentials |
|-----------|-----|---------------------|
| Grafana | http://localhost:3000 | admin / FreeCompute2024!Secure |
| Prometheus | http://localhost:9090 | N/A |
| Loki | http://localhost:3100 | N/A |

## Troubleshooting

If you encounter issues with the monitoring stack, here are some common solutions:

1. **Loki WAL permission issues**:
   - Ensure the Loki data directory has proper permissions:
   ```bash
   chmod -R 777 ~/Repos/freecompute-node/bootstrap/data/loki
   ```

2. **Prometheus cannot reach targets**:
   - Check that the service names in prometheus.yml match the container names
   - Verify all services are running with `docker ps`

3. **No logs in Grafana**:
   - Ensure Promtail is properly configured to send logs to Loki
   - Check that the Loki URL in Promtail's config is correct

4. **Restarting the monitoring stack**:
   ```bash
   docker restart freecompute-prometheus freecompute-loki freecompute-grafana freecompute-promtail freecompute-node-exporter
   ```

## Data Storage

Monitoring data is stored in:
- `~/Repos/freecompute-node/bootstrap/data/prometheus`
- `~/Repos/freecompute-node/bootstrap/data/loki`
- `~/Repos/freecompute-node/bootstrap/data/grafana`

## Pre-configured Dashboards

The monitoring stack comes with pre-configured dashboards:
- FreeCompute Node Dashboard (services health, metrics, logs)
- System monitoring (CPU, memory, disk, network)

## Integration with FreeCompute Node

The monitoring stack integrates with the existing FreeCompute Node services:
- The router service exposes metrics for Prometheus
- Docker logs are captured by Loki via Promtail
- System metrics are collected by Node Exporter
- All metrics are visualized in Grafana dashboards

## Testing the Monitoring Stack

You can generate test logs to verify the monitoring stack is working:

```bash
cd ~/Repos/freecompute-node/monitoring
./generate-test-logs.sh
```

Then check the logs in Grafana (http://localhost:3000) > Explore > Select Loki data source > Query: `{job="system"}`
