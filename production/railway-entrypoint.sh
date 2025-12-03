#!/bin/bash
# Haley Railway Entrypoint
# Starts MariaDB, Redis, and bench

set -e

echo "=== Starting Haley ==="

# Start MariaDB
echo "Starting MariaDB..."
sudo service mariadb start

# Start Redis
echo "Starting Redis..."
sudo service redis-server start

# Wait for services
sleep 2

# Start bench (runs all frappe processes via honcho)
echo "Starting Frappe/ERPNext..."
cd /home/frappe/frappe-bench
exec bench start
