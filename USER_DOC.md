# USER_DOC.md - User & Administrator Guide

## Overview

This guide explains how to use and manage the Inception Docker infrastructure as an end user or system administrator. It covers starting/stopping the system, accessing services, managing credentials, and monitoring health.

---

## Table of Contents

1. [Services Overview](#services-overview)
2. [Quick Start](#quick-start)
3. [Accessing the System](#accessing-the-system)
4. [Managing Credentials](#managing-credentials)
5. [Starting & Stopping](#starting--stopping)
---

## Services Overview

Your Inception infrastructure provides three main services:

### 1. NGINX (Web Server)
- **Purpose**: Serves the website securely over HTTPS
- **Port**: 443 (HTTPS only)
- **Status**: Must be running for website access
- **URL**: https://yourlogin.42.fr
- **Protocol**: TLSv1.2 or TLSv1.3 (encrypted)

### 2. WordPress (Content Management)
- **Purpose**: Blog/website platform for creating and managing content
- **Admin Panel**: https://yourlogin.42.fr/wp-admin
- **Database**: Connected to MariaDB
- **Default Admin Access**: See credentials section
- **File Storage**: Persisted in Docker volume

### 3. MariaDB (Database)
- **Purpose**: Stores all website data, users, posts, settings
- **Port**: 3306 (internal, not exposed)
- **Access**: Only via WordPress or Adminer (if enabled)
- **Backup**: Persisted in Docker volume
- **Users**: Root user and WordPress user (see credentials)

---

## Quick Start

### First Time Setup

```bash
# 1. Navigate to project directory
cd /path/to/inception

# 2. Build and start all services
make

# 3. Wait for services to initialize (30-60 seconds)
sleep 10

# 4. Access the website
# Open browser and go to: https://yourlogin.42.fr

# 5. Accept self-signed certificate (development)
# Click "Advanced" or "Proceed Anyway"
```

---

## Accessing the System

### Website Access

1. **Via Browser**
   ```
   https://yourlogin.42.fr
   ```
   - Accept self-signed certificate when prompted
   - Normal WordPress website appears

2. **Via Command Line**
   ```bash
   # Test HTTPS connection
   curl -k https://yourlogin.42.fr
   
   # View NGINX status
   docker exec nginx_container nginx -T
   ```

### WordPress Admin Panel

1. **Login**
   ```
   URL: https://yourlogin.42.fr/wp-admin
   Username: [See credentials]
   Password: [See credentials]
   ```

2. **Admin Functions**
   - Create/edit posts and pages
   - Manage users
   - Configure site settings
   - Install plugins
   - Upload media

3. **First Time Login**
   - Navigate to `/wp-admin`
   - Use credentials from environment setup
   - Change password if desired (recommended)

---

## Managing Credentials

### Where Credentials Are Stored

```
Project Root/
│
└── srcs/
    └── .env                        # Environment configuration
```

### Viewing Credentials

```bash
# View environment variables
cat srcs/.env | grep -v "^#"
```

### Securing Credentials

1. **Add to .gitignore**
   ```bash
   echo "srcs/.env" >> .gitignore
   echo "secrets/" >> .gitignore
   ```
2. **Don't Share**
   - Never commit credentials to git
   - Never share passwords in chat/email
   - Never log into containers as root

---

## Starting & Stopping

### Start Services

```bash
# Start everything
make

# Start all containers
make up

# Or using docker-compose directly
docker-compose -f srcs/docker-compose.yml up -d

# Verify all containers are running
docker ps
# Should show: nginx, wordpress, mariadb containers
```

### Stop Services

```bash
# Graceful stop (data persists)
make down

# Or using docker-compose
docker-compose -f srcs/docker-compose.yml down

# Verify containers are stopped
docker ps
# Should show empty list
```

### Complete Rebuild

```bash
# Stop everything and remove containers (data persists)
make fclean

# Rebuild and start fresh
make re

# Or step by step
make down
make clean
make build
make up
```

### Check that the services are running correctly

After starting the system, verify all containers are running:

```bash
docker ps
```
