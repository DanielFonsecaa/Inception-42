# Inception

*This project has been created as part of the 42 curriculum by dda-fons.*

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
inception/
├── Makefile                    # Automation
├── .env                        # Global variables (DO NOT COMMIT!)
├── .gitignore                  # Ignore sensitive files
├── INSTALLATION.md             # Full setup guide
├── README.md                   # This file
└── srcs/
    ├── docker-compose.yml      # Orchestration
    ├── .env                    # Variable backup
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile      # NGINX image
        │   └── conf/
        │       └── nginx.conf   # TLS configuration
        |
        ├── wordpress/
        │   ├── Dockerfile      # WordPress image
        │   ├── conf/
        │   │   └── www.conf     # PHP-FPM configuration
        │   └── tools/
        │       └── wordpress-init.sh
        │
        └── mariadb/
            ├── Dockerfile      # MariaDB image
            ├── conf/
            │   └── mariadb.conf # MariaDB configuration
            └── tools/
                └── mariadb-init.sh
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


3. **Build and run the infrastructure**
   ```bash
   make
   # or
   make build
   ```

4. **View running containers**
   ```bash
   docker ps
   ```

5. **Access the website**
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


## Project Description: Design Choices

### Docker vs Virtual Machines

| Aspect | Docker | Virtual Machine |
|--------|--------|-----------------|
| **Startup Time** | Seconds | Minutes |
| **Resource Usage** | Minimal (MBs) | Heavy (GBs) |
| **Isolation** | OS-level | Complete OS |
| **Portability** | High (any Linux) | Lower (fixed resources) |
| **Use Case** | Microservices, dev/test | Legacy apps, full isolation |

**My Choice**: Docker containers for this project because they are lightweight, fast to deploy, and ideal for microservices architecture.

### Secrets vs Environment Variables

| Feature | Environment Variables | Docker Secrets |
|---------|----------------------|-----------------|
| **Storage** | Plain text in .env | Encrypted at rest |
| **Scope** | Global or container | Task-specific |
| **Security** | Low (visible in ps) | High (encrypted) |
| **Use Case** | Non-sensitive config | Sensitive credentials |
| **Swarm Support** | No | Yes (native) |

**My Choice**: Environment variables are simpler to configure and fully integrate with docker-compose, fitting the project’s local infrastructure scope without additional complexity.

### Docker Network vs Host Network

| Feature | Docker Network | Host Network |
|---------|---------------|--------------|
| **Isolation** | Complete | None |
| **Service Discovery** | Built-in DNS | Manual IP tracking |
| **Port Binding** | Flexible | Must avoid conflicts |
| **Security** | Better (isolated) | Worse (exposed) |
| **Complexity** | Moderate | Simple |

**My Choice**: Custom Docker network for proper isolation and automatic service discovery between containers.

### Docker Volumes vs Bind Mounts

| Feature | Named Volumes | Bind Mounts |
|---------|---------------|------------|
| **Management** | Docker manages | User manages |
| **Performance** | Optimized | Variable |
| **Portability** | High | Low |
| **Driver Support** | Yes | No |
| **Backup** | Easier | Manual |

**My Choice**: Named volumes for WordPress and database files for better portability, backup capabilities, and Docker management.
