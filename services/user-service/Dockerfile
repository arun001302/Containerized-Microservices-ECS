# Use official Node.js runtime as base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["npm", "start"]
```

**Dockerfile Explanation**:
- **FROM node:18-alpine**: Uses lightweight Alpine Linux with Node.js
- **WORKDIR /app**: Sets working directory inside container
- **npm ci --only=production**: Installs only production dependencies (faster, more reliable than npm install)
- **Non-root user**: Security best practice - containers shouldn't run as root
- **HEALTHCHECK**: Docker can automatically check if container is healthy
- **EXPOSE 3000**: Documents which port the app uses

---

### **5. `services/user-service/.dockerignore`**
```
node_modules
npm-debug.log
.env
.git
.gitignore
README.md
.dockerignore