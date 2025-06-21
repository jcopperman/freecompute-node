import express from 'express';
import promClient from 'prom-client';
import fs from 'fs/promises';
import { exec } from 'child_process';
import { promisify } from 'util';
import os from 'os';

const execAsync = promisify(exec);

// Create a Registry to register metrics
const register = new promClient.Registry();

// Add default metrics (CPU, memory, event loop, etc.)
promClient.collectDefaultMetrics({ register });

// Create custom metrics
const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status'],
  registers: [register]
});

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
  registers: [register]
});

const serviceHealth = new promClient.Gauge({
  name: 'service_health',
  help: 'Health status of services (1 = up, 0 = down)',
  labelNames: ['service'],
  registers: [register]
});

const nodeStatus = new promClient.Gauge({
  name: 'node_status',
  help: 'Overall node status (1 = healthy, 0 = unhealthy)',
  registers: [register]
});

const diskSpaceAvailable = new promClient.Gauge({
  name: 'disk_space_available_bytes',
  help: 'Available disk space in bytes',
  labelNames: ['path'],
  registers: [register]
});

const diskSpaceTotal = new promClient.Gauge({
  name: 'disk_space_total_bytes',
  help: 'Total disk space in bytes',
  labelNames: ['path'],
  registers: [register]
});

const memoryUsage = new promClient.Gauge({
  name: 'memory_usage_bytes',
  help: 'Memory usage in bytes',
  registers: [register]
});

const memoryTotal = new promClient.Gauge({
  name: 'memory_total_bytes',
  help: 'Total memory in bytes',
  registers: [register]
});

// HTTP request middleware to measure duration and count
export function metricsMiddleware(req, res, next) {
  const start = Date.now();
  
  // Record the end of the request
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestsTotal.inc({ method: req.method, route: req.route?.path || req.path, status: res.statusCode });
    httpRequestDuration.observe({ method: req.method, route: req.route?.path || req.path, status: res.statusCode }, duration);
  });
  
  next();
}

// Update service health metrics based on health check results
export function updateServiceHealthMetrics(services) {
  for (const [service, status] of Object.entries(services)) {
    serviceHealth.set({ service }, status.healthy ? 1 : 0);
  }
}

// Update node status metric
export function updateNodeStatusMetric(isHealthy) {
  nodeStatus.set(isHealthy ? 1 : 0);
}

// Update disk space metrics
export async function updateDiskMetrics(path = '/') {
  try {
    const { stdout } = await execAsync(`df -B1 ${path} | tail -1`);
    const parts = stdout.trim().split(/\s+/);
    const total = parseInt(parts[1], 10);
    const available = parseInt(parts[3], 10);
    
    diskSpaceTotal.set({ path }, total);
    diskSpaceAvailable.set({ path }, available);
  } catch (error) {
    console.error('Error updating disk metrics:', error);
  }
}

// Update memory metrics
export function updateMemoryMetrics() {
  const totalMem = os.totalmem();
  const freeMem = os.freemem();
  const usedMem = totalMem - freeMem;
  
  memoryTotal.set(totalMem);
  memoryUsage.set(usedMem);
}

// Metrics endpoint
export const metricsEndpoint = async (req, res) => {
  res.setHeader('Content-Type', register.contentType);
  res.end(await register.metrics());
};

// Schedule regular updates of system metrics
export function startMetricsCollection(interval = 60000) {
  // Initial update
  updateDiskMetrics('/');
  updateMemoryMetrics();
  
  // Schedule regular updates
  setInterval(() => {
    updateDiskMetrics('/');
    updateMemoryMetrics();
  }, interval);
}

export default {
  metricsMiddleware,
  metricsEndpoint,
  updateServiceHealthMetrics,
  updateNodeStatusMetric,
  updateDiskMetrics,
  updateMemoryMetrics,
  startMetricsCollection
};
