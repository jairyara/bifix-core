# Bifix Core

Monorepo for the Bifix platform — electric bike maintenance, workshop discovery, and service management.

## Structure

| Path | Description |
|------|-------------|
| `api/` | Laravel REST API (Sanctum, PostgreSQL, Pest) |

## API setup

```bash
cd api
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
composer dev
```

Health check: `GET http://localhost:8000/api/v1/health`
