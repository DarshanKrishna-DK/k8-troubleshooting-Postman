const express = require('express');
const app = express();

// Environment variables (will come from K8s ConfigMap)
const PORT = process.env.PORT || 3000;
const APP_NAME = process.env.APP_NAME || 'K8s Demo API';
const DB_HOST = process.env.DB_HOST || 'localhost';
const FAILURE_RATE = parseFloat(process.env.FAILURE_RATE || '0'); // For demo: simulate failures

app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path} - Pod: ${process.env.HOSTNAME || 'unknown'}`);
  next();
});

// ============================================
// HEALTH CHECK ENDPOINTS (Critical for K8s)
// ============================================

// Liveness probe - is the app alive?
app.get('/health', (req, res) => {
  // Simulate intermittent failures for demo
  if (Math.random() < FAILURE_RATE) {
    console.log('❌ Health check FAILED (simulated)');
    return res.status(503).json({ 
      status: 'unhealthy', 
      error: 'Simulated failure',
      failureRate: FAILURE_RATE,
      timestamp: new Date().toISOString()
    });
  }
  console.log('✅ Health check passed');
  res.json({ 
    status: 'healthy', 
    pod: process.env.HOSTNAME || 'unknown',
    timestamp: new Date().toISOString() 
  });
});

// Readiness probe - is the app ready to receive traffic?
app.get('/ready', (req, res) => {
  // Check if "database" is connected (simulated)
  const dbConnected = DB_HOST !== 'invalid-host';
  
  if (!dbConnected) {
    console.log('❌ Readiness check FAILED - DB not connected');
    return res.status(503).json({ 
      ready: false, 
      error: 'Database not connected',
      dbHost: DB_HOST 
    });
  }
  
  console.log('✅ Readiness check passed');
  res.json({ 
    ready: true, 
    database: DB_HOST,
    pod: process.env.HOSTNAME || 'unknown'
  });
});

// ============================================
// MAIN API ENDPOINTS
// ============================================

// App info endpoint - shows which pod is responding
app.get('/api/info', (req, res) => {
  res.json({
    name: APP_NAME,
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    pod: process.env.HOSTNAME || 'unknown', // K8s sets HOSTNAME to pod name
    node: process.env.NODE_NAME || 'unknown',
    dbHost: DB_HOST,
    failureRate: FAILURE_RATE,
    timestamp: new Date().toISOString()
  });
});

// Products API - simulated e-commerce data
const products = [
  { id: 1, name: 'Kubernetes Guide', price: 49.99, category: 'Books', inStock: true },
  { id: 2, name: 'Postman Pro Tips', price: 29.99, category: 'Books', inStock: true },
  { id: 3, name: 'DevOps Handbook', price: 39.99, category: 'Books', inStock: false },
  { id: 4, name: 'Docker Stickers', price: 9.99, category: 'Merchandise', inStock: true },
  { id: 5, name: 'K8s Coffee Mug', price: 14.99, category: 'Merchandise', inStock: true }
];

app.get('/api/products', (req, res) => {
  const { category, inStock } = req.query;
  let filtered = [...products];
  
  if (category) {
    filtered = filtered.filter(p => p.category.toLowerCase() === category.toLowerCase());
  }
  if (inStock !== undefined) {
    filtered = filtered.filter(p => p.inStock === (inStock === 'true'));
  }
  
  res.json({ 
    products: filtered, 
    count: filtered.length,
    pod: process.env.HOSTNAME || 'unknown'
  });
});

app.get('/api/products/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const product = products.find(p => p.id === id);
  
  if (!product) {
    return res.status(404).json({ 
      error: 'Product not found',
      requestedId: id 
    });
  }
  
  res.json({
    ...product,
    pod: process.env.HOSTNAME || 'unknown'
  });
});

// ============================================
// TROUBLESHOOTING TEST ENDPOINTS
// ============================================

// Slow endpoint - for timeout testing
app.get('/api/slow', async (req, res) => {
  const delay = parseInt(req.query.delay) || 5000;
  console.log(`⏳ Slow endpoint called, delaying ${delay}ms`);
  
  await new Promise(resolve => setTimeout(resolve, delay));
  
  res.json({ 
    message: 'Slow response completed', 
    delay,
    pod: process.env.HOSTNAME || 'unknown',
    timestamp: new Date().toISOString()
  });
});

// Error endpoint - always fails
app.get('/api/error', (req, res) => {
  console.log('💥 Error endpoint called');
  res.status(500).json({ 
    error: 'Intentional server error for testing',
    pod: process.env.HOSTNAME || 'unknown',
    timestamp: new Date().toISOString()
  });
});

// Memory hog endpoint - for resource limit testing
app.get('/api/memory-hog', (req, res) => {
  const sizeMB = parseInt(req.query.size) || 50;
  console.log(`🐷 Allocating ${sizeMB}MB of memory`);
  
  // Allocate memory (careful with this in production!)
  const data = Buffer.alloc(sizeMB * 1024 * 1024, 'x');
  
  res.json({
    message: `Allocated ${sizeMB}MB`,
    actualSize: data.length,
    pod: process.env.HOSTNAME || 'unknown'
  });
});

// CPU intensive endpoint
app.get('/api/cpu-intensive', (req, res) => {
  const iterations = parseInt(req.query.iterations) || 1000000;
  console.log(`🔥 Running ${iterations} iterations`);
  
  let result = 0;
  for (let i = 0; i < iterations; i++) {
    result += Math.sqrt(i) * Math.random();
  }
  
  res.json({
    message: 'CPU intensive task completed',
    iterations,
    result: result.toFixed(2),
    pod: process.env.HOSTNAME || 'unknown'
  });
});

// Random failure endpoint - for chaos testing
app.get('/api/chaos', (req, res) => {
  const failChance = parseFloat(req.query.failChance) || 0.5;
  
  if (Math.random() < failChance) {
    const errorTypes = [
      { status: 500, error: 'Internal Server Error' },
      { status: 502, error: 'Bad Gateway' },
      { status: 503, error: 'Service Unavailable' },
      { status: 504, error: 'Gateway Timeout' }
    ];
    const randomError = errorTypes[Math.floor(Math.random() * errorTypes.length)];
    console.log(`💀 Chaos: Returning ${randomError.status}`);
    return res.status(randomError.status).json(randomError);
  }
  
  res.json({
    message: 'Chaos test passed',
    failChance,
    pod: process.env.HOSTNAME || 'unknown'
  });
});

// ============================================
// 404 HANDLER
// ============================================
app.use((req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    path: req.path,
    method: req.method,
    availableEndpoints: [
      'GET /health',
      'GET /ready', 
      'GET /api/info',
      'GET /api/products',
      'GET /api/products/:id',
      'GET /api/slow?delay=ms',
      'GET /api/error',
      'GET /api/chaos?failChance=0.5'
    ]
  });
});

// ============================================
// START SERVER
// ============================================
app.listen(PORT, () => {
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║        🚀 K8s Troubleshooting Demo API Started         ║');
  console.log('╠════════════════════════════════════════════════════════╣');
  console.log(`║  App Name:     ${APP_NAME.padEnd(39)}║`);
  console.log(`║  Port:         ${String(PORT).padEnd(39)}║`);
  console.log(`║  Pod:          ${(process.env.HOSTNAME || 'local').padEnd(39)}║`);
  console.log(`║  DB Host:      ${DB_HOST.padEnd(39)}║`);
  console.log(`║  Failure Rate: ${(FAILURE_RATE * 100 + '%').padEnd(39)}║`);
  console.log('╠════════════════════════════════════════════════════════╣');
  console.log('║  Endpoints:                                            ║');
  console.log('║    • GET /health        - Liveness probe               ║');
  console.log('║    • GET /ready         - Readiness probe              ║');
  console.log('║    • GET /api/info      - App information              ║');
  console.log('║    • GET /api/products  - List products                ║');
  console.log('║    • GET /api/slow      - Slow response test           ║');
  console.log('║    • GET /api/error     - Error test                   ║');
  console.log('║    • GET /api/chaos     - Random failures              ║');
  console.log('╚════════════════════════════════════════════════════════╝');
});

