# Haley Railway Deployment Guide

Deploys Haley (ERPNext v16 + Enhanced Kanban View) to Railway using the same pattern as Railway's official ERPNext template.

## How It Works

This uses the [pipech/erpnext-docker-debian](https://github.com/pipech/erpnext-docker-debian) pattern:
- **Self-contained image**: MariaDB + Redis + Frappe/ERPNext all inside one container
- **bench start**: Runs all processes (web, socketio, workers, scheduler) via honcho
- **Optional external services**: Can reconfigure to use Railway's MySQL/Redis instead

## Quick Start

### 1. Deploy to Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new)

1. Click "New Project" → "Deploy from GitHub repo"
2. Select your `Haley-Arkangel` repository
3. Wait for build to complete (~15-20 minutes first time)

### 2. Configure Port

1. Click on the Haley service
2. Go to Settings → Networking
3. Set port to `8000`
4. Generate a domain

### 3. Access Your Site

- URL: Your Railway-generated domain
- Username: `Administrator`
- Password: `admin` (default)

## Using External Database (Recommended for Production)

By default, the container uses its internal MariaDB. For production, use Railway's MySQL service:

### Add MySQL Service

1. In your Railway project, click "New" → "Database" → "MySQL"
2. Wait for it to provision

### Add Redis Service

1. Click "New" → "Database" → "Redis"
2. Wait for it to provision

### Configure Haley

1. Open Railway shell for Haley service
2. Run the setup script:

```bash
su frappe -c "/home/frappe/frappe-bench/railway-setup.sh"
```

3. Set environment variables in Railway:

```
RFP_DOMAIN_NAME=your-domain.railway.app
RFP_SITE_ADMIN_PASSWORD=your_secure_password
MYSQLHOST=${{MySQL.MYSQLHOST}}
MYSQLPORT=${{MySQL.MYSQLPORT}}
MYSQL_ROOT_PASSWORD=${{MySQL.MYSQL_ROOT_PASSWORD}}
REDIS_URL=${{Redis.REDIS_URL}}
```

4. Remove the start command (Settings → Deploy → Start Command → clear it)
5. Set HTTP port to `8000`
6. Redeploy

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `RFP_DOMAIN_NAME` | Site domain name | haley.localhost |
| `RFP_SITE_ADMIN_PASSWORD` | Admin password | admin |
| `MYSQLHOST` | External MySQL host | localhost |
| `MYSQLPORT` | External MySQL port | 3306 |
| `MYSQL_ROOT_PASSWORD` | MySQL root password | admin123 |
| `REDIS_URL` | Redis connection URL | redis://localhost:6379 |

## Architecture

```
┌─────────────────────────────────────────────┐
│           Haley Container                    │
│  ┌───────────────────────────────────────┐  │
│  │            bench start                 │  │
│  │  • web (gunicorn :8000)               │  │
│  │  • socketio (node :9000)              │  │
│  │  • worker_short                       │  │
│  │  • worker_long                        │  │
│  │  • schedule                           │  │
│  │  • redis_queue                        │  │
│  │  • redis_cache                        │  │
│  └───────────────────────────────────────┘  │
│                     │                        │
│  ┌─────────────┐  ┌─────────────┐           │
│  │  MariaDB    │  │   Redis     │           │
│  │  (internal) │  │  (internal) │           │
│  └─────────────┘  └─────────────┘           │
└─────────────────────────────────────────────┘

OR with external services:

┌─────────────────────────────────────────────┐
│           Haley Container                    │
│  ┌───────────────────────────────────────┐  │
│  │            bench start                 │  │
│  └───────────────────────────────────────┘  │
└──────────────────┬──────────────────────────┘
                   │
     ┌─────────────┼─────────────┐
     ▼             ▼             ▼
┌─────────┐  ┌─────────┐  ┌─────────┐
│  MySQL  │  │  Redis  │  │  Redis  │
│(Railway)│  │ (cache) │  │ (queue) │
└─────────┘  └─────────┘  └─────────┘
```

## Customization

### Adding Your Database Backup

1. Open Railway shell
2. Upload your backup:
```bash
cd /home/frappe/frappe-bench
# Download your backup
curl -O https://your-server/backup.sql.gz
# Restore
bench --site haley.localhost restore backup.sql.gz
bench --site haley.localhost migrate
```

### Installing Additional Apps

```bash
cd /home/frappe/frappe-bench
bench get-app https://github.com/your-org/your-app
bench --site haley.localhost install-app your_app
```

## Troubleshooting

### Container Won't Start
- Check logs in Railway dashboard
- Ensure port is set to 8000
- MariaDB might need time to initialize

### Site Not Loading
- Run `bench --site haley.localhost migrate`
- Check `bench --site haley.localhost doctor`

### Permission Errors
- Run commands as frappe user: `su frappe -c "your command"`

### Clear Cache
```bash
su frappe -c "bench --site haley.localhost clear-cache"
```

## Costs

Estimated Railway costs:
- Haley container: ~$10-25/month (depending on RAM usage)
- MySQL (optional): ~$5-10/month
- Redis (optional): ~$5/month

Total: ~$10-40/month depending on configuration

## Notes

- First build takes 15-20 minutes (compiling from source)
- Subsequent deploys are faster (cached layers)
- Internal MariaDB data persists in container volume
- For production, use external MySQL for data safety
