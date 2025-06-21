# Monitoring and Logging System

The Free Compute Node includes a comprehensive monitoring and logging system that provides real-time insights into the health, performance, and behavior of all services.

## Overview

The monitoring and logging system consists of:

1. **Metrics Collection**: Prometheus for collecting and storing time-series metrics
2. **Log Aggregation**: Loki for collecting and querying logs
3. **Visualization**: Grafana for dashboards and visualization
4. **Container Monitoring**: cAdvisor for container-level metrics
5. **Application Metrics**: Custom metrics exposed by the router service
6. **Centralized Logging**: Structured logging with Winston and Loki integration

## Architecture

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Services  │         │ Collectors  │         │ Visualization│
│             │         │             │         │             │
│  ┌─────┐    │         │  ┌─────┐    │         │  ┌─────┐    │
│  │Nginx│    │         │  │Prom │    │  query  │  │     │    │
│  └─────┘    │  scrape │  │theus│    │◄────────┤  │     │    │
│  ┌─────┐    │◄────────┤  └─────┘    │         │  │     │    │
│  │MinIO│    │         │  ┌─────┐    │         │  │Graf │    │
│  └─────┘    │         │  │cAdv │    │         │  │ana  │    │
│  ┌─────┐    │  logs   │  │isor │    │         │  │     │    │
│  │Router    │◄────────┤  └─────┘    │         │  │     │    │
│  └─────┘    │         │  ┌─────┐    │  query  │  │     │    │
│  ┌─────┐    │         │  │Loki │    │◄────────┤  │     │    │
│  │Ollama│   │  logs   │  │     │    │         │  └─────┘    │
│  └─────┘    │◄────────┤  └─────┘    │         │             │
└─────────────┘         └─────────────┘         └─────────────┘
```

## Components

### 1. Prometheus

Prometheus is an open-source monitoring and alerting toolkit that collects metrics from configured targets at given intervals, evaluates rule expressions, displays the results, and can trigger alerts when specified conditions are observed.

- **Role**: Metrics collection and storage
- **Data Collection**: Scrapes metrics from services via HTTP endpoints
- **Storage**: Time-series database for storing metrics
- **Integration**: Collects metrics from router, cAdvisor, and node-exporter

### 2. Loki

Loki is a horizontally-scalable, highly-available, multi-tenant log aggregation system inspired by Prometheus but designed for logs instead of metrics.

- **Role**: Log aggregation and querying
- **Data Collection**: Receives logs via Promtail
- **Storage**: Stores log metadata and indexes
- **Integration**: Collects logs from all containers and services

### 3. Grafana

Grafana is an open-source platform for monitoring and observability that allows you to query, visualize, alert on, and understand your metrics.

- **Role**: Visualization and dashboards
- **Features**: Real-time metrics visualization, alerting, annotations
- **Dashboards**: Pre-configured dashboards for system, services, and logs
- **Integration**: Connects to Prometheus and Loki as data sources

### 4. cAdvisor

cAdvisor (Container Advisor) provides container users an understanding of the resource usage and performance characteristics of their running containers.

- **Role**: Container monitoring
- **Metrics**: CPU, memory, network, and disk usage per container
- **Integration**: Exposes metrics for Prometheus to collect

### 5. Node Exporter

Node Exporter is a Prometheus exporter that collects hardware and OS metrics from the host system.

- **Role**: Host system monitoring
- **Metrics**: CPU, memory, disk, network usage at host level
- **Integration**: Exposes metrics for Prometheus to collect

### 6. Router Metrics

The router service now exposes application-level metrics that provide insights into its operation.

- **Role**: Application monitoring
- **Metrics**: Request counts, durations, error rates, service health
- **Integration**: Exposes a `/metrics` endpoint for Prometheus

### 7. Centralized Logging

All services now use structured logging with Winston, which sends logs to both the console and Loki.

- **Role**: Log collection and aggregation
- **Format**: JSON structured logs with metadata
- **Integration**: Sends logs to Loki via winston-loki transport

## Dashboards

The monitoring system includes several pre-configured Grafana dashboards:

1. **System Overview**: Shows CPU, memory, disk, and network usage
2. **Container Metrics**: Shows resource usage by container
3. **Service Health**: Shows service status and health checks
4. **Log Analysis**: Shows log volume, errors, and patterns
5. **Request Metrics**: Shows HTTP request counts, durations, and error rates

## Configuration

The monitoring system can be configured through environment variables in the `.env` file:

```bash
# Monitoring Configuration
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

## Integration with Existing Health Check System

The monitoring system integrates with the existing health check system:

1. Health check results update Prometheus metrics
2. Service status is displayed in Grafana dashboards
3. Health check logs are sent to Loki
4. The dashboard shows both real-time and historical health data

## Security Considerations

- Prometheus, Loki, and cAdvisor are accessible only on localhost by default
- Grafana requires authentication
- All communication is unencrypted by default (assumes local network)
- Sensitive data is not logged or collected as metrics

## Alerting

Grafana can be configured to send alerts based on metrics and logs:

1. **Service Down Alerts**: Notify when a service becomes unavailable
2. **Resource Usage Alerts**: Notify when CPU, memory, or disk usage exceeds thresholds
3. **Error Rate Alerts**: Notify when error rates exceed thresholds
4. **Log Pattern Alerts**: Notify when specific log patterns are detected

## Extending the System

The monitoring system can be extended in several ways:

1. **Additional Exporters**: Add more Prometheus exporters for specific technologies
2. **Custom Dashboards**: Create custom Grafana dashboards for specific use cases
3. **Alert Destinations**: Configure additional alert destinations (email, Slack, etc.)
4. **Custom Metrics**: Add more application-specific metrics to the router service
