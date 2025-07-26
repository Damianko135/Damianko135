# 🐋 Docker Configurations

<div align="center">

![Docker Header](https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=0,74,173&height=150&section=header&text=Containerized%20Development&fontSize=28&fontColor=fff&animation=fadeIn&fontAlignY=35)

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Multi-Platform](https://img.shields.io/badge/Multi--Platform-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)](https://docs.docker.com/build/building/multi-platform/)

> *"Consistent development environments across all platforms!"*

</div>

---

## 📋 Table of Contents

- [🎯 Overview](#-overview)
- [📂 Project Structure](#-project-structure)
- [🚀 Quick Start](#-quick-start)
- [📦 Available Environments](#-available-environments)
- [⚙️ Configuration Guide](#️-configuration-guide)
- [🔧 Customization](#-customization)
- [🛠️ Troubleshooting](#️-troubleshooting)
- [📚 Best Practices](#-best-practices)

---

## 🎯 Overview

Welcome to my **Docker configurations collection**! This directory contains production-ready Docker Compose setups for various projects, designed to provide consistent, isolated development environments that work seamlessly across different platforms.

### 🌟 Why Use These Configurations?

- **🔄 Consistency** - Same environment across dev, staging, and production
- **⚡ Fast Setup** - Get projects running in minutes, not hours
- **🔒 Isolation** - No more "works on my machine" issues
- **📦 Portable** - Easy to share and deploy anywhere
- **🎯 Optimized** - Performance-tuned for development workflows

---

## 📂 Project Structure

```
📦 docker/
├── 🌐 first-project/              # Initial project setup
│   ├── 📄 compose.yml            # Main composition file
│   ├── 🔧 .env.example           # Environment variables template
│   └── 📁 config/                # Project-specific configurations
├── 🌱 groeneweide/               # Groeneweide project environment
│   ├── 📄 compose.yml            # Groeneweide-specific setup
│   └── 📁 data/                  # Persistent data volumes
├── 💼 portfolio-prototype/        # Portfolio development environment
│   ├── 📄 compose.yml            # Portfolio-specific composition
│   └── 📁 assets/                # Static assets and media
├── 📄 compose.yml                 # Master composition file
├── 🔧 .env.example               # Global environment template
└── 📖 README.md                  # This comprehensive guide
```

---

## 🚀 Quick Start

### Prerequisites

- **Docker** (v20.10+) - [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose** (v2.0+) - Usually included with Docker Desktop

### 1️⃣ Clone and Setup

```bash
# Clone the repository
git clone https://github.com/Damianko135/Damianko135.git
cd Damianko135/docker

# Copy environment template
cp .env.example .env
```

### 2️⃣ Choose Your Project

```bash
# Option 1: Run all projects (master composition)
docker compose up -d

# Option 2: Run specific project
cd first-project && docker compose up -d
cd groeneweide && docker compose up -d
cd portfolio-prototype && docker compose up -d
```

### 3️⃣ Access Your Applications

- **🌐 First Project**: http://localhost:3000
- **🌱 Groeneweide**: http://localhost:8080
- **💼 Portfolio**: http://localhost:4000

---

## 📦 Available Environments

<div align="center">

| Project | Description | Tech Stack | Status | Quick Start |
|:-------:|:------------|:----------:|:------:|:-----------:|
| 🌐 **First Project** | Initial development setup | Node.js, Express, MongoDB | ✅ Ready | `cd first-project && docker compose up` |
| 🌱 **Groeneweide** | Green energy project | Python, FastAPI, PostgreSQL | ✅ Ready | `cd groeneweide && docker compose up` |
| 💼 **Portfolio** | Personal portfolio prototype | Svelte, Vite, Nginx | ✅ Ready | `cd portfolio-prototype && docker compose up` |

</div>

### 🎯 Environment Features

- **🔄 Hot Reload** - Instant code changes reflection
- **📊 Health Checks** - Automatic service monitoring
- **💾 Persistent Data** - Data survives container restarts
- **🔒 Security** - Non-root users and secure configurations
- **📈 Scalable** - Easy horizontal scaling support

---

## ⚙️ Configuration Guide

### 🌐 First Project Configuration

<details>
<summary><strong>📄 compose.yml Overview</strong></summary>

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=${DATABASE_URL}
    volumes:
      - ./src:/app/src
      - node_modules:/app/node_modules
    depends_on:
      - database
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  database:
    image: mongo:5.0
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${DB_USER}
      - MONGO_INITDB_ROOT_PASSWORD=${DB_PASSWORD}
    volumes:
      - mongo_data:/data/db

volumes:
  node_modules:
  mongo_data:
```

**Key Features:**
- 🔄 Live code reloading
- 📊 Health monitoring
- 💾 Persistent MongoDB storage
- 🔒 Environment-based configuration
</details>

### 🌱 Groeneweide Configuration

<details>
<summary><strong>📄 compose.yml Overview</strong></summary>

```yaml
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile.api
    ports:
      - "8080:8080"
    environment:
      - ENVIRONMENT=development
      - DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
    volumes:
      - ./app:/app
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:14-alpine
    environment:
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

**Key Features:**
- 🐍 Python FastAPI backend
- 🐘 PostgreSQL database
- 🔴 Redis caching layer
- 🏥 Comprehensive health checks
</details>

### 💼 Portfolio Configuration

<details>
<summary><strong>📄 compose.yml Overview</strong></summary>

```yaml
version: '3.8'

services:
  frontend:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "4000:4000"
    environment:
      - NODE_ENV=development
      - VITE_API_URL=${API_URL}
    volumes:
      - ./src:/app/src
      - ./public:/app/public
      - node_modules:/app/node_modules
    command: npm run dev

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./dist:/usr/share/nginx/html
    depends_on:
      - frontend

volumes:
  node_modules:
```

**Key Features:**
- ⚡ Vite development server
- 🎨 Svelte framework
- 🌐 Nginx reverse proxy
- 📦 Optimized build process
</details>

---

## 🔧 Customization

### 🎯 Environment Variables

Create your `.env` file based on the template:

```bash
# Database Configuration
DB_USER=your_username
DB_PASSWORD=your_secure_password
DB_NAME=your_database_name

# Application Settings
NODE_ENV=development
API_URL=http://localhost:8080

# Security
JWT_SECRET=your_jwt_secret_key
ENCRYPTION_KEY=your_encryption_key

# External Services
REDIS_URL=redis://localhost:6379
SMTP_HOST=your_smtp_host
SMTP_PORT=587
```

### 🔄 Adding New Services

To add a new service to any composition:

```yaml
services:
  your-new-service:
    image: your-image:tag
    ports:
      - "PORT:PORT"
    environment:
      - ENV_VAR=value
    volumes:
      - ./local-path:/container-path
    depends_on:
      - existing-service
    networks:
      - your-network
```

### 🎨 Custom Dockerfiles

Example optimized Dockerfile:

```dockerfile
# Multi-stage build for production
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS runtime
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
WORKDIR /app
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --chown=nextjs:nodejs . .
USER nextjs
EXPOSE 3000
CMD ["npm", "start"]
```

---

## 🛠️ Troubleshooting

### 🐛 Common Issues

<details>
<summary><strong>🔍 Port Already in Use</strong></summary>

**Error:** `Port 3000 is already allocated`

**Solutions:**
```bash
# Check what's using the port
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Kill the process or change port in compose.yml
ports:
  - "3001:3000"  # Use different host port
```
</details>

<details>
<summary><strong>🐘 Database Connection Issues</strong></summary>

**Error:** `Connection refused` or `Database not ready`

**Solutions:**
```bash
# Check database health
docker compose ps
docker compose logs database

# Wait for database to be ready
depends_on:
  database:
    condition: service_healthy
```
</details>

<details>
<summary><strong>💾 Volume Permission Issues</strong></summary>

**Error:** `Permission denied` when accessing volumes

**Solutions:**
```bash
# Fix permissions (Linux/macOS)
sudo chown -R $USER:$USER ./data

# Use named volumes instead of bind mounts
volumes:
  - postgres_data:/var/lib/postgresql/data  # Named volume
  # - ./data:/var/lib/postgresql/data      # Bind mount
```
</details>

### 🔧 Useful Commands

```bash
# View logs
docker compose logs -f [service-name]

# Rebuild containers
docker compose build --no-cache

# Reset everything
docker compose down -v --remove-orphans
docker system prune -a

# Execute commands in running container
docker compose exec [service-name] bash

# Check resource usage
docker stats
```

---

## 📚 Best Practices

### ✅ Do's

- **🏷️ Use Specific Tags** - Avoid `latest` in production
- **🔒 Non-Root Users** - Run containers as non-root
- **💾 Named Volumes** - Use named volumes for data persistence
- **🏥 Health Checks** - Implement proper health monitoring
- **🔧 Multi-Stage Builds** - Optimize image sizes

### ❌ Don'ts

- **🚫 Hardcode Secrets** - Use environment variables
- **🚫 Run as Root** - Security risk
- **🚫 Large Images** - Optimize for size and security
- **🚫 Single Container** - Don't put everything in one container

### 🎯 Performance Tips

<div align="center">

| 💡 **Tip** | 📝 **Description** | 🎯 **Impact** |
|:----------:|:-------------------|:-------------:|
| **📦 Layer Caching** | Order Dockerfile commands by change frequency | 🚀 Faster builds |
| **🔄 Health Checks** | Implement proper service health monitoring | 🛡️ Better reliability |
| **💾 Volume Strategy** | Use appropriate volume types for data | 📈 Better performance |
| **🌐 Network Optimization** | Use custom networks for service isolation | 🔒 Enhanced security |

</div>

---

## 📊 Resource Monitoring

### 🎯 Container Health Dashboard

```bash
# Quick health check script
#!/bin/bash
echo "🐋 Docker Environment Status"
echo "================================"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "📊 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### 📈 Monitoring Setup

Add monitoring services to your composition:

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

---

<div align="center">

### 🎉 Happy Containerizing!

![Footer](https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=0,74,173&height=100&section=footer&animation=fadeIn)

**🐋 Build once, run anywhere!**

*Need help? Check the [Docker Documentation](https://docs.docker.com/) or reach out on [LinkedIn](https://www.linkedin.com/in/dkorver/)*

</div>