#!/bin/bash
set -e

# Check if database is already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "=== Initializing MariaDB data directory ==="
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db
fi

# Start MariaDB in the background with skip-grant-tables (allows root login without password)
echo "=== Starting MariaDB for configuration ==="
mysqld_safe &
MARIADB_PID=$!

# Wait for MariaDB to be ready
echo "=== Waiting for MariaDB to be ready ==="
for i in {1..3}; do
    if mysql -u root -e "SELECT 1" >/dev/null 2>&1; then
        echo "✓ MariaDB is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "✗ ERROR: MariaDB failed to start"
        exit 1
    fi
    echo "  Waiting... ($i/30)"
    sleep 1
done

# Initialize root password and create database
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "=== Creating database and users ==="
    
    mysql -u root << EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create application database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Create application user
CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Grant privileges
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';

-- Apply changes
FLUSH PRIVILEGES;
EOF

    echo "✓ Database configuration complete"
else
    echo "✓ Database already exists, verifying root password..."
    
    # Set/update root password
    mysql -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
fi

# Shutdown MariaDB gracefully
echo "=== Stopping MariaDB for restart ==="
mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown 2>/dev/null || true

# Wait for process to finish
wait $MARIADB_PID 2>/dev/null || true

echo "=== Starting MariaDB as main service ==="
exec "$@"
