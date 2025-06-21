import winston from 'winston';
import LokiTransport from 'winston-loki';

// Create a Winston logger with console and Loki transports
const createLogger = (service = 'router', lokiUrl = 'http://loki:3100') => {
  const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.json()
    ),
    defaultMeta: { service },
    transports: [
      // Console transport
      new winston.transports.Console({
        format: winston.format.combine(
          winston.format.colorize(),
          winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
          winston.format.printf(info => {
            return `${info.timestamp} ${info.level}: ${info.message}`;
          })
        )
      })
    ]
  });

  // Add Loki transport if enabled
  if (process.env.LOKI_ENABLED === 'true') {
    logger.add(new LokiTransport({
      host: lokiUrl,
      labels: { service, node: process.env.NODE_NAME || 'freecompute-node' },
      json: true,
      batching: true,
      interval: 5, // seconds
      replaceTimestamp: false,
      onConnectionError: (err) => console.error('Loki connection error:', err)
    }));
  }

  return logger;
};

// Create a middleware for Express to log HTTP requests
const expressLogger = (logger) => {
  return (req, res, next) => {
    const start = Date.now();
    const requestId = req.headers['x-request-id'] || Math.random().toString(36).substring(2, 15);
    
    // Add request ID to the request object for tracking
    req.requestId = requestId;
    
    // Log the request
    logger.info(`${req.method} ${req.originalUrl}`, {
      requestId,
      method: req.method,
      url: req.originalUrl,
      ip: req.ip,
      userAgent: req.get('User-Agent')
    });
    
    // Log response when finished
    res.on('finish', () => {
      const duration = Date.now() - start;
      const level = res.statusCode >= 400 ? 'warn' : 'info';
      
      logger[level](`${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`, {
        requestId,
        method: req.method,
        url: req.originalUrl,
        statusCode: res.statusCode,
        duration
      });
    });
    
    next();
  };
};

export { createLogger, expressLogger };
