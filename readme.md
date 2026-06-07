# Bifix Core

Monorepo for the Bifix platform — electric bike maintenance, workshop discovery, and service management.

## Structure

| Path | Description |
|------|-------------|
| `api/` | Laravel REST API (Sanctum, PostgreSQL, Pest, Sail) |

## API with Sail

```bash
cd api
composer install
cp .env.example .env
./vendor/bin/sail up -d
./vendor/bin/sail artisan key:generate
./vendor/bin/sail artisan migrate
```

| Service | URL / Port |
|---------|------------|
| API | http://localhost:8080 |
| Health | http://localhost:8080/api/v1/health |
| PostgreSQL (host) | `localhost:5433` — user `sail`, password `password`, db `bifix_api` |

Use `./vendor/bin/sail` instead of `php artisan` for commands inside the container.
