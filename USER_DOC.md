# USER_DOC.md - User & Administrator Guide

## Overview

This guide explains how to use and manage the Inception Docker infrastructure as an end user or system administrator. It covers starting/stopping the system, accessing services, managing credentials, and monitoring health.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Services Overview](#services-overview)
3. [Accessing the System](#accessing-the-system)
4. [Managing Credentials](#managing-credentials)
5. [Starting & Stopping](#starting--stopping)
6. [Service Management](#service-management)
7. [Troubleshooting](#troubleshooting)
8. [FAQ](#faq)

---

## Quick Start

### First Time Setup

```bash
# 1. Navigate to project directory
cd /path/to/inception

# 2. Build and start all services
make

# 3. Wait for services to initialize (30-60 seconds)
sleep 60

# 4. Access the website
# Open browser and go to: https://yourlogin.42.fr

# 5. Accept self-signed certificate (development)
# Click "Advanced" or "Proceed Anyway"
```

### Daily Usage

```bash
# Start services (if not already running)
make up

# Check if everything is working
docker ps

# Stop services at end of day
make down

# View logs if something seems wrong
docker logs wordpress_container
```

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

### Database Access (if Adminer enabled)

```
https://yourlogin.42.fr/adminer/

Server: mariadb
Username: [See WordPress DB credentials]
Password: [See credentials]
Database: wordpress
```

---

## Managing Credentials

### Where Credentials Are Stored

```
Project Root/
├── secrets/
│   ├── db_root_password.txt       # Database root password
│   ├── db_password.txt             # WordPress DB user password
│   └── credentials.txt             # WordPress admin credentials
│
└── srcs/
    └── .env                        # Environment configuration
```

### Important Credentials

#### Database Root Access
```
Username: root
Password: [Check secrets/db_root_password.txt]
Access: Internal only (not exposed to web)
```

#### WordPress Database User
```
Username: [See MYSQL_USER in .env]
Password: [See secrets/db_password.txt]
Access: Used by WordPress internally
```

#### WordPress Administrator
```
Username: [See WP_ADMIN_USER in .env]
Password: [See secrets/credentials.txt]
Access: https://yourlogin.42.fr/wp-admin
```

### Viewing Credentials Safely

```bash
# View environment variables
cat srcs/.env | grep -v "^#"

# View secret files (if not encrypted)
cat secrets/db_password.txt
cat secrets/credentials.txt

# Check what's inside a running container
docker exec wordpress_container env | grep MYSQL
```

### Changing Passwords

#### WordPress Admin Password

```bash
# Option 1: Via WordPress Admin Panel
# Login to https://yourlogin.42.fr/wp-admin
# Go to Users > Your Profile > Change Password

# Option 2: Via Command Line
docker exec wordpress_container wp user update 1 --prompt=user_pass
```

#### Database Password

⚠️ **Warning**: Changing database password requires updating environment variables and redeploying.

```bash
# Backup current data
docker cp mariadb_container:/var/lib/mysql ./mysql_backup

# Update password in secrets/db_password.txt
echo "new_secure_password" > secrets/db_password.txt

# Update environment variable in srcs/.env
nano srcs/.env  # Edit MYSQL_PASSWORD

# Redeploy
make re
```

### Securing Credentials

1. **Add to .gitignore**
   ```bash
   echo "srcs/.env" >> .gitignore
   echo "secrets/" >> .gitignore
   ```

2. **File Permissions**
   ```bash
   chmod 600 srcs/.env
   chmod 700 secrets/
   chmod 600 secrets/*
   ```

3. **Don't Share**
   - Never commit credentials to git
   - Never share passwords in chat/email
   - Never log into containers as root

---

## Starting & Stopping

### Start Services

```bash
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

### Check Status

```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View container logs
docker logs nginx_container
docker logs wordpress_container
docker logs mariadb_container

# View last 50 lines with timestamps
docker logs --tail 50 -t wordpress_container

# Follow logs in real-time
docker logs -f nginx_container
```

---

## Service Management

### Restart a Single Service

```bash
# Restart without stopping others
docker-compose -f srcs/docker-compose.yml restart wordpress_container

# Or via docker directly
docker restart wordpress_container
```

### View Service Health

```bash
# NGINX Status
docker exec nginx_container service nginx status

# PHP-FPM Status
docker exec wordpress_container service php-fpm status

# MariaDB Status
docker exec mariadb_container mysqladmin -u root ping

# Check all port bindings
docker port nginx_container
```

### Disk Space & Volumes

```bash
# Check volume usage
docker volume ls

# Inspect specific volume
docker volume inspect inception_wordpress_volume

# Check actual disk space used
du -sh /home/yourlogin/data/

# Prune unused volumes (WARNING: deletes orphaned volumes)
docker volume prune
```

### Database Backup

```bash
# Create backup
docker exec mariadb_container mysqldump -u root -p[password] wordpress > backup.sql

# Or use volume copy
docker cp mariadb_container:/var/lib/mysql ./mysql_backup

# Restore from backup
docker exec -i mariadb_container mysql -u root -p[password] wordpress < backup.sql
```

---

## Troubleshooting

### Website Not Accessible

**Problem**: Cannot reach https://yourlogin.42.fr

**Solutions**:

```bash
# 1. Check containers are running
docker ps

# 2. Check domain is in hosts file
grep yourlogin.42.fr /etc/hosts
# Should show: 127.0.0.1 yourlogin.42.fr

# 3. Add domain if missing
echo "127.0.0.1 yourlogin.42.fr" | sudo tee -a /etc/hosts

# 4. Check NGINX is listening on port 443
docker exec nginx_container netstat -tlnp | grep 443

# 5. Verify certificate exists
docker exec nginx_container ls -la /etc/nginx/ssl/

# 6. Test connection directly
curl -k https://127.0.0.1:443
```

### Certificate Errors

**Problem**: "NET::ERR_CERT_AUTHORITY_INVALID" in browser

**Solution**: This is normal for self-signed certificates in development.
- Click "Advanced"
- Click "Proceed to yourlogin.42.fr (unsafe)"
- Or accept the certificate permanently

For production, use Let's Encrypt:
```bash
# Not required for this project, but good to know
# Use certbot: sudo apt install certbot
# Then: sudo certbot certonly --standalone -d yourlogin.42.fr
```

### WordPress Shows Blank Page

**Problem**: Website displays nothing or PHP errors

**Solutions**:

```bash
# 1. Check WordPress container logs
docker logs wordpress_container

# 2. Check PHP-FPM is running
docker exec wordpress_container service php-fpm status

# 3. Check database connection
docker exec wordpress_container wp db check

# 4. Check WordPress configuration
docker exec wordpress_container cat /var/www/wordpress/wp-config.php

# 5. Check file permissions
docker exec wordpress_container ls -la /var/www/wordpress/
```

### Database Connection Error

**Problem**: "Error establishing database connection"

**Solutions**:

```bash
# 1. Check MariaDB is running
docker ps | grep mariadb

# 2. Check MariaDB can accept connections
docker exec mariadb_container mysqladmin -u root -p[ROOT_PASSWORD] ping

# 3. Verify connection credentials
docker exec wordpress_container wp db check

# 4. Check MariaDB logs
docker logs mariadb_container

# 5. Restart MariaDB
docker-compose -f srcs/docker-compose.yml restart mariadb_container

# 6. Wait 30 seconds for MariaDB to initialize
sleep 30
docker ps
```

### Volumes Not Persisting

**Problem**: Data disappears after restart

**Solutions**:

```bash
# 1. Check volumes exist
docker volume ls

# 2. Inspect volume location
docker volume inspect inception_wordpress_volume

# 3. Check host directory
ls -la /home/yourlogin/data/

# 4. Verify volume is mounted in container
docker inspect inception_wordpress_container | grep -A 5 Mounts

# 5. Check file permissions
sudo ls -la /home/yourlogin/data/

# 6. Fix permissions if needed
sudo chown -R $USER:$USER /home/yourlogin/data
```

### High Memory/CPU Usage

**Problem**: System running slowly

**Solutions**:

```bash
# 1. Check container resource usage
docker stats

# 2. Check individual container
docker stats wordpress_container --no-stream

# 3. View detailed logs
docker logs mariadb_container | tail -20

# 4. If WordPress has too many processes
docker exec wordpress_container ps aux | wc -l

# 5. Restart affected container
docker-compose -f srcs/docker-compose.yml restart wordpress_container
```

---

## FAQ

### Q: How do I change the domain name?

A: The domain is configured in `srcs/.env` as `DOMAIN_NAME=yourlogin.42.fr`

```bash
# 1. Update .env
nano srcs/.env
# Change DOMAIN_NAME to your new domain

# 2. Update /etc/hosts
sudo nano /etc/hosts
# Update or add entry for new domain

# 3. Rebuild with new domain
make re
```

### Q: Can I access the database from my computer?

A: No, MariaDB is only exposed internally to the WordPress container. This is intentional for security. To access:

```bash
# Option 1: Via WordPress CLI inside container
docker exec wordpress_container wp db query "SELECT * FROM wp_users;"

# Option 2: Use Adminer if enabled as bonus
https://yourlogin.42.fr/adminer

# Option 3: Access inside container
docker exec -it mariadb_container mysql -u root -p
```

### Q: How do I backup my WordPress data?

A: Create backups of volumes:

```bash
# Backup WordPress files
docker run --rm -v inception_wordpress_volume:/data -v $(pwd):/backup \
  alpine tar czf /backup/wordpress-backup.tar.gz -C /data .

# Backup database
docker exec mariadb_container mysqldump -u wordpress -p wordpress > db-backup.sql

# Or copy volumes directly
sudo cp -r /home/yourlogin/data ~/backups/
```

### Q: Can I modify WordPress files inside the container?

A: Yes, but changes should persist via the volume:

```bash
# Edit file inside container
docker exec -it wordpress_container nano /var/www/wordpress/wp-config.php

# Or copy file out, edit, and copy back
docker cp wordpress_container:/var/www/wordpress/wp-config.php .
# Edit the file
docker cp wp-config.php wordpress_container:/var/www/wordpress/
```

### Q: How do I update WordPress plugins?

A: Via WordPress admin panel:

```
https://yourlogin.42.fr/wp-admin
→ Plugins
→ Check updates, click "Update Now"
```

Or via command line:

```bash
docker exec wordpress_container wp plugin update --all
```

### Q: What if a container crashes?

A: They should auto-restart due to `restart_policy: always`

```bash
# Check if container restarted
docker ps

# View restart history
docker inspect wordpress_container | grep RestartCount

# Check logs for crash reason
docker logs wordpress_container

# Manually restart if needed
docker restart wordpress_container
```

### Q: How do I clean up after the project?

A: Remove all components:

```bash
# Stop containers (data in /home/yourlogin/data persists)
make down

# Remove containers and images
make fclean

# Optional: Remove volumes (WARNING: deletes data)
docker volume prune

# Optional: Remove .env and secrets
rm srcs/.env
rm -rf secrets/

# Remove domain from hosts
sudo nano /etc/hosts
# Remove the yourlogin.42.fr line

# Optional: Remove data directory
sudo rm -rf /home/yourlogin/data
```

### Q: Is it safe to expose to the internet?

A: No, this is development-only:
- Uses self-signed certificates (not trusted)
- Has default/weak passwords
- Not hardened for production
- No firewall/rate limiting
- No backup strategy

For production, you would need:
- Let's Encrypt SSL certificates
- Strong password policies
- Security hardening
- Firewall rules
- Automated backups
- Monitoring/alerting

---

## Contact & Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Docker logs: `docker logs <container_name>`
3. Check README.md for architecture details
4. Ask peers in study group
5. Review official Docker documentation

---

**Last Updated**: [Date]
**Version**: 5.2
**Audience**: End Users & System Administrators
