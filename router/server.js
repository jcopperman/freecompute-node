import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs/promises';
import { performHealthChecks, startHealthCheckScheduler } from './healthcheck.js';
import metrics, { metricsMiddleware, metricsEndpoint, startMetricsCollection } from './metrics.js';
import { createLogger, expressLogger } from './logger.js';

// Create a logger instance
const logger = createLogger('router');

// Load environment variables
dotenv.config({ path: join(dirname(fileURLToPath(import.meta.url)), '../bootstrap/.env') });

// Configuration
const PORT = process.env.ROUTER_PORT || 3000;
const NODE_NAME = process.env.NODE_NAME || 'freecompute-node';
const NODE_ROLE = process.env.NODE_ROLE || 'general';
const API_KEY = process.env.ROUTER_AUTH_KEY || 'change_this_key';
const REGISTRY_PATH = join(dirname(fileURLToPath(import.meta.url)), 'registry.json');

// Initialize Express app
const app = express();

// Middleware
app.use(helmet());
app.use(cors({
  origin: [`http://localhost:8080`, `http://${NODE_NAME}:8080`],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'X-API-Key']
}));
app.use(express.json());
app.use(metricsMiddleware()); // Add metrics middleware
app.use(expressLogger(logger)); // Add request logging middleware

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Authentication middleware
const authenticate = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  
  if (!apiKey || apiKey !== API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  next();
};

// Load or create service registry
const loadRegistry = async () => {
  try {
    const data = await fs.readFile(REGISTRY_PATH, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    // Create default registry if it doesn't exist
    const defaultRegistry = {
      node: {
        name: NODE_NAME,
        role: NODE_ROLE,
        version: '0.1.0',
        uptime: new Date().toISOString(),
        lastUpdated: new Date().toISOString(),
        resources: {
          cpu: null,
          memory: null,
          disk: null
        }
      },
      services: {
        nginx: {
          status: process.env.NGINX_ENABLED !== 'false' ? 'active' : 'inactive',
          port: parseInt(process.env.NGINX_PORT || 8080),
          url: '/',
          lastChecked: new Date().toISOString()
        },
        minio: {
          status: process.env.MINIO_ENABLED !== 'false' ? 'active' : 'inactive',
          port: parseInt(process.env.MINIO_PORT || 9002),
          consolePort: parseInt(process.env.MINIO_CONSOLE_PORT || 9003),
          url: '/minio/',
          lastChecked: new Date().toISOString()
        },
        ollama: {
          status: process.env.OLLAMA_ENABLED === 'true' ? 'active' : 'inactive',
          port: parseInt(process.env.OLLAMA_PORT || 11435),
          url: '/ollama/',
          models: [],
          lastChecked: new Date().toISOString()
        },
        router: {
          status: 'active',
          port: PORT,
          url: '/api/',
          lastChecked: new Date().toISOString()
        }
      },
      mesh: {
        nodes: [],
        lastSynced: null
      }
    };
    
    await fs.writeFile(REGISTRY_PATH, JSON.stringify(defaultRegistry, null, 2));
    
    // Run an initial health check after creating the default registry
    return await performHealthChecks(defaultRegistry);
  }
};

// Update registry
const updateRegistry = async (registry) => {
  registry.node.lastUpdated = new Date().toISOString();
  await fs.writeFile(REGISTRY_PATH, JSON.stringify(registry, null, 2));
  return registry;
};

// API Routes

// Health check endpoint - no authentication required
app.get('/api/health', async (req, res) => {
  res.json({ status: 'ok', node: NODE_NAME });
});

// Node info
app.get('/api/node/info', authenticate, async (req, res) => {
  const registry = await loadRegistry();
  res.json(registry.node);
});

// List services
app.get('/api/services', authenticate, async (req, res) => {
  const registry = await loadRegistry();
  res.json(registry.services);
});

// Get specific service
app.get('/api/services/:serviceId', authenticate, async (req, res) => {
  const registry = await loadRegistry();
  const service = registry.services[req.params.serviceId];
  
  if (!service) {
    return res.status(404).json({ error: 'Service not found' });
  }
  
  res.json(service);
});

// Register a service
app.post('/api/services/register', authenticate, async (req, res) => {
  const { id, name, port, status, url } = req.body;
  
  if (!id || !name || !port) {
    return res.status(400).json({ error: 'Missing required fields' });
  }
  
  const registry = await loadRegistry();
  
  registry.services[id] = {
    name,
    status: status || 'active',
    port,
    url: url || `/${id}/`,
    registered: new Date().toISOString()
  };
  
  await updateRegistry(registry);
  
  res.status(201).json({ message: 'Service registered successfully', service: registry.services[id] });
});

// Mesh endpoints
app.get('/api/mesh/nodes', authenticate, async (req, res) => {
  const registry = await loadRegistry();
  res.json(registry.mesh.nodes);
});

// Health check endpoint - comprehensive system status with auth
app.get('/api/system/status', authenticate, async (req, res) => {
  // Perform a fresh health check
  const registry = await performHealthChecks();
  
  // Return comprehensive system status
  res.json({
    node: registry.node,
    services: registry.services,
    mesh: {
      nodeCount: registry.mesh.nodes.length,
      lastSynced: registry.mesh.lastSynced
    }
  });
});

app.post('/api/mesh/register', authenticate, async (req, res) => {
  const { nodeUrl, nodeName, capabilities } = req.body;
  
  if (!nodeUrl || !nodeName) {
    return res.status(400).json({ error: 'Missing required fields' });
  }
  
  const registry = await loadRegistry();
  
  // Check if node already exists
  const existingNodeIndex = registry.mesh.nodes.findIndex(node => node.url === nodeUrl);
  
  if (existingNodeIndex >= 0) {
    // Update existing node
    registry.mesh.nodes[existingNodeIndex] = {
      ...registry.mesh.nodes[existingNodeIndex],
      name: nodeName,
      capabilities: capabilities || registry.mesh.nodes[existingNodeIndex].capabilities,
      lastSeen: new Date().toISOString()
    };
  } else {
    // Add new node
    registry.mesh.nodes.push({
      url: nodeUrl,
      name: nodeName,
      capabilities: capabilities || [],
      registered: new Date().toISOString(),
      lastSeen: new Date().toISOString()
    });
  }
  
  registry.mesh.lastSynced = new Date().toISOString();
  await updateRegistry(registry);
  
  res.status(201).json({ message: 'Node registered successfully', meshSize: registry.mesh.nodes.length });
});

// Metrics endpoint (for Prometheus)
app.get('/metrics', metricsEndpoint);

// Initialize server and health checks
async function initServer() {
  try {
    // Run initial health checks
    const healthCheckResults = await performHealthChecks();
    
    // Update metrics based on health check results
    metrics.updateServiceHealthMetrics(healthCheckResults.services);
    metrics.updateNodeStatusMetric(healthCheckResults.healthy);
    
    // Start health check scheduler
    startHealthCheckScheduler();
    
    // Start metrics collection
    startMetricsCollection();
    
    logger.info(`Server running on port ${PORT}`);
    logger.info(`Health checks will run every ${HEALTH_CHECK_INTERVAL/1000} seconds`);
  } catch (error) {
    logger.error(`Failed to initialize server:`, error);
  }
}

// Start the server with initialization
initServer();
