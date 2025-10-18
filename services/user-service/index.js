const express = require('express');
const helmet = require('helmet');
const morgan = require('morgan');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;
const SERVICE_NAME = 'user-service';
const VERSION = '1.0.0';

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// In-memory data store (in production, use RDS/DynamoDB)
let users = [
  { id: 1, name: 'John Doe', email: 'john@example.com', role: 'admin' },
  { id: 2, name: 'Jane Smith', email: 'jane@example.com', role: 'user' },
  { id: 3, name: 'Bob Johnson', email: 'bob@example.com', role: 'user' }
];

// Health check endpoint (CRITICAL for ALB health checks)
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
      users: '/api/users',
      user: '/api/users/:id'
    }
  });
});

// Get all users
app.get('/api/users', (req, res) => {
  console.log('GET /api/users - Fetching all users');
  res.json({
    success: true,
    data: users,
    count: users.length
  });
});

// Get user by ID
app.get('/api/users/:id', (req, res) => {
  const userId = parseInt(req.params.id);
  console.log(`GET /api/users/${userId} - Fetching user`);
  
  const user = users.find(u => u.id === userId);
  
  if (!user) {
    return res.status(404).json({
      success: false,
      error: 'User not found'
    });
  }
  
  res.json({
    success: true,
    data: user
  });
});

// Create new user
app.post('/api/users', (req, res) => {
  const { name, email, role } = req.body;
  
  console.log('POST /api/users - Creating new user');
  
  if (!name || !email) {
    return res.status(400).json({
      success: false,
      error: 'Name and email are required'
    });
  }
  
  const newUser = {
    id: users.length + 1,
    name,
    email,
    role: role || 'user'
  };
  
  users.push(newUser);
  
  res.status(201).json({
    success: true,
    data: newUser,
    message: 'User created successfully'
  });
});

// Update user
app.put('/api/users/:id', (req, res) => {
  const userId = parseInt(req.params.id);
  const { name, email, role } = req.body;
  
  console.log(`PUT /api/users/${userId} - Updating user`);
  
  const userIndex = users.findIndex(u => u.id === userId);
  
  if (userIndex === -1) {
    return res.status(404).json({
      success: false,
      error: 'User not found'
    });
  }
  
  users[userIndex] = {
    ...users[userIndex],
    ...(name && { name }),
    ...(email && { email }),
    ...(role && { role })
  };
  
  res.json({
    success: true,
    data: users[userIndex],
    message: 'User updated successfully'
  });
});

// Delete user
app.delete('/api/users/:id', (req, res) => {
  const userId = parseInt(req.params.id);
  
  console.log(`DELETE /api/users/${userId} - Deleting user`);
  
  const userIndex = users.findIndex(u => u.id === userId);
  
  if (userIndex === -1) {
    return res.status(404).json({
      success: false,
      error: 'User not found'
    });
  }
  
  users.splice(userIndex, 1);
  
  res.json({
    success: true,
    message: 'User deleted successfully'
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