#!/bin/bash
# Haley Entrypoint Script
# Configures frappe bench based on environment variables and starts the app

set -e

cd /home/frappe/frappe-bench

# Configure database connection
if [ -n "$DB_HOST" ]; then
    bench set-config -g db_host "$DB_HOST"
fi

if [ -n "$DB_PORT" ]; then
    bench set-config -gp db_port "$DB_PORT"
fi

# Configure Redis
if [ -n "$REDIS_CACHE" ]; then
    bench set-config -g redis_cache "redis://$REDIS_CACHE"
fi

if [ -n "$REDIS_QUEUE" ]; then
    bench set-config -g redis_queue "redis://$REDIS_QUEUE"
    bench set-config -g redis_socketio "redis://$REDIS_QUEUE"
fi

# Generate apps.txt if not exists
if [ ! -f "sites/apps.txt" ]; then
    ls -1 apps > sites/apps.txt
fi

# Create site if SITE_NAME and DB_ROOT_PASSWORD are provided and site doesn't exist
if [ -n "$SITE_NAME" ] && [ -n "$DB_ROOT_PASSWORD" ]; then
    if [ ! -d "sites/$SITE_NAME" ]; then
        echo "Creating site: $SITE_NAME"
        bench new-site "$SITE_NAME" \
            --db-root-password "$DB_ROOT_PASSWORD" \
            --admin-password "${ADMIN_PASSWORD:-admin}" \
            --no-mariadb-socket || true

        # Install apps
        bench --site "$SITE_NAME" install-app erpnext || true
        bench --site "$SITE_NAME" install-app enhanced_kanban_view || true

        # Run migrations
        bench --site "$SITE_NAME" migrate || true
    fi
fi

# Set default site if specified
if [ -n "$SITE_NAME" ]; then
    bench use "$SITE_NAME" || true
fi

# Determine what to run based on WORKER_TYPE env var
WORKER_TYPE="${WORKER_TYPE:-web}"

case "$WORKER_TYPE" in
    web)
        echo "Starting web server..."
        exec /home/frappe/frappe-bench/env/bin/gunicorn \
            --chdir=/home/frappe/frappe-bench/sites \
            --bind=0.0.0.0:${PORT:-8000} \
            --threads=4 \
            --workers=${GUNICORN_WORKERS:-2} \
            --worker-class=gthread \
            --worker-tmp-dir=/dev/shm \
            --timeout=120 \
            --preload \
            frappe.app:application
        ;;
    worker-short)
        echo "Starting short queue worker..."
        exec bench worker --queue short,default
        ;;
    worker-long)
        echo "Starting long queue worker..."
        exec bench worker --queue long,default,short
        ;;
    scheduler)
        echo "Starting scheduler..."
        exec bench schedule
        ;;
    socketio)
        echo "Starting socketio..."
        exec node /home/frappe/frappe-bench/apps/frappe/socketio.js
        ;;
    *)
        echo "Unknown WORKER_TYPE: $WORKER_TYPE"
        exit 1
        ;;
esac
