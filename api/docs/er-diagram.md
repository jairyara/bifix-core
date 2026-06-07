# ER Diagram — Bifix API

Data model for the Bifix REST API (e-bike maintenance platform).

## Full diagram

```mermaid
erDiagram
    USER ||--o{ BIKE : "owns"
    USER ||--o{ RIDE : "logs"
    BRAND ||--o{ BIKE_MODEL : "has"
    BATTERY_TYPE ||--o{ BIKE_MODEL : "uses"
    BIKE_MODEL ||--o{ BIKE : "instance of"
    BIKE ||--o{ RIDE : "has"

    USER {
        bigint id PK
        string name
        string email UK
        string password
        timestamp email_verified_at "nullable"
        timestamp created_at
        timestamp updated_at
    }

    BRAND {
        bigint id PK
        string name UK
        string slug UK
        string country "nullable"
        string logo_url "nullable"
        timestamp created_at
        timestamp updated_at
    }

    BATTERY_TYPE {
        bigint id PK
        string name
        string slug UK
        text description "nullable"
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    BIKE_MODEL {
        bigint id PK
        bigint brand_id FK
        bigint battery_type_id FK "nullable"
        string name
        string slug
        smallint year "nullable"
        string frame_type "nullable"
        string motor_brand "nullable"
        integer battery_wh "nullable, capacity"
        integer range_km "nullable, nominal range"
        timestamp created_at
        timestamp updated_at
    }

    BIKE {
        bigint id PK
        bigint user_id FK
        bigint bike_model_id FK
        string serial_number UK "nullable"
        string frame_number UK "nullable"
        string nickname "nullable"
        string color "nullable"
        integer odometer_km "nullable, accumulated km"
        date purchased_at "nullable"
        timestamp created_at
        timestamp updated_at
    }

    RIDE {
        bigint id PK
        bigint user_id FK
        bigint bike_id FK
        integer distance_km "trip distance"
        timestamp started_at "nullable"
        timestamp ended_at "nullable"
        text notes "nullable"
        timestamp created_at
        timestamp updated_at
    }
```

## Relationships

| Relationship | Cardinality | Description |
|--------------|-------------|-------------|
| User → Bike | 1:N | A user owns many bikes |
| User → Ride | 1:N | A user logs many rides |
| Brand → BikeModel | 1:N | A brand has many models |
| BatteryType → BikeModel | 1:N | A battery type applies to many models |
| BikeModel → Bike | 1:N | A model can have many bike instances |
| Bike → Ride | 1:N | A bike accumulates many rides |

## Design notes

### Catalog vs instance

- **Brand**, **BatteryType**, and **BikeModel** are master/reference data (seed/admin).
- **Bike** and **Ride** are user-owned data.

### Odometer and rides

- `Bike.odometer_km` stores the **accumulated mileage** of the bike.
- Each **Ride** records a single trip (`distance_km`).
- Creating, updating, or deleting a ride **syncs** `odometer_km` automatically.

### Battery types

Extensible catalog (`battery_types`) to support lead, lithium, and future chemistries without schema changes.

### Laravel conventions

| Table | Eloquent model |
|-------|------------------|
| `bike_models` | `BikeModel` |
| `rides` | `Ride` |

## Related endpoints

| Resource | Prefix |
|----------|--------|
| Auth | `/api/v1/auth/*` |
| Catalog | `/api/v1/brands`, `/bike-models`, `/battery-types` |
| Bikes | `/api/v1/bikes` |
| Rides | `/api/v1/bikes/{bike}/rides` |
