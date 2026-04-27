# DEV_DOC.md - Developer & Technical Guide

## Overview

This guide provides comprehensive technical information for developers setting up, modifying, and extending the Inception infrastructure. It covers environment setup, build processes, Docker configuration details, volume management, and development best practices.

---

## Table of Contents

1. [Prerequisites & Setup](#prerequisites--setup)
2. [Environment Configuration](#environment-configuration)
3. [Building the Infrastructure](#building-the-infrastructure)
4. [Docker Configuration Details](#docker-configuration-details)
5. [Dockerfile Best Practices](#dockerfile-best-practices)
6. [Container Management](#container-management)
7. [Volume Management](#volume-management)
8. [Networking](#networking)
9. [Development Workflow](#development-workflow)
10. [Debugging & Inspection](#debugging--inspection)
11. [Common Tasks](#common-tasks)

---

## Prerequisites & Setup

### System Requirements

```bash
# Minimum recommended
- Linux VM (Debian/Ubuntu preferred)
- 4GB RAM
- 20GB storage
- Docker Engine 20.10+
- Docker Compose 1.29+
```

### Installation Steps

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io docker-compose

# Verify Docker installation
docker --version
docker-compose --version

# Add user to docker group (optional, requires logout/login)
sudo usermod -aG docker $USER

# Test Docker
docker run hello-world
```

### Repository Structure

```
inception/
├── .gitignore                      # Git ignore patterns
├── Makefile                        # Build orchestration
├── README.md                       # Project overview
├── USER_DOC.md                     # User guide
├── DEV_DOC.md                      # Developer guide (this file)
├── srcs/
│   ├── docker-compose.yml          # Docker orchestration
│   ├── .env                        # Environment variables (NOT in git)
│   ├── .env.example                # Template for .env
│   └── requirements/
│       ├── nginx/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   │   ├── nginx.conf
│       │   │   └── ssl.conf        # SSL/TLS configuration
│       │   └── tools/
│       │       ├── setup.sh        # Entry script
│       │       └── certs.sh        # Certificate generation
│       ├── wordpress/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   │   └── www.conf        # PHP-FPM config
│       │   ├── tools/
│       │   │   ├── setup.sh        # WordPress initialization
│       │   │   └── wp-config.php   # WP configuration
│       │   └── (wordpress files)
│       ├── mariadb/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   │   └── my.cnf          # MySQL configuration
│       │   └── tools/
│       │       ├── setup.sh        # Database initialization
│       │       └── init.sql        # Initial SQL script
│       ├── bonus/                  # (Optional)
│       │   ├── redis/
│       │   ├── ftp/
│       │   └── ...
│       └── tools/                  # Shared utilities
│           └── utils.sh            # Common functions
└── secrets/                        # Credentials (NOT in git)
    ├── db_password.txt
    ├── db_root_password.txt
    └── credentials.txt
```

### Git Configuration

```bash
# Create .gitignore
cat > .gitignore << 'EOF'
# Environment and secrets
srcs/.env
srcs/.env.local
secrets/
*.key
*.crt

# Docker
.docker/
docker-compose.override.yml

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Backups and logs
*.log
*.bak
backup/
*_backup/
EOF

# Initialize repository
git init
git add .
git commit -m "Initial Inception project setup"
```

---

## Environment Configuration

### Creating .env File

```bash
# Copy template
cp srcs/.env.example srcs/.env

# Edit with your values
nano srcs/.env
```

### .env.example Template

```bash
# Domain Configuration
DOMAIN_NAME=yourlogin.42.fr

# MySQL Root
MYSQL_ROOT_PASSWORD=your_secure_root_password_here

# WordPress Database
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=your_secure_wordpress_password

# WordPress Admin
WP_TITLE=My Awesome Website
WP_ADMIN_USER=websiteowner
WP_ADMIN_PASSWORD=secure_admin_password
WP_ADMIN_EMAIL=admin@yourlogin.42.fr
WP_URL=https://yourlogin.42.fr

# Optional
WP_LANGUAGE=en_US
WP_LOCALE=en_US
TZ=UTC
```

### Environment Variable Usage in Dockerfiles

```dockerfile
# Reference variables in docker-compose.yml
FROM alpine:3.19
ENV DB_HOST=${DB_HOST:-mariadb}
ENV DB_USER=${MYSQL_USER}
ENV DB_PASS=${MYSQL_PASSWORD}

# Use in scripts
RUN echo "Database: $DB_HOST"
```

### Using Docker Secrets

```bash
# Create secret files
mkdir -p secrets/
echo "super_secure_password_123" > secrets/db_password.txt
echo "root_password_456" > secrets/db_root_password.txt
chmod 600 secrets/*

# Reference in docker-compose.yml
services:
  mariadb:
    secrets:
      - db_password
      - db_root_password
    environment:
      MYSQL_PASSWORD_FILE: /run/secrets/db_password

# Access in container
cat /run/secrets/db_password
```

### Sensitive Data Management

```bash
# Add to .gitignore
echo "srcs/.env" >> .gitignore
echo "secrets/" >> .gitignore

# Verify nothing sensitive is committed
git check-ignore srcs/.env secrets/*

# Check for accidentally committed secrets
git log -p | grep -i password

# Never add to git
git config core.protectntfs true
```

---

## Building the Infrastructure

### Makefile Targets

Create a comprehensive Makefile:

```makefile
.PHONY: all build up down re clean fclean logs ps help

all: build up

build:
	@echo "🔨 Building Docker images..."
	docker-compose -f srcs/docker-compose.yml build --no-cache

up:
	@echo "🚀 Starting containers..."
	docker-compose -f srcs/docker-compose.yml up -d
	@echo "✅ Containers started!"
	@echo "🌐 Access at: https://yourlogin.42.fr"

down:
	@echo "⛔ Stopping containers..."
	docker-compose -f srcs/docker-compose.yml down

restart:
	@echo "🔄 Restarting containers..."
	docker-compose -f srcs/docker-compose.yml restart

re: down build up

clean: down
	@echo "🧹 Removing containers and networks..."
	docker system prune -f

fclean: down
	@echo "🔥 Full cleanup - removing images and volumes..."
	docker-compose -f srcs/docker-compose.yml down -v
	docker system prune -af

logs:
	@docker-compose -f srcs/docker-compose.yml logs -f

ps:
	@docker-compose -f srcs/docker-compose.yml ps

help:
	@echo "Available targets:"
	@echo "  make all      - Build and start everything"
	@echo "  make build    - Build images only"
	@echo "  make up       - Start containers"
	@echo "  make down     - Stop containers"
	@echo "  make re       - Clean rebuild"
	@echo "  make clean    - Stop and clean"
	@echo "  make fclean   - Full cleanup"
	@echo "  make logs     - View logs"
	@echo "  make ps       - List containers"
```

### Build Process

```bash
# Full build from scratch
make

# Or step by step
make build    # Build images (takes 2-5 minutes)
make up       # Start containers
make ps       # Verify containers running

# Check logs for any startup errors
make logs
```

### Build Verification

```bash
# List built images
docker images | grep -E "nginx|wordpress|mariadb"

# Check image sizes
docker images --format "table {{.Repository}}\t{{.Size}}" | grep -E "nginx|wordpress|mariadb"

# Inspect image details
docker inspect inception_nginx_1 | grep -A 5 Config

# Test image independently
docker run --rm -it inception_nginx:latest /bin/sh
```

---

## Docker Configuration Details

### docker-compose.yml Structure

```yaml
version: '3.8'

services:
  # NGINX Service
  nginx:
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    image: inception_nginx:latest
    container_name: inception_nginx
    ports:
      - "443:443"
    volumes:
      - wordpress:/var/www/wordpress
    networks:
      - inception
    depends_on:
      - wordpress
    restart: always
    environment:
      DOMAIN_NAME: ${DOMAIN_NAME}

  # WordPress Service
  wordpress:
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    image: inception_wordpress:latest
    container_name: inception_wordpress
    volumes:
      - wordpress:/var/www/wordpress
    networks:
      - inception
    depends_on:
      - mariadb
    restart: always
    environment:
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      DB_HOST: mariadb
      DB_USER: ${MYSQL_USER}
      DB_PASSWORD: ${MYSQL_PASSWORD}
      WP_ADMIN_USER: ${WP_ADMIN_USER}
      WP_ADMIN_PASSWORD: ${WP_ADMIN_PASSWORD}
      WP_URL: ${WP_URL}
      WP_TITLE: ${WP_TITLE}

  # MariaDB Service
  mariadb:
    build:
      context: ./requirements/mariadb
      dockerfile: Dockerfile
    image: inception_mariadb:latest
    container_name: inception_mariadb
    volumes:
      - mysql:/var/lib/mysql
    networks:
      - inception
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}

volumes:
  wordpress:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/wordpress
  mysql:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/mysql

networks:
  inception:
    driver: bridge
```

### Key Configuration Points

#### Container Names
```yaml
# Must match service names for proper networking
container_name: inception_nginx
container_name: inception_wordpress
container_name: inception_mariadb
```

#### Restart Policy
```yaml
# Auto-restart on crash
restart: always
```

#### Dependencies
```yaml
# Startup order
depends_on:
  - mariadb
  - wordpress
```

#### Port Mapping
```yaml
# Only NGINX exposes port 443
ports:
  - "443:443"  # External:Internal
```

---

## Dockerfile Best Practices

### NGINX Dockerfile

```dockerfile
# Use penultimate stable Alpine (not latest)
FROM alpine:3.19

# Install dependencies
RUN apk add --no-cache \
    nginx \
    openssl \
    bash

# Create SSL directory
RUN mkdir -p /etc/nginx/ssl

# Copy configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Setup scripts
COPY tools/setup.sh /tmp/setup.sh
RUN chmod +x /tmp/setup.sh

# Run setup (generates certificates, configures NGINX)
RUN /tmp/setup.sh

# Remove setup script
RUN rm /tmp/setup.sh

# Expose port
EXPOSE 443

# Start NGINX (not as daemon!)
CMD ["nginx", "-g", "daemon off;"]
```

### WordPress Dockerfile

```dockerfile
FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    php-fpm \
    php-mysql \
    php-xml \
    php-gd \
    php-curl \
    php-zip \
    wget \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy PHP-FPM configuration
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Download WordPress
RUN mkdir -p /var/www/wordpress && \
    wget -O /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz && \
    tar -xzf /tmp/wordpress.tar.gz -C /var/www/ && \
    mv /var/www/wordpress/* /var/www/wordpress/ && \
    rm /tmp/wordpress.tar.gz

# Setup scripts
COPY tools/setup.sh /tmp/setup.sh
RUN chmod +x /tmp/setup.sh

ENTRYPOINT ["/tmp/setup.sh"]
CMD ["php-fpm8.2", "-F"]
```

### MariaDB Dockerfile

```dockerfile
FROM alpine:3.19

# Install MariaDB
RUN apk add --no-cache \
    mariadb \
    mariadb-client \
    bash

# Create data directory
RUN mkdir -p /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql

# Copy configuration
COPY conf/my.cnf /etc/my.cnf

# Setup script
COPY tools/setup.sh /tmp/setup.sh
RUN chmod +x /tmp/setup.sh

# Initialize database
ENTRYPOINT ["/tmp/setup.sh"]
CMD ["mariadbd"]
```

### Dockerfile Best Practices

```dockerfile
# ✅ Good: Alpine base (small)
FROM alpine:3.19

# ❌ Bad: Latest tag (unpredictable)
FROM alpine:latest

# ✅ Good: Run as unprivileged user
RUN adduser -D -s /sbin/nologin webapp
USER webapp

# ❌ Bad: Run as root
RUN useradd -m appuser
# (then don't switch)

# ✅ Good: Use init/supervisor for processes
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# ❌ Bad: Hacky workarounds
CMD ["sh", "-c", "tail -f /dev/null"]

# ✅ Good: Multi-line RUN for layer reduction
RUN apk add --no-cache \
    nginx \
    php \
    && rm -rf /var/cache/apk/*

# ❌ Bad: Multiple RUN commands
RUN apk add nginx
RUN apk add php

# ✅ Good: .dockerignore to exclude unnecessary files
# (Put in .dockerignore: *.md, .git, .env)

# ✅ Good: Use secrets for sensitive data
RUN --mount=type=secret,id=db_pass \
    mysql -u root -p$(cat /run/secrets/db_pass)

# ❌ Bad: Passwords in Dockerfile
ENV DB_PASS=my_password
```

---

## Container Management

### Docker Commands

```bash
# List containers
docker ps                              # Running only
docker ps -a                           # All containers
docker ps -aq                          # Only IDs

# Container info
docker inspect inception_nginx         # Full details
docker logs inception_nginx            # Container logs
docker stats inception_nginx           # Resource usage
docker top inception_nginx             # Running processes

# Container interaction
docker exec -it inception_nginx sh     # Interactive shell
docker exec inception_nginx ps aux     # Run command

# Start/Stop
docker start inception_nginx
docker stop inception_nginx
docker restart inception_nginx
docker kill inception_nginx            # Force stop

# Remove
docker rm inception_nginx              # Remove container
docker rmi inception_nginx:latest      # Remove image
```

### Debugging

```bash
# View detailed logs
docker logs -f --tail 50 inception_wordpress

# Check environment variables
docker exec inception_wordpress env

# View running processes
docker exec inception_wordpress ps aux

# Check listening ports
docker exec inception_nginx netstat -tlnp

# Test connectivity
docker exec inception_wordpress ping mariadb

# Check file system
docker exec inception_wordpress ls -la /var/www/wordpress/

# Execute SQL queries
docker exec inception_mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD wordpress -e "SELECT * FROM wp_users;"

# Copy files in/out
docker cp inception_wordpress:/var/www/wordpress/wp-config.php .
docker cp wp-config.php inception_wordpress:/var/www/wordpress/
```

### Resource Management

```bash
# Monitor resource usage
docker stats

# Limit container resources in docker-compose.yml
services:
  wordpress:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

# Update running container
docker update --cpus 0.5 inception_wordpress
docker update --memory 512M inception_wordpress
```

---

## Volume Management

### Named Volume Configuration

```yaml
volumes:
  wordpress:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yourlogin/data/wordpress

  mysql:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yourlogin/data/mysql
```

### Volume Operations

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect inception_wordpress

# Create volume manually
docker volume create myvolume

# Remove volume
docker volume rm inception_wordpress

# Prune unused volumes
docker volume prune

# Check volume size
du -sh /home/yourlogin/data/wordpress
du -sh /home/yourlogin/data/mysql

# Backup volume
docker run --rm -v inception_wordpress:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/wordpress-backup.tar.gz -C /data .

# Restore volume
docker run --rm -v inception_wordpress:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/wordpress-backup.tar.gz -C /data

# Copy between volumes
docker run --rm \
  -v source_vol:/source \
  -v dest_vol:/dest \
  alpine cp -r /source/* /dest/
```

### Directory Permissions

```bash
# Create directories with correct permissions
mkdir -p /home/$USER/data/wordpress
mkdir -p /home/$USER/data/mysql

# Set ownership
sudo chown -R $USER:$USER /home/$USER/data

# Set permissions
chmod 755 /home/$USER/data
chmod 755 /home/$USER/data/wordpress
chmod 755 /home/$USER/data/mysql

# Verify
ls -la /home/$USER/data/
```

---

## Networking

### Network Inspection

```bash
# List networks
docker network ls

# Inspect network
docker network inspect inception

# Check network driver
docker network inspect inception | grep Driver

# View connected containers
docker network inspect inception | grep -A 20 Containers
```

### Service Discovery

```bash
# Containers can reach each other by service name
docker exec inception_wordpress \
  ping mariadb
# mariadb is resolved via internal DNS

docker exec inception_wordpress \
  ping nginx
# Works because they're on same network
```

### Network Debugging

```bash
# Test connectivity from container
docker exec inception_wordpress \
  wget -O- https://nginx:443

# Check open ports
docker exec inception_nginx \
  netstat -tlnp

# Check DNS resolution
docker exec inception_wordpress \
  nslookup mariadb

# Trace network routes
docker exec inception_wordpress \
  traceroute mariadb
```

### Port Mapping

```yaml
# Only NGINX exposes to host
ports:
  - "443:443"  # Host:Container

# Others communicate via network
# wordpress port 9000 (PHP-FPM) not exposed
# mariadb port 3306 not exposed
```

---

## Development Workflow

### Making Code Changes

```bash
# 1. Modify files locally
nano srcs/requirements/nginx/conf/nginx.conf

# 2. Rebuild affected service
docker-compose -f srcs/docker-compose.yml build nginx

# 3. Restart container
docker-compose -f srcs/docker-compose.yml restart nginx

# 4. Verify changes
docker logs nginx

# 5. Test functionality
curl -k https://yourlogin.42.fr
```

### Iterative Development

```bash
# Watch for changes and rebuild
while inotifywait -r srcs/; do
  docker-compose -f srcs/docker-compose.yml restart
done

# Or use docker-compose in watch mode
docker-compose -f srcs/docker-compose.yml up --build
```

### Testing Strategy

```bash
# 1. Test individual services
docker-compose -f srcs/docker-compose.yml up -d mariadb
sleep 30  # Wait for DB to initialize
docker-compose -f srcs/docker-compose.yml exec mariadb mysqladmin ping

# 2. Test integration
docker-compose -f srcs/docker-compose.yml up -d
docker exec inception_wordpress wp db check

# 3. Test from outside
curl -k https://yourlogin.42.fr
curl -k https://yourlogin.42.fr/wp-admin

# 4. Test persistence
docker-compose -f srcs/docker-compose.yml down
docker-compose -f srcs/docker-compose.yml up -d
curl -k https://yourlogin.42.fr  # Should still work
```

---

## Debugging & Inspection

### Log Inspection

```bash
# View logs from all services
docker-compose -f srcs/docker-compose.yml logs

# Follow logs in real-time
docker-compose -f srcs/docker-compose.yml logs -f

# Specific service
docker logs inception_wordpress -f

# Last N lines
docker logs --tail 100 inception_wordpress

# Since specific time
docker logs --since 2024-01-01T00:00:00 inception_wordpress

# With timestamps
docker logs -t inception_wordpress

# Combine options
docker logs -f --tail 50 -t inception_wordpress
```

### Container Inspection

```bash
# Full container details
docker inspect inception_wordpress

# Specific fields
docker inspect -f '{{.NetworkSettings.Networks.inception.IPAddress}}' inception_wordpress

# All IP addresses
docker inspect -f '{{.NetworkSettings.IPAddress}}' inception_wordpress

# Image info
docker inspect inception_wordpress:latest | grep -i image

# Mount points
docker inspect inception_wordpress | grep -A 10 Mounts
```

### Interactive Debugging

```bash
# Open shell in running container
docker exec -it inception_wordpress /bin/bash

# Once inside:
# Check files
ls -la /var/www/wordpress/

# View configuration
cat /var/www/wordpress/wp-config.php

# Run WordPress CLI
wp user list
wp db query "SELECT * FROM wp_posts;"

# Check PHP info
php -i | grep -i mysql

# View PHP error log
tail -f /var/log/php-fpm.log
```

### Performance Monitoring

```bash
# Real-time resource usage
docker stats --no-stream

# CPU and memory
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Detailed inspection
docker inspect inception_wordpress | grep -i memory

# Process list inside container
docker exec inception_wordpress ps aux

# Disk usage inside container
docker exec inception_wordpress du -sh /var/www/wordpress
```

---

## Common Tasks

### Adding a New Service (Bonus)

```yaml
# 1. Add to docker-compose.yml
  redis:
    build:
      context: ./requirements/redis
      dockerfile: Dockerfile
    image: inception_redis:latest
    container_name: inception_redis
    networks:
      - inception
    restart: always

# 2. Create Dockerfile
mkdir -p srcs/requirements/redis
cat > srcs/requirements/redis/Dockerfile << 'EOF'
FROM alpine:3.19
RUN apk add --no-cache redis
EXPOSE 6379
CMD ["redis-server"]
EOF

# 3. Build and test
docker-compose -f srcs/docker-compose.yml build redis
docker-compose -f srcs/docker-compose.yml up -d redis
docker logs inception_redis
```

### Database Initialization

```bash
# Manual initialization script
docker exec inception_mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD << 'EOF'
CREATE DATABASE wordpress;
CREATE USER 'wp_user'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'%';
FLUSH PRIVILEGES;
EOF

# Or via script mounted in container
docker cp init.sql inception_mariadb:/tmp/
docker exec inception_mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD < /tmp/init.sql
```

### SSL Certificate Management

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /home/yourlogin/data/nginx.key \
  -out /home/yourlogin/data/nginx.crt \
  -subj "/CN=yourlogin.42.fr"

# Verify certificate
openssl x509 -in /home/yourlogin/data/nginx.crt -text -noout

# Check certificate expiration
openssl x509 -in /home/yourlogin/data/nginx.crt -noout -dates
```

### WordPress CLI Operations

```bash
# List WordPress users
docker exec inception_wordpress wp user list

# Create new user
docker exec inception_wordpress wp user create newuser newuser@example.com

# Update user password
docker exec inception_wordpress wp user update 1 --prompt=user_pass

# Install plugin
docker exec inception_wordpress wp plugin install woocommerce

# Activate plugin
docker exec inception_wordpress wp plugin activate woocommerce

# Export database
docker exec inception_wordpress wp db export /var/www/wordpress/backup.sql
docker cp inception_wordpress:/var/www/wordpress/backup.sql .
```

### Health Checks

```yaml
# Add to services in docker-compose.yml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

```bash
# Check health status
docker ps
# HEALTH column shows: healthy/unhealthy/starting

# Manual health check
docker exec inception_mariadb mysqladmin -u root ping

docker exec inception_wordpress curl -f http://localhost:9000/
```

---

## Troubleshooting Guide

### Build Failures

```bash
# Check Docker daemon
docker info

# Rebuild without cache
docker-compose -f srcs/docker-compose.yml build --no-cache

# Check Dockerfile syntax
docker build --no-cache .

# View build logs
docker build --no-cache -t test . 2>&1 | tee build.log
```

### Container Won't Start

```bash
# Check logs
docker logs inception_wordpress

# Run with TTY for interactive mode
docker run -it inception_wordpress:latest /bin/bash

# Check file permissions
docker exec inception_wordpress ls -la /var/www/wordpress/

# Check port availability
sudo netstat -tlnp | grep 443
```

### Network Issues

```bash
# Check network exists
docker network ls | grep inception

# Test DNS resolution
docker exec inception_wordpress nslookup mariadb

# Test connectivity
docker exec inception_wordpress ping mariadb

# Check firewall
sudo ufw status
```

---

## Contributing Guidelines

1. **Code Style**: Follow existing patterns in Dockerfiles
2. **Comments**: Document complex configurations
3. **Testing**: Test changes in docker-compose before committing
4. **Git**: Commit frequently with meaningful messages
5. **Documentation**: Update README when making changes

---

**Last Updated**: [Date]
**Version**: 5.2
**Audience**: Developers & System Administrators
