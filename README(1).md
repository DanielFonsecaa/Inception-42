# Inception

*This project has been created as part of the 42 curriculum by [your_login].*

## Description

**Inception** is a system administration project that focuses on expanding your knowledge of Docker and containerization. The project requires you to set up a complete infrastructure using Docker Compose, consisting of three interconnected services: NGINX, WordPress with PHP-FPM, and MariaDB. The goal is to create a production-like environment with proper networking, persistent storage, and security best practices, all orchestrated within a virtual machine.

This project teaches fundamental concepts of:
- Docker containerization and image building
- Docker Compose orchestration
- Networking between containers
- Data persistence with volumes
- SSL/TLS encryption
- Environment variable management and secrets
- System administration fundamentals

## Project Goals

1. Deploy a multi-container application using Docker Compose
2. Understand the role of each service in a web application stack
3. Implement security best practices (TLS encryption, secrets management)
4. Learn about data persistence in containerized environments
5. Develop infrastructure-as-code skills
6. Practice writing Dockerfiles with best practices in mind

## Technical Architecture

### Infrastructure Overview

The Inception project requires the following architecture:

```
┌─────────────────────────────────────────────────────┐
│                   Host Machine                       │
├─────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────┐   │
│  │          Docker Network (Isolated)            │   │
│  │  ┌──────────────┐  ┌──────────────┐          │   │
│  │  │   NGINX      │  │   WordPress  │          │   │
│  │  │  (TLS 443)   │  │  + PHP-FPM   │          │   │
│  │  └──────────────┘  └──────────────┘          │   │
│  │         │                  │                  │   │
│  │         └──────────┬───────┘                  │   │
│  │                    │                          │   │
│  │          ┌─────────▼────────┐                │   │
│  │          │     MariaDB      │                │   │
│  │          │    (Database)    │                │   │
│  │          └──────────────────┘                │   │
│  └──────────────────────────────────────────────┘   │
│                      │                               │
│        ┌─────────────┴──────────────┐                │
│        │          Volumes          │                │
│  ┌─────▼──────┐            ┌────────▼──────┐        │
│  │ WordPress  │            │  MariaDB DB   │        │
│  │   Files    │            │    Database   │        │
│  └────────────┘            └───────────────┘        │
│  Located at /home/login/data                        │
└─────────────────────────────────────────────────────┘
```

### Services

#### 1. NGINX Container
- **Purpose**: Reverse proxy and web server
- **SSL/TLS**: Enforced TLSv1.2 or TLSv1.3 only
- **Port**: 443 (HTTPS only)
- **Role**: Single entrypoint to the infrastructure
- **Configuration**: Routes requests to WordPress container via docker network

#### 2. WordPress + PHP-FPM Container
- **Purpose**: Content management system and PHP application
- **Components**: WordPress application + PHP-FPM (no NGINX)
- **Database**: Communicates with MariaDB
- **Port**: Internal (9000 for PHP-FPM)
- **Persistent Storage**: WordPress files volume

#### 3. MariaDB Container
- **Purpose**: Relational database
- **Database**: Stores WordPress data
- **Port**: Internal (3306)
- **Persistent Storage**: Database volume
- **Users**: Two users (one administrator, no admin/Admin in username)

### Volumes

Two named Docker volumes handle persistent storage:

1. **WordPress Volume**: Contains all WordPress website files
   - Location on host: `/home/login/data/wordpress`
   - Mounted at: `/var/www/wordpress` (or configured path)

2. **Database Volume**: Contains MariaDB data
   - Location on host: `/home/login/data/mysql`
   - Mounted at: `/var/lib/mysql`

**Important**: Named volumes must be used (bind mounts prohibited)

### Docker Network

- Custom Docker network established between all containers
- Containers communicate via service names (internal DNS)
- No `host` networking or `--link` allowed
- Network isolation from host system

## Instructions

### Prerequisites

- Virtual Machine (Linux-based, preferably Debian or Ubuntu)
- Docker installed (`apt install docker.io`)
- Docker Compose installed (`apt install docker-compose`)
- Basic understanding of shell scripting
- Text editor for configuration files

### Directory Structure

Your project must follow this structure:

```
project_root/
├── Makefile                          # Main build orchestration
├── README.md                         # This file
├── USER_DOC.md                       # User documentation
├── DEV_DOC.md                        # Developer documentation
├── srcs/
│   ├── docker-compose.yml            # Docker Compose configuration
│   ├── .env                          # Environment variables (git ignored)
│   └── requirements/
│       ├── nginx/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   │   └── nginx.conf
│       │   └── tools/
│       │       └── (setup scripts)
│       ├── wordpress/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   └── tools/
│       │       └── (setup scripts)
│       ├── mariadb/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   │   └── my.cnf
│       │   └── tools/
│       │       └── (database initialization)
│       ├── bonus/                    # (Optional)
│       │   ├── redis/
│       │   ├── ftp/
│       │   └── ...
│       └── tools/                    # Shared utilities
└── secrets/                          # Credentials (git ignored)
    ├── credentials.txt
    ├── db_password.txt
    └── db_root_password.txt
```

### Getting Started

1. **Clone the repository**
   ```bash
   git clone <your_repo_url>
   cd inception
   ```

2. **Configure environment variables**
   ```bash
   # Edit srcs/.env with your login and settings
   cp srcs/.env.example srcs/.env
   # Edit the .env file with your credentials
   ```

3. **Set up secrets** (if using Docker secrets)
   ```bash
   mkdir -p secrets/
   # Create credential files (should be git ignored)
   ```

4. **Create the data directory**
   ```bash
   mkdir -p /home/$USER/data
   ```

5. **Update your hosts file**
   ```bash
   # Add to /etc/hosts:
   127.0.0.1 yourlogin.42.fr
   ```

6. **Build and run the infrastructure**
   ```bash
   make
   # or
   make build
   ```

7. **View running containers**
   ```bash
   docker ps
   ```

8. **Access the website**
   ```
   https://yourlogin.42.fr
   ```

### Makefile Commands

The Makefile must provide the following targets:

```bash
make all       # Build and start all containers (default)
make build     # Build all Docker images
make up        # Start all containers
make down      # Stop all containers
make re        # Clean and rebuild everything
make clean     # Stop containers and remove volumes
make fclean    # Complete clean (remove images too)
make logs      # View container logs
make ps        # List running containers
```

### Key Configuration Points

#### Environment Variables

Create a `.env` file in `srcs/`:

```env
# Domain configuration
DOMAIN_NAME=yourlogin.42.fr

# MySQL/MariaDB
MYSQL_DATABASE=wordpress
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=your_secure_user_password

# WordPress
WP_TITLE=My Website
WP_ADMIN_USER=admin_user_name
WP_ADMIN_PASSWORD=your_secure_admin_password
WP_ADMIN_EMAIL=admin@example.com
WP_URL=https://yourlogin.42.fr

# Optional
WP_LANGUAGE=en_US
MYSQL_PORT=3306
```

**Important**: Do NOT commit `.env` file with real credentials to git.

#### Docker Secrets (Recommended)

For production-like security, use Docker secrets:

```bash
# Create secrets
echo "your_password" | docker secret create db_password -

# Reference in docker-compose.yml:
secrets:
  db_password:
    file: ./secrets/db_password.txt
```

#### TLS/SSL Certificate

You must generate a self-signed certificate for NGINX:

```bash
# In your nginx tools/setup script:
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/nginx.key \
  -out /etc/nginx/ssl/nginx.crt \
  -subj "/CN=yourlogin.42.fr"
```

#### WordPress Database Users

Two users must exist in MariaDB:
- **Administrator**: Username cannot contain "admin" or "administrator"
  - Example: `webmaster`, `owner`, `root_user`
- **Regular User**: For WordPress operations
  - Example: `wordpress`, `wp_user`

## Key Requirements

### Mandatory Requirements

✅ **Virtual Machine**: Project must run in a VM, not on the host machine

✅ **Docker Compose**: Use `docker-compose.yml` for orchestration

✅ **Image Names**: Docker image names must match service names

✅ **Dedicated Containers**: Each service in its own container

✅ **Alpine/Debian Base**: Use penultimate stable versions (not latest tag)

✅ **Custom Dockerfiles**: Write all Dockerfiles yourself

✅ **No Pre-built Images**: Cannot pull from Docker Hub (except Alpine/Debian base)

✅ **TLS Enforcement**: NGINX with TLSv1.2 or TLSv1.3 only

✅ **Named Volumes**: Use Docker named volumes (NOT bind mounts)

✅ **Volume Location**: `/home/login/data` on host machine

✅ **Docker Network**: Custom network connecting all containers

✅ **Auto-restart**: Containers restart on crash (`restart_policy: always`)

✅ **PID 1 Handling**: Proper daemons, no `tail -f`, `sleep infinity`, `bash`, `while true`

✅ **Environment Variables**: Use `.env` file for configuration

✅ **Docker Secrets**: Use for sensitive credentials

✅ **No Passwords in Dockerfiles**: All credentials via environment/secrets

✅ **Port 443 Only**: NGINX is sole entrypoint via HTTPS

✅ **Domain Name**: `login.42.fr` pointing to localhost

✅ **No network: host**: Forbidden, use Docker network instead

### Documentation Requirements

✅ **README.md**: Project overview, architecture, and usage

✅ **USER_DOC.md**: How to start/stop, access, manage credentials

✅ **DEV_DOC.md**: How to set up development environment

✅ **English Language**: All documentation in English

## Common Pitfalls to Avoid

### Docker Configuration
- ❌ Using `tail -f` or `sleep infinity` to keep containers running
- ❌ Using `latest` tag for base images
- ❌ Storing passwords in Dockerfile
- ❌ Using bind mounts instead of named volumes
- ❌ Logging into containers to run services manually
- ❌ Using `network: host` mode

### Security
- ❌ Committing `.env` or secret files to git
- ❌ Using weak passwords
- ❌ HTTP instead of HTTPS
- ❌ Using TLS versions older than 1.2

### Architecture
- ❌ Running NGINX inside WordPress container
- ❌ Running multiple services in one container
- ❌ No proper networking between containers
- ❌ WordPress/database files not in volumes

## Resources

### Docker Documentation
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dockerfile_best-practices/)
- [Docker Networking](https://docs.docker.com/network/)

### Container Best Practices
- [12 Factor App Methodology](https://12factor.net/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dockerfile_best-practices/)
- [Running Processes in Containers](https://docs.docker.com/config/containers/start-containers-automatically/)

### Technologies Used
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/docs/)
- [WordPress Documentation](https://wordpress.org/support/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)

### Security & SSL/TLS
- [OWASP TLS Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Protection_Cheat_Sheet.html)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

## Project Description: Design Choices

### Docker vs Virtual Machines

| Aspect | Docker | Virtual Machine |
|--------|--------|-----------------|
| **Startup Time** | Seconds | Minutes |
| **Resource Usage** | Minimal (MBs) | Heavy (GBs) |
| **Isolation** | OS-level | Complete OS |
| **Portability** | High (any Linux) | Lower (fixed resources) |
| **Use Case** | Microservices, dev/test | Legacy apps, full isolation |

**Our Choice**: Docker containers for this project because they are lightweight, fast to deploy, and ideal for microservices architecture.

### Secrets vs Environment Variables

| Feature | Environment Variables | Docker Secrets |
|---------|----------------------|-----------------|
| **Storage** | Plain text in .env | Encrypted at rest |
| **Scope** | Global or container | Task-specific |
| **Security** | Low (visible in ps) | High (encrypted) |
| **Use Case** | Non-sensitive config | Sensitive credentials |
| **Swarm Support** | No | Yes (native) |

**Our Choice**: Use Docker Secrets for passwords and sensitive data, Environment Variables for non-sensitive configuration.

### Docker Network vs Host Network

| Feature | Docker Network | Host Network |
|---------|---------------|--------------|
| **Isolation** | Complete | None |
| **Service Discovery** | Built-in DNS | Manual IP tracking |
| **Port Binding** | Flexible | Must avoid conflicts |
| **Security** | Better (isolated) | Worse (exposed) |
| **Complexity** | Moderate | Simple |

**Our Choice**: Custom Docker network for proper isolation and automatic service discovery between containers.

### Docker Volumes vs Bind Mounts

| Feature | Named Volumes | Bind Mounts |
|---------|---------------|------------|
| **Management** | Docker manages | User manages |
| **Performance** | Optimized | Variable |
| **Portability** | High | Low |
| **Driver Support** | Yes | No |
| **Backup** | Easier | Manual |

**Our Choice**: Named volumes for WordPress and database files for better portability, backup capabilities, and Docker management.

## Bonus Features

The bonus part includes optional enhancements:

- **Redis Cache**: Improve WordPress performance with caching layer
- **FTP Server**: Direct file access to WordPress volume
- **Static Website**: Showcase site in non-PHP language (HTML, Python, etc.)
- **Adminer**: Web interface for database management
- **Custom Service**: Any additional service with justification

**Note**: Bonus features are only evaluated if mandatory requirements are 100% complete and functional.

## Tips for Success

1. **Read Documentation**: Invest time in Docker and service documentation
2. **Test Incrementally**: Build and test each service independently first
3. **Use Proper Processes**: Understand how to run services as daemons properly
4. **Security First**: Implement TLS, secrets, and proper credential management from the start
5. **Peer Review**: Share your approach with peers and get feedback
6. **Document Everything**: Explain your choices in the README
7. **Keep It Simple**: Avoid over-engineering; stick to requirements

## Troubleshooting

### Container won't start
```bash
docker logs <container_name>  # Check error messages
docker ps -a                   # See all containers
```

### Can't access the website
```bash
# Verify NGINX is running and listening
docker exec nginx_container netstat -tlnp

# Check DNS resolution
cat /etc/hosts  # Ensure domain is mapped to 127.0.0.1

# Test HTTPS connection
curl -k https://yourlogin.42.fr
```

### Volumes not persisting
```bash
docker volume ls                              # List volumes
docker volume inspect <volume_name>           # Check volume details
ls -la /home/login/data                       # Verify host storage
```

### WordPress shows blank page
```bash
# Check database connection
docker exec wordpress_container wp db check

# View PHP error logs
docker logs wordpress_container
```

## File Organization

Ensure all required files are present:

```bash
.
├── Makefile ........................... Build orchestration
├── README.md .......................... This file
├── USER_DOC.md ........................ User guide
├── DEV_DOC.md ......................... Developer guide
├── srcs/
│   ├── docker-compose.yml ............ Docker orchestration
│   ├── .env ........................... Environment config (git ignored)
│   └── requirements/ ................. Service configurations
└── secrets/ ........................... Credential storage (git ignored)
```

## Important Notes

🔒 **Security**: Never commit `.env` or `secrets/` folder to git. Add them to `.gitignore`.

⚙️ **Customization**: Replace `yourlogin` with your actual 42 login in all configuration files.

📝 **Documentation**: Keep USER_DOC.md and DEV_DOC.md updated as you progress.

🐳 **Docker Practice**: This project is excellent for learning Docker. Take time to understand each component.

## Support & Learning

- Ask peers for help with specific Docker concepts
- Read official documentation for your services
- Test changes incrementally
- Document your decisions
- Share your solution approach with others

---

**Project Status**: [In Progress / Complete]  
**Last Updated**: [Date]  
**Version**: 5.2

---

*Remember: The goal is not just to complete the project, but to deeply understand containerization, networking, and infrastructure concepts.*
