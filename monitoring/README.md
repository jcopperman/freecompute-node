# Monitoring Stack for Free Compute Node

This directory contains the monitoring stack for the Free Compute Node, providing comprehensive logging, metrics collection, and visualization capabilities.

## Components

The monitoring stack includes the following components:

- **Prometheus**: Time-series database for metrics collection
- **Loki**: Log aggregation system
- **Grafana**: Visualization platform for metrics and logs
- **cAdvisor**: Container resource usage metrics collector

## Deployment

The monitoring stack can be deployed independently after deploying the main Free Compute Node services:

```bash
cd ~/Repos/freecompute-node/monitoring
./deploy-monitoring.sh
```

## Access Information

| Component | URL | Default Credentials |
|-----------|-----|---------------------|
| Grafana | http://localhost:3000 | admin / FreeCompute2024!Secure |
| Prometheus | http://localhost:9090 | N/A |
| Loki | http://localhost:3100 | N/A |
| cAdvisor | http://localhost:8081 | N/A |

## Configuration

The monitoring stack can be configured through the `.env` file in the monitoring directory:

```
PROMETHEUS_PORT=9090
LOKI_PORT=3100
GRAFANA_PORT=3000
CADVISOR_PORT=8081
GRAFANA_USER=admin
GRAFANA_PASSWORD=FreeCompute2024!Secure
NODE_NAME=freecompute-node
LOKI_ENABLED=true
```

## Data Storage

Monitoring data is stored in:
- `/opt/freecompute-data/monitoring/prometheus`
- `/opt/freecompute-data/monitoring/loki`
- `/opt/freecompute-data/monitoring/grafana`

## Pre-configured Dashboards

The monitoring stack comes with pre-configured dashboards for:
- System overview (CPU, memory, disk)
- Container metrics
- Log analysis
- Service health status

## Integration with Free Compute Node

The monitoring stack integrates with the existing Free Compute Node services:
- The router service exposes metrics for Prometheus
- Docker logs are captured by Loki
- System metrics are collected by node_exporter
- Container metrics are collected by cAdvisor

## Rollback

To remove the monitoring stack:

```bash
/opt/freecompute-data/rollback-monitoring.sh
```
