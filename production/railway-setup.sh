#!/bin/bash
# Haley Railway Setup Script
# Run this after deployment to configure external services
# Usage: su frappe -c "/home/frappe/frappe-bench/railway-setup.sh"

set -e

cd /home/frappe/frappe-bench

echo "=== Haley Railway Setup ==="

# Get environment variables from Railway
SITE_NAME="${RFP_DOMAIN_NAME:-haley.localhost}"
ADMIN_PASS="${RFP_SITE_ADMIN_PASSWORD:-admin}"

# Database config from Railway MySQL service
DB_HOST="${MYSQLHOST:-localhost}"
DB_PORT="${MYSQLPORT:-3306}"
DB_USER="${MYSQLUSER:-root}"
DB_PASS="${MYSQLPASSWORD:-admin123}"
DB_ROOT_PASS="${MYSQL_ROOT_PASSWORD:-admin123}"

# Redis config from Railway Redis service
REDIS_URL="${REDIS_URL:-redis://localhost:6379}"

echo "Site Name: $SITE_NAME"
echo "DB Host: $DB_HOST:$DB_PORT"
echo "Redis: $REDIS_URL"

# Update site config to use external database
if [ "$DB_HOST" != "localhost" ]; then
    echo "Configuring external database..."
    bench set-config -g db_host "$DB_HOST"
    bench set-config -gp db_port "$DB_PORT"
fi

# Update Redis config
if [ "$REDIS_URL" != "redis://localhost:6379" ]; then
    echo "Configuring external Redis..."
    bench set-config -g redis_cache "$REDIS_URL"
    bench set-config -g redis_queue "$REDIS_URL"
    bench set-config -g redis_socketio "$REDIS_URL"
fi

# Create new site if domain changed
if [ "$SITE_NAME" != "haley.localhost" ]; then
    echo "Creating site: $SITE_NAME"

    # Check if using external DB
    if [ "$DB_HOST" != "localhost" ]; then
        bench new-site "$SITE_NAME" \
            --db-host "$DB_HOST" \
            --db-port "$DB_PORT" \
            --db-root-password "$DB_ROOT_PASS" \
            --admin-password "$ADMIN_PASS" \
            --no-mariadb-socket
    else
        bench new-site "$SITE_NAME" \
            --mariadb-root-password "$DB_ROOT_PASS" \
            --admin-password "$ADMIN_PASS"
    fi

    # Install apps
    bench --site "$SITE_NAME" install-app erpnext
    bench --site "$SITE_NAME" install-app enhanced_kanban_view

    # Set as default
    bench use "$SITE_NAME"
fi

# Run migrations
echo "Running migrations..."
bench --site "$SITE_NAME" migrate

# Clear cache
bench --site "$SITE_NAME" clear-cache

echo "=== Setup Complete ==="
echo "Site: $SITE_NAME"
echo "Admin Password: $ADMIN_PASS"
