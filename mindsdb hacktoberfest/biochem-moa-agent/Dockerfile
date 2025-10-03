# DietMOA MCP Server Dockerfile
# ==============================

# Multi-stage build for optimized image size
FROM python:3.11-slim as python-builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy Python requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --user -r requirements.txt

# Node.js stage
FROM node:18-slim as node-builder

WORKDIR /build

# Copy package files
COPY package*.json ./

# Install Node dependencies
RUN npm ci --only=production

# Final stage
FROM python:3.11-slim

# Install Node.js runtime
RUN apt-get update && apt-get install -y \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 dietmoa && \
    mkdir -p /app && \
    chown -R dietmoa:dietmoa /app

# Set working directory
WORKDIR /app

# Copy Python dependencies from builder
COPY --from=python-builder --chown=dietmoa:dietmoa /root/.local /home/dietmoa/.local

# Copy Node dependencies from builder
COPY --from=node-builder --chown=dietmoa:dietmoa /build/node_modules ./node_modules

# Copy application code
COPY --chown=dietmoa:dietmoa . .

# Update PATH for Python packages
ENV PATH=/home/dietmoa/.local/bin:$PATH

# Switch to non-root user
USER dietmoa

# Expose MCP server port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start MCP server
CMD ["npm", "start"]
