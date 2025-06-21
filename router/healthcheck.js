import fetch from 'node-fetch';
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import metrics from './metrics.js';

const execAsync = promisify(exec);
const __dirname = dirname(fileURLToPath(import.meta.url));
const REGISTRY_PATH = join(__dirname, 'registry.json');

/**
 * Check if a service is available by making a HTTP request
 * @param {string} url - URL to check
 * @returns {Promise<boolean>} - True if service is available
 */
async function checkServiceAvailability(url) {
  try {
    console.log(`Checking service availability for ${url}`);
    const response = await fetch(url, { 
      method: 'GET',
      timeout: 3000, // 3 second timeout
    });
    console.log(`Service check for ${url}: ${response.ok ? 'OK' : 'Failed'}`);
    return response.ok;
  } catch (error) {
    console.error(`Health check failed for ${url}:`, error.message);
    return false;
  }
}

/**
 * Check if a Docker container is running
 * @param {string} containerName - Name of the container
 * @returns {Promise<boolean>} - True if container is running
 */
async function checkContainerStatus(containerName) {
  try {
    const { stdout } = await execAsync(`docker ps --filter "name=${containerName}" --format "{{.Status}}"`);
    return stdout.trim().startsWith('Up');
  } catch (error) {
    console.error(`Container check failed for ${containerName}:`, error.message);
    return false;
  }
}

/**
 * Check Ollama models and update registry
 * @param {Object} registry - The registry object
 * @returns {Promise<Object>} - Updated registry
 */
async function updateOllamaModels(registry) {
  if (registry.services.ollama && registry.services.ollama.status === 'active') {
    try {
      // Use the ollama container name if it exists, otherwise use localhost
      const ollamaHost = process.env.OLLAMA_ENABLED === 'true' ? 'ollama' : 'localhost';
      const response = await fetch(`http://${ollamaHost}:11434/api/tags`);
      if (response.ok) {
        const data = await response.json();
        registry.services.ollama.models = data.models || [];
      }
    } catch (error) {
      console.error('Failed to fetch Ollama models:', error.message);
    }
  }
  return registry;
}

/**
 * Check system resources
 * @returns {Promise<Object>} - Object with CPU, memory, and disk usage
 */
async function getSystemResources() {
  try {
    // Get memory info
    const { stdout: memInfo } = await execAsync('free -m | grep Mem');
    const memParts = memInfo.split(/\s+/);
    const totalMem = parseInt(memParts[1]);
    const usedMem = parseInt(memParts[2]);
    const memoryUsage = Math.round((usedMem / totalMem) * 100);
    
    // Get CPU info
    const { stdout: cpuInfo } = await execAsync('top -bn1 | grep "Cpu(s)" | sed "s/.*, *\\([0-9.]*\\)%* id.*/\\1/" | awk \'{print 100 - $1}\'');
    const cpuUsage = Math.round(parseFloat(cpuInfo));
    
    // Get disk info
    const { stdout: diskInfo } = await execAsync('df -h / | tail -1');
    const diskParts = diskInfo.split(/\s+/);
    const diskUsage = parseInt(diskParts[4].replace('%', ''));
    
    return {
      cpu: cpuUsage,
      memory: memoryUsage,
      disk: diskUsage
    };
  } catch (error) {
    console.error('Failed to get system resources:', error.message);
    return { cpu: null, memory: null, disk: null };
  }
}

/**
 * Perform health checks on all services and update registry
 * @param {Object} initialRegistry - The initial registry to update
 * @returns {Promise<Object>} - Updated registry
 */
export async function performHealthChecks(initialRegistry = null) {
  let registry;
  
  try {
    if (!initialRegistry) {
      const data = await fs.readFile(REGISTRY_PATH, 'utf8');
      registry = JSON.parse(data);
    } else {
      registry = initialRegistry;
    }
    
    // Update system resources
    try {
      const resources = await getSystemResources();
      registry.node.resources = resources;
    } catch (error) {
      console.error('Error updating system resources:', error);
    }
    
    // Check Nginx
    if (registry.services.nginx) {
      try {
        // Use container name when in Docker network
        const isNginxActive = await checkServiceAvailability('http://nginx:80/');
        registry.services.nginx.status = isNginxActive ? 'active' : 'inactive';
      } catch (error) {
        console.error('Error checking Nginx:', error);
        registry.services.nginx.status = 'inactive';
      }
      registry.services.nginx.lastChecked = new Date().toISOString();
    }
    
    // Check MinIO
    if (registry.services.minio) {
      try {
        // Use container name when in Docker network
        const isMinioActive = await checkServiceAvailability('http://minio:9000/minio/health/live');
        registry.services.minio.status = isMinioActive ? 'active' : 'inactive';
      } catch (error) {
        console.error('Error checking MinIO:', error);
        registry.services.minio.status = 'inactive';
      }
      registry.services.minio.lastChecked = new Date().toISOString();
    }
    
    // Check Ollama
    if (registry.services.ollama) {
      const ollamaPort = registry.services.ollama.port || process.env.OLLAMA_PORT || 11435;
      // Use the ollama container name if it exists, otherwise use localhost (for standalone Ollama)
      const ollamaHost = process.env.OLLAMA_ENABLED === 'true' ? 'ollama' : 'localhost'; 
      const ollamaUrl = `http://${ollamaHost}:11434/api/tags`;
      const isOllamaActive = await checkServiceAvailability(ollamaUrl);
      registry.services.ollama.status = isOllamaActive ? 'active' : 'inactive';
      registry.services.ollama.lastChecked = new Date().toISOString();
      
      // Update Ollama models if active
      if (isOllamaActive) {
        registry = await updateOllamaModels(registry);
      }
    }
    
    // Check Router (self)
    if (registry.services.router) {
      registry.services.router.status = 'active';
      registry.services.router.lastChecked = new Date().toISOString();
    }
    
    // Update the registry with the latest information
    registry.node.lastUpdated = new Date().toISOString();
    await fs.writeFile(REGISTRY_PATH, JSON.stringify(registry, null, 2));
    
    return registry;
  } catch (error) {
    console.error('Health check failed:', error);
    if (initialRegistry) return initialRegistry;
    // Return a basic registry if we couldn't load one
    return {
      node: {
        name: process.env.NODE_NAME || 'freecompute-node',
        role: process.env.NODE_ROLE || 'general',
        version: '0.1.0',
        uptime: new Date().toISOString(),
        lastUpdated: new Date().toISOString(),
        resources: { cpu: null, memory: null, disk: null }
      },
      services: {
        router: {
          status: 'active',
          port: process.env.ROUTER_PORT || 3000,
          url: '/api/',
          lastChecked: new Date().toISOString()
        }
      },
      mesh: {
        nodes: [],
        lastSynced: null
      }
    };
  }
}

/**
 * Start periodic health checks
 * @param {number} interval - Interval in milliseconds
 */
export function startHealthCheckScheduler(interval = 60000) {
  // Run first health check immediately
  performHealthChecks().then(results => {
    // Update metrics based on health check results
    metrics.updateServiceHealthMetrics(results.services);
    metrics.updateNodeStatusMetric(results.healthy);
  });
  
  // Schedule periodic health checks
  setInterval(async () => {
    try {
      const results = await performHealthChecks();
      
      // Update metrics based on health check results
      metrics.updateServiceHealthMetrics(results.services);
      metrics.updateNodeStatusMetric(results.healthy);
    } catch (error) {
      console.error(`[${new Date().toISOString()}] ❌ Health check error:`, error);
    }
  }, interval);
}
