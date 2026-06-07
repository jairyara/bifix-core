# Bifix API

Laravel REST API for the Bifix platform — mobile app and third-party integrations.

Part of [bifix-core](https://github.com/jairyara/bifix-core) (`api/`).

## Stack

- PHP 8.4 (Sail)
- Laravel 13
- PostgreSQL 18
- Laravel Sanctum
- Pest

## Setup with Sail

```bash
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
| PostgreSQL (host) | `localhost:5433` |

Default ports avoid conflicts with services on 80, 5432 and 5173. Override via `APP_PORT`, `FORWARD_DB_PORT` and `VITE_PORT` in `.env`.

## Commands

```bash
./vendor/bin/sail artisan migrate
./vendor/bin/sail artisan test
./vendor/bin/sail down
```
