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
8. [Development Workflow](#development-workflow)
9. [Debugging & Inspection](#debugging--inspection)
10. [MariaDB Database Access](#mariadb-database-access)
11. [Generic Container Access](#generic-container-access)
12. [NGINX Port Verification](#nginx-port-verification)
13. [WordPress (PHP-FPM) Verification](#wordpress-php-fpm-verification)
14. [MariaDB Port Verification](#mariadb-port-verification)
15. [Port Configuration Reference](#port-configuration-reference)
16. [Contributing Guidelines](#contributing-guidelines)
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
├── .gitignore                          # Git ignore patterns
├── Makefile                            # Build orchestration
├── README.md                           # Project overview
├── USER_DOC.md                         # User guide
├── DEV_DOC.md                          # Developer guide (this file)
└── srcs/
    ├── docker-compose.yml              # Docker orchestration
    ├── .env.example                    # Template for .env
    └── requirements/
       ├── nginx/
       │   ├── Dockerfile
       │   └── conf/
       │       └── nginx.conf
       ├── wordpress/
       │   ├── Dockerfile
       │   ├── .dockerignore
       │   ├── conf/
       │   │   └── www.conf             # PHP-FPM config
       │   └── tools/
       │       └── wordpress-init.sh    # WordPress initialization
       └── mariadb/
           ├── Dockerfile
           ├── conf/
           │   └── mariadb.conf         # MySQL configuration
           └── tools/
               └── mariadb-init.sh      # Database initialization
```

## Environment Configuration

### Creating .env File

```bash
# Copy template
cp srcs/.env.example srcs/.env

# Edit with your values
nano srcs/.env
```

### Sensitive Data Management

```bash
# Add to .gitignore
echo "srcs/.env" >> .gitignore

# Verify nothing sensitive is committed
git check-ignore srcs/.env secrets/*
```

---

## Building the Infrastructure

### Makefile Targets

Create a comprehensive Makefile:

```makefile
.DEFAULT_GOAL := all

.PHONY: all build down re clean fclean logs help

RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
NC = \033[0m

COMPOSE_FILE = srcs/docker-compose.yml
DOCKER_COMPOSE = docker-compose -f $(COMPOSE_FILE)
DATA_PATH = ${HOME}/data

help:
	@echo ""
	@echo "$(YELLOW)Available commands:$(NC)"
	@echo "  $(GREEN)make all$(NC)       - Create volumes, build images and start containers"
	@echo "  $(GREEN)make down$(NC)      - Stop and remove containers"
	@echo "  $(GREEN)make re$(NC)        - Rebuild everything (down + clean + build + up)"
	@echo "  $(GREEN)make clean$(NC)     - Remove containers and images"
	@echo "  $(GREEN)make fclean$(NC)    - Remove everything including volumes and data"
	@echo "  $(GREEN)make logs$(NC)      - Show logs from all containers"
	@echo "  $(GREEN)make ps$(NC)        - Show container status"
	@echo ""

all: setup
	@echo "$(GREEN)✓ Inception project started successfully!$(NC)"
	$(DOCKER_COMPOSE) up -d --build
	@echo "$(YELLOW)Access: https://yourlogin.42.fr$(NC)"

setup:
	@echo "Created data folders."
	@sudo mkdir -p $(DATA_PATH)/mariadb
	@sudo mkdir -p $(DATA_PATH)/wordpress
	@sudo chmod 777 $(DATA_PATH)/mariadb
	@sudo chmod 777 $(DATA_PATH)/wordpress

up:
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(BLUE)► Starting all containers...$(NC)"; \
		$(DOCKER_COMPOSE) up -d --build; \
	else \
		echo "$(BLUE)► Starting container: $(SERVICE)...$(NC)"; \
		$(DOCKER_COMPOSE) up -d --build $(SERVICE); \
	fi

down:
	@echo "$(BLUE)► Stopping containers...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)✓ Containers stopped$(NC)"

clean: down
	@echo "$(BLUE)► Removing Docker images...$(NC)"
	@docker rmi $$(docker images -q -f reference='inception*') 2>/dev/null || true
	@echo "$(GREEN)✓ Images removed$(NC)"

fclean: clean
	@echo "$(RED)► FULL CLEANUP - Removing EVERYTHING...$(NC)"
	@$(DOCKER_COMPOSE) down -v --rmi all --remove-orphans >/dev/null 2>&1 || true
	@echo "$(BLUE)► Removing all Docker volumes...$(NC)"
	@docker volume prune -f >/dev/null 2>&1
	@echo "$(BLUE)► Removing all Docker images...$(NC)"
	@docker image prune -a -f >/dev/null 2>&1
	@echo "$(BLUE)► Removing all Docker networks...$(NC)"
	@docker network prune -f >/dev/null 2>&1
	@echo "$(BLUE)► Removing build cache...$(NC)"
	@docker builder prune -a -f >/dev/null 2>&1
	@echo "$(BLUE)► Fixing permissions...$(NC)"
	@sudo chown -R $(USER):$(USER) $(DATA_PATH) >/dev/null 2>&1 || true
	@echo "$(BLUE)► Removing persistent data...$(NC)"
	@rm -rf $(DATA_PATH)/* >/dev/null 2>&1
	@echo "$(GREEN)✓ COMPLETE CLEANUP DONE$(NC)"

re: fclean all
	@echo "$(GREEN)✓ Full rebuild completed$(NC)"

logs:
	@$(DOCKER_COMPOSE) logs -f
 
ps:
	@$(DOCKER_COMPOSE) ps

.PHONY: all setup stop down clean fclean re
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
docker inspect nginx_1 | grep -A 5 Config

# Test image independently
docker run --rm -it nginx:latest /bin/sh
```

---

## Docker Configuration Details

### docker-compose.yml Structure

```yaml
services:

  # =========================
  # MARIADB
  # =========================
  mariadb:
    build:
      context: ./requirements/mariadb
    container_name: mariadb
    networks:
      - inception
    expose:
      - "${MYSQL_PORT}"
    env_file:
      - .env
    volumes:
      - mariadb_volume:/var/lib/mysql
    restart: always

  # =========================
  # NGINX
  # =========================
  nginx:
    build:
      context: ./requirements/nginx
    container_name: nginx
    depends_on:
      - mariadb
    ports:
      - "443:443"
    networks:
      - inception
    env_file:
      - .env
    volumes:
      - wordpress_volume:/var/www/html
    restart: always

  # =========================
  # WORDPRESS
  # =========================
  wordpress:
    build:
      context: ./requirements/wordpress
    container_name: wordpress
    depends_on:
    - mariadb
    networks:
    - inception
    env_file:
    - .env
    volumes:
    - wordpress_volume:/var/www/html
    restart: always

# =========================
# NETWORK
# =========================
networks:
  inception:
    driver: bridge

# =========================
# VOLUMES
# =========================
volumes:
  mariadb_volume:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yourIntra/data/mariadb
```

### Key Configuration Points

#### Container Names
```yaml
# Must match service names for proper networking
container_name: nginx
container_name: wordpress
container_name: mariadb
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
FROM debian:bookworm

#install nginx and openssl (openssl is used to generate the security certificates)
RUN apt-get update && apt-get install -y nginx openssl

#removes default configuration from debian
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

#set up the SSL folder (to store the keys for the http connection)
RUN mkdir -p /etc/nginx/ssl

#generate the certificate (passport for the website)
RUN openssl req -x509 -nodes -out /etc/nginx/ssl/inception.crt -keyout /etc/nginx/ssl/inception.key -subj "/C=PT/ST=Porto/L=Porto/O=42/OU=42/CN=dda-fons.42.fr/UID=dda-fons"

#configure NGINX (copy the custom config into the container)
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

#start NGINX (in the foreground with daemon off so the container doesn't close)
CMD [ "nginx", "-g", "daemon off;" ]
```

### WordPress Dockerfile

```dockerfile
FROM debian:bookworm

# =========================
# DEPENDENCIES
# =========================
RUN apt-get update && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    curl \
    mariadb-client

# =========================
# WP-CLI
# =========================
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# =========================
# PHP-FPM CONFIG
# =========================
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# =========================
# REQUIRED DIRS
# =========================
RUN mkdir -p /run/php

# =========================
# WORKDIR
# =========================
WORKDIR /var/www/html

# =========================
# SCRIPT (your original one)
# =========================
COPY tools/wordpress-init.sh /usr/local/bin/wordpress-init.sh
RUN chmod +x /usr/local/bin/wordpress-init.sh

# =========================
# STARTUP
# =========================
ENTRYPOINT ["/usr/local/bin/wordpress-init.sh"]

CMD ["/usr/sbin/php-fpm8.2", "-F"]
```

### MariaDB Dockerfile

```dockerfile
FROM debian:bookworm

RUN apt-get update && apt-get install -y mariadb-server

#create folder for the database process to run
RUN mkdir -p /var/run/mysqld && chown -R mysql:mysql /var/run/mysqld

#this line transports the conf to the container
COPY conf/mariadb.conf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/mariadb-init.sh /usr/local/bin/mariadb-init.sh 

RUN chmod +x /usr/local/bin/mariadb-init.sh 

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mariadb-init.sh"]

#command that keeps container alive
CMD ["mysqld", "--user=mysql"]
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
docker inspect nginx         # Full details
docker logs nginx            # Container logs
docker stats nginx           # Resource usage
docker top nginx             # Running processes

# Container interaction
docker exec -it nginx sh     # Interactive shell
docker exec nginx ps aux     # Run command

# Start/Stop
docker start nginx
docker stop nginx
docker restart nginx
docker kill nginx            # Force stop

# Remove
docker rm nginx              # Remove container
docker rmi nginx:latest      # Remove image
```

### Debugging

```bash
# View detailed logs
docker logs -f --tail 50 wordpress

# Check environment variables
docker exec wordpress env

# View running processes
docker exec wordpress ps aux

# Check listening ports
docker exec nginx netstat -tlnp

# Test connectivity
docker exec wordpress ping mariadb

# Check file system
docker exec wordpress ls -la /var/www/wordpress/

# Execute SQL queries
docker exec mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD wordpress -e "SELECT * FROM wp_users;"

# Copy files in/out
docker cp wordpress:/var/www/wordpress/wp-config.php .
docker cp wp-config.php wordpress:/var/www/wordpress/
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
docker volume inspect wordpress

# Prune unused volumes
docker volume prune
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

### Port Mapping

```yaml
# Only NGINX exposes to host
ports:
  - "443:443"  # Host:Container

# Others communicate via network
```

---

## Development Workflow

### Making Code Changes

```bash
# 1. Modify files locally
vim srcs/requirements/nginx/conf/nginx.conf

# 2. Rebuild affected service
docker-compose -f srcs/docker-compose.yml build nginx

# 3. Restart container
docker-compose -f srcs/docker-compose.yml restart nginx

# 4. Verify changes
docker logs nginx

# 5. Test functionality
curl -k https://yourlogin.42.fr
```

## Debugging & Inspection

### Log Inspection

```bash
# View logs from all services
docker-compose -f srcs/docker-compose.yml logs

# Follow logs in real-time
docker-compose -f srcs/docker-compose.yml logs -f

# Specific service
docker logs wordpress -f

# Last N lines
docker logs --tail 100 wordpress

# Combine options
docker logs -f --tail 50 -t wordpress
```

---

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

---

## 🗄️ MariaDB Database Access

Enter MariaDB container:
```bash
docker exec -it mariadb bash
mariadb --user=dda -pddapass
```
Or direcrlty
```bash
docker exec -it mariadb mariadb --user=dda -pddapass
```

## 🧩 Generic Container Access
Enter any container:
```bash
docker exec -it <container_name>
```
Fallback (if bash is not available):
```bash
docker exec -it <container_name> sh
```
Example:
```bash
docker exec -it wordpress sh
```

## 🔒 NGINX Port Verification

Verify that NGINX is listening on the correct port and that Docker is mapping it correctly.

**1. Check listening port inside the container:**
```bash
ss -lnt | grep 443
```
*Expected output: 0.0.0.0:443 (listening)*

```bash
docker ps
```
*Expected mapping: 0.0.0.0:8443 -> 443*

Inspect container configuration:
```bash
docker inspect nginx | grep -A 5 Ports
```
Test HTTPS access:
```bash
curl -k https://localhost:8443
```
## ⚙️ WordPress (PHP-FPM) Verification

Verify port reachability:
```Bash
bash -c "</dev/tcp/wordpress/9000" && echo OK || echo FAIL
```
Check PHP-FPM configuration:
```bash
cat /etc/php/8.2/fpm/pool.d/www.conf | grep listen
```
*Expected output: listen = 0.0.0.0:9000*

## 🐬 MariaDB Port Verification
Enter the container:
```bash
docker exec -it mariadb bash
```
Test database connection:
```bash
# Replace <PORT>, <USER>, and <PASSWORD> with your credentials
mysql -h 127.0.0.1 -P <PORT> -u <USER> -p
```
    Note: If login succeeds, the port configuration is correct.

Quick network check:
```bash
# Replace 3309 with your custom port
bash -c "</dev/tcp/127.0.0.1/3309" && echo OK || echo FAIL
```


## 🔧 Port Configuration Reference
Use this table to locate where changes need to be applied:


<table>
  <thead>
    <tr>
      <th>Service</th>
      <th>Default Port</th>
      <th>Primary Files to Update</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>WordPress</td>
      <td>9000</td>
      <td><code>nginx.conf</code>, <code>www.conf</code>, <code>wordpress-init.sh</code></td>
    </tr>
    <tr>
      <td>NGINX</td>
      <td>443 → 8443</td>
      <td><code>docker-compose.yml</code></td>
    </tr>
    <tr>
      <td>MariaDB</td>
      <td>3306 → <em>Custom</em></td>
      <td><code>mariadb.conf</code>, <code>Dockerfile</code>, <code>.env</code></td>
    </tr>
  </tbody>
</table>

## Contributing Guidelines

1. **Code Style**: Follow existing patterns in Dockerfiles
2. **Comments**: Document complex configurations
3. **Testing**: Test changes in docker-compose before committing
4. **Git**: Commit frequently with meaningful messages
5. **Documentation**: Update README when making changes
