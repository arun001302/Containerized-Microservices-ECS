const express = require('express');
const helmet = require('helmet');
const morgan = require('morgan');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3001;
const SERVICE_NAME = 'product-service';
const VERSION = '1.0.0';

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// In-memory data store
let products = [
  { id: 1, name: 'Laptop', price: 999.99, category: 'Electronics', stock: 50 },
  { id: 2, name: 'Mouse', price: 29.99, category: 'Electronics', stock: 200 },
  { id: 3, name: 'Keyboard', price: 79.99, category: 'Electronics', stock: 150 },
  { id: 4, name: 'Monitor', price: 299.99, category: 'Electronics', stock: 75 }
];

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    service: SERVICE_NAME,
    version: VERSION,
    timestamp: new Date().toISOString()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    service: SERVICE_NAME,
    version: VERSION,
    endpoints: {
      health: '/health',
      products: '/api/products',
      product: '/api/products/:id',
      categories: '/api/products/categories'
    }
  });
});

// Get all products
app.get('/api/products', (req, res) => {
  const { category, minPrice, maxPrice } = req.query;
  
  console.log('GET /api/products - Fetching all products');
  
  let filteredProducts = [...products];
  
  if (category) {
    filteredProducts = filteredProducts.filter(p => 
      p.category.toLowerCase() === category.toLowerCase()
    );
  }
  
  if (minPrice) {
    filteredProducts = filteredProducts.filter(p => p.price >= parseFloat(minPrice));
  }
  
  if (maxPrice) {
    filteredProducts = filteredProducts.filter(p => p.price <= parseFloat(maxPrice));
  }
  
  res.json({
    success: true,
    data: filteredProducts,
    count: filteredProducts.length
  });
});

// Get product by ID
app.get('/api/products/:id', (req, res) => {
  const productId = parseInt(req.params.id);
  console.log(`GET /api/products/${productId} - Fetching product`);
  
  const product = products.find(p => p.id === productId);
  
  if (!product) {
    return res.status(404).json({
      success: false,
      error: 'Product not found'
    });
  }
  
  res.json({
    success: true,
    data: product
  });
});

// Get unique categories
app.get('/api/products/categories', (req, res) => {
  const categories = [...new Set(products.map(p => p.category))];
  
  res.json({
    success: true,
    data: categories,
    count: categories.length
  });
});

// Create new product
app.post('/api/products', (req, res) => {
  const { name, price, category, stock } = req.body;
  
  console.log('POST /api/products - Creating new product');
  
  if (!name || !price || !category) {
    return res.status(400).json({
      success: false,
      error: 'Name, price, and category are required'
    });
  }
  
  const newProduct = {
    id: products.length + 1,
    name,
    price: parseFloat(price),
    category,
    stock: stock || 0
  };
  
  products.push(newProduct);
  
  res.status(201).json({
    success: true,
    data: newProduct,
    message: 'Product created successfully'
  });
});

// Update product
app.put('/api/products/:id', (req, res) => {
  const productId = parseInt(req.params.id);
  const { name, price, category, stock } = req.body;
  
  console.log(`PUT /api/products/${productId} - Updating product`);
  
  const productIndex = products.findIndex(p => p.id === productId);
  
  if (productIndex === -1) {
    return res.status(404).json({
      success: false,
      error: 'Product not found'
    });
  }
  
  products[productIndex] = {
    ...products[productIndex],
    ...(name && { name }),
    ...(price && { price: parseFloat(price) }),
    ...(category && { category }),
    ...(stock !== undefined && { stock: parseInt(stock) })
  };
  
  res.json({
    success: true,
    data: products[productIndex],
    message: 'Product updated successfully'
  });
});

// Delete product
app.delete('/api/products/:id', (req, res) => {
  const productId = parseInt(req.params.id);
  
  console.log(`DELETE /api/products/${productId} - Deleting product`);
  
  const productIndex = products.findIndex(p => p.id === productId);
  
  if (productIndex === -1) {
    return res.status(404).json({
      success: false,
      error: 'Product not found'
    });
  }
  
  products.splice(productIndex, 1);
  
  res.json({
    success: true,
    message: 'Product deleted successfully'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`${SERVICE_NAME} v${VERSION} running on port ${PORT}`);
  console.log(`Health check available at http://localhost:${PORT}/health`);
});