# Vikla — Alineación Backend (Laravel) ↔ Frontend (Flutter)

> Estado a 2026-06-07. El frontend corre hoy 100% en **mock**; el backend Laravel
> (`api/`) está parcialmente implementado. Este documento contrasta ambos y
> propone cómo alinearlos. Sirve de referencia para los dos equipos.

## 1. Visión del proyecto

Vikla es una app de **mantenimiento de bicicletas eléctricas**. El valor central
es: avisarle al usuario qué mantenimiento está **al día / próximo / vencido**,
calculado a partir de **kilómetros recorridos + tiempo** contra intervalos por
tarea (cadena, frenos, batería, etc.).

Cadena de valor:

```
Bici (identidad + odómetro base)
   └─ Recorridos (estimados / manuales / tracking)  ─┐
   └─ Perfil de estimación (km/día, días activos)    ├─► Odómetro total
                                                      ┘
Odómetro total + fechas  ──►  Motor de recomendaciones  ──►  Estados de mantenimiento
```

- **Catálogo** (marcas, modelos, tipos de batería): fuente de datos del backend
  para identificar bicis con precisión.
- **Auth**: tokens (Sanctum) por dispositivo.
- v1 **sin GPS**: la distancia se ingresa manual o se estima (velocidad × tiempo).

## 2. Estado de endpoints

| Recurso | Contrato app (`API_CONTRACT.md`) | Laravel real (`api/routes/api.php`) | ¿Alineado? |
|---|---|---|---|
| Auth register/login | `POST /auth/{register,login}` → `{token,user}` | ✅ pero envuelto en `{data:{user,token}}` y exige `device_name` | ⚠️ forma distinta |
| Perfil | `GET/PUT /auth/me` | ✅ `GET /auth/me` · ❌ **no hay PUT** · ✅ extra `POST /auth/logout` | ⚠️ falta editar perfil |
| Bikes | `GET/POST/PUT/DELETE /bikes` + `/odometer` | ✅ `apiResource bikes` · ❌ sin `/odometer` | ⚠️ modelo de datos distinto |
| Rides | `GET/POST /bikes/{id}/rides`, `DELETE /rides/{id}` | ✅ `apiResource bikes.rides` (DELETE **anidado**) | ⚠️ campos y ruta distintos |
| Catálogo | (no existe en la app) | ✅ `brands`, `bike-models`, `battery-types` | ➕ backend tiene de más |
| **Mantenimiento** | `GET/POST/DELETE /maintenance/*` | ❌ **no existe** | 🔴 falta backend |
| **Preferencias** | `GET/PUT /me/preferences` | ❌ **no existe** | 🔴 falta backend |
| Health | — | ✅ `GET /api/v1/health` | ok |

> **Prefijo de rutas:** Laravel sirve todo bajo **`/api/v1/...`**. El frontend hoy
> usa `baseUrl` sin prefijo, así que al conectar hay que apuntar
> `API_BASE_URL=https://host/api/v1`.

## 3. Diferencias por entidad (campos)

### Auth / User
| App espera | Laravel devuelve |
|---|---|
| `{ token, user }` plano | `{ data: { token, user } }` |
| login/register: `{name,email,password,phone?}` | exige además **`device_name`**; **no** acepta `phone` |
| user: `{id,name,email,phone?,createdAt}` | `{id,name,email,email_verified_at,created_at,updated_at}` — **sin `phone`**, snake_case |

### Bike — **el choque más grande**
| App (frontend) | Laravel (backend) |
|---|---|
| `name` (texto libre) | `nickname` |
| `brand`, `model`, `year`, `batteryWh` como **texto/num libre** en la bici | **referencia obligatoria** `bike_model_id` (del catálogo); marca/modelo/año/batería viven en `bike_model` |
| `baselineKm` (odómetro inicial; total se calcula en cliente) | `odometer_km` (entero, **almacenado** en backend) — sin concepto de baseline |
| — | `serial_number`, `frame_number`, `color`, `purchased_at` |
| `purchaseDate` | `purchased_at` |

→ Filosofías distintas: el front trata la bici como datos libres con odómetro
calculado; el back la ancla a un **catálogo** y guarda el odómetro como verdad.

### Ride
| App | Laravel |
|---|---|
| `title`, `source` (estimated/manual/tracked), `durationMinutes` | **no existen** |
| `date` (un instante) | `started_at` + `ended_at` |
| `distanceKm` (double) | `distance_km` (**entero**, min 1) |
| `DELETE /rides/{id}` | `DELETE /bikes/{id}/rides/{id}` (anidado) |

### Catálogo (solo backend)
`brands{id,name,slug,country?,logo_url?}` · `bike_models{...,year,frame_type,motor_brand,battery_wh,range_km,brand,battery_type}` · `battery_types{id,name,slug,description?}`. El front aún no lo consume.

### Mantenimiento y Preferencias
**No existen en el backend.** Son el corazón de la app:
- `maintenance/tasks`, `bikes/{id}/maintenance` (records), recomendaciones (se
  calculan en cliente con `buildRecommendations`).
- `me/preferences`: `ridingMode` (estimation|tracking) + `dailyProfile`
  (dailyKm, activeWeekdays, since).

### Convención global
Backend **snake_case** (`serial_number`, `started_at`) · Frontend **camelCase**
(`baselineKm`, `distanceKm`). Hay que decidir una sola.

## 4. Decisiones de alineación (recomendación)

1. **Convención:** adoptar **snake_case** como canónico (idioma de Laravel, ya más
   avanzado). El frontend ajusta sus `fromJson/toJson`. *(Alternativa: configurar
   Laravel para emitir camelCase, pero toca todos los Resources.)*
2. **Envelope auth:** frontend lee `data.token` / `data.user` y envía
   `device_name` (p.ej. modelo del teléfono). Backend agrega `phone` al user si lo
   queremos en perfil.
3. **Perfil editable:** backend agrega `PUT /auth/me`.
4. **Bici = catálogo:** adoptar el modelo del backend. El **formulario de bici en
   Flutter cambia** a: elegir marca → modelo (desde catálogo) + nickname, color,
   serial, odómetro, fecha de compra. Se elimina el texto libre de marca/modelo.
5. **Odómetro:** el backend es la fuente de verdad (`odometer_km`). El modo
   estimación/daily accrual del front se recalcula y se **persiste vía
   preferencias** (nuevo endpoint) o se sube como ajustes de odómetro.
6. **Rides:** mapear `started_at→date`; `distance_km` pasa a entero; `title`,
   `source`, `durationMinutes` → o se agregan al backend, o se vuelven opcionales/
   derivados en el front. DELETE pasa a anidado.
7. **Mantenimiento + Preferencias:** el backend debe implementarlos (migraciones,
   modelos, controllers, rutas) siguiendo `API_CONTRACT.md`. Hasta entonces, esos
   dos features **siguen en mock** en la app.

## 5. Plan de alineación (orden sugerido)

- **A. Cosas que el frontend puede adelantar ya (sin API arriba):**
  ajustar `baseUrl` a `/api/v1`, alinear auth (envelope + device_name), pasar
  modelos `Bike`/`Ride`/`User` a snake_case, rehacer el form de bici contra el
  catálogo, dejar rides con DELETE anidado. Mantenimiento/preferencias quedan en mock.
- **B. Cosas que requieren al backend:** `PUT /auth/me`, `phone` en user,
  endpoints de **mantenimiento** y **preferencias**, y opcionalmente `source/title`
  en rides.
- **C. Verificación end-to-end:** con el deploy (Dokploy) arriba, correr la app
  con `--dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=https://host/api/v1`
  y validar cada flujo (login → bici desde catálogo → ride → odómetro → mantenimiento).

> Nota: `API_CONTRACT.md` (en `bifix_app/`) refleja el diseño original del front.
> Tras acordar las decisiones de §4, conviene actualizarlo para que sea el contrato
> único y real entre ambos equipos.
