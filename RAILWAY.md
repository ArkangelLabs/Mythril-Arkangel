# Haley Railway Deployment Guide

This guide covers deploying Haley to Railway.

## Prerequisites

1. A Railway account
2. Railway CLI installed (optional, for local management)

## Deployment Steps

### 1. Create Railway Project

1. Go to [Railway](https://railway.app)
2. Click "New Project" → "Deploy from GitHub repo"
3. Select your `Haley-Arkangel` repository

### 2. Add Required Services

After the initial deployment fails (expected - needs database), add these services:

#### MariaDB Database
1. Click "New" → "Database" → "MySQL" (Railway uses MySQL, compatible with MariaDB)
2. Note the connection variables Railway provides

#### Redis (2 instances needed)
1. Click "New" → "Database" → "Redis"
2. Rename to "redis-cache"
3. Repeat and create another Redis, rename to "redis-queue"

### 3. Configure Environment Variables

Click on your Haley service and add these variables:

```
# Database (from Railway MySQL service)
DB_HOST=${{MySQL.MYSQLHOST}}
DB_PORT=${{MySQL.MYSQLPORT}}
DB_ROOT_PASSWORD=${{MySQL.MYSQL_ROOT_PASSWORD}}

# Redis (from Railway Redis services)
REDIS_CACHE=${{redis-cache.REDISHOST}}:${{redis-cache.REDISPORT}}
REDIS_QUEUE=${{redis-queue.REDISHOST}}:${{redis-queue.REDISPORT}}

# Site Configuration
SITE_NAME=haley.railway.app
ADMIN_PASSWORD=your_admin_password

# Worker Type (default is web)
WORKER_TYPE=web
```

### 4. Deploy Additional Workers (Optional but Recommended)

For production, you need background workers. Create additional services from the same repo:

#### Scheduler
- Click "New" → "GitHub Repo" → select same repo
- Add env var: `WORKER_TYPE=scheduler`
- Add same DB_HOST, REDIS_* variables

#### Queue Worker
- Click "New" → "GitHub Repo" → select same repo
- Add env var: `WORKER_TYPE=worker-short`
- Add same DB_HOST, REDIS_* variables

### 5. First-Time Site Setup

After all services are running, access the web service shell:

```bash
railway run bash
```

Or use Railway's console feature, then run:

```bash
cd /home/frappe/frappe-bench
bench new-site your-site-name \
    --db-root-password $DB_ROOT_PASSWORD \
    --admin-password your_password \
    --no-mariadb-socket

bench --site your-site-name install-app erpnext
bench --site your-site-name install-app enhanced_kanban_view
bench --site your-site-name migrate
bench use your-site-name
```

## Environment Variables Reference

| Variable | Description | Required |
|----------|-------------|----------|
| `DB_HOST` | Database host | Yes |
| `DB_PORT` | Database port (default: 3306) | No |
| `DB_ROOT_PASSWORD` | Database root password | Yes |
| `REDIS_CACHE` | Redis cache host:port | Yes |
| `REDIS_QUEUE` | Redis queue host:port | Yes |
| `SITE_NAME` | Frappe site name | Yes |
| `ADMIN_PASSWORD` | Admin user password | Yes (first run) |
| `WORKER_TYPE` | web, scheduler, worker-short, worker-long, socketio | No (default: web) |
| `GUNICORN_WORKERS` | Number of gunicorn workers | No (default: 2) |
| `PORT` | Web server port | No (Railway sets this) |

## Architecture on Railway

```
┌─────────────────────────────────────────────────────────┐
│                     Railway Project                      │
├─────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │   Web    │  │ Scheduler│  │  Worker  │              │
│  │ (Haley)  │  │ (Haley)  │  │ (Haley)  │              │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘              │
│       │             │             │                     │
│       └─────────────┼─────────────┘                     │
│                     │                                   │
│       ┌─────────────┼─────────────┐                     │
│       ▼             ▼             ▼                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  MySQL   │  │  Redis   │  │  Redis   │              │
│  │    DB    │  │  Cache   │  │  Queue   │              │
│  └──────────┘  └──────────┘  └──────────┘              │
└─────────────────────────────────────────────────────────┘
```

## Costs

Railway bills per usage. Expected costs for Haley:
- Web service: ~$5-15/month
- Workers: ~$3-5/month each
- MySQL: ~$5-10/month
- Redis (x2): ~$2-5/month each

Total: ~$15-40/month depending on usage

## Troubleshooting

### Build Fails
- Check Railway logs for specific error
- Ensure Dockerfile is at root level
- Verify production/apps.json has valid GitHub URLs

### Site Not Loading
- Verify all env variables are set
- Check that DB and Redis services are healthy
- Run migrations: `bench --site $SITE_NAME migrate`

### 502 Bad Gateway
- Container might still be starting (frappe takes time)
- Check if site exists: `bench --site $SITE_NAME list-apps`
- Verify DB connection: `bench --site $SITE_NAME mariadb`

### Missing Assets
- Rebuild: `bench build`
- Clear cache: `bench --site $SITE_NAME clear-cache`
