# Bifix API

Laravel REST API for the Bifix platform — mobile app and third-party integrations.

Part of [bifix-core](https://github.com/jairyara/bifix-core) (`api/`).

## Stack

- PHP 8.3+
- Laravel 13
- PostgreSQL
- Laravel Sanctum
- Pest

## Setup

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
composer dev
```

Health check: `GET http://localhost:8000/api/v1/health`
