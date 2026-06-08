# Bifix — Contrato de API

El frontend (Flutter) consume una API externa que se desarrolla en paralelo.
Mientras el backend no esté listo, la app corre contra repositorios **mock**
en memoria (`AppConfig.useMockApi = true`). Para apuntar a la API real:

```bash
flutter run \
  --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=https://tu-api.com
```

Todas las respuestas son JSON. Las rutas protegidas requieren el header
`Authorization: Bearer <token>`. Las colecciones se devuelven como
`{ "data": [ ... ] }`. Los errores deben incluir `{ "message": "..." }` y un
status HTTP adecuado (401 invalida la sesión en el cliente).

## Autenticación

| Método | Ruta              | Body                                  | Respuesta             |
|--------|-------------------|---------------------------------------|-----------------------|
| POST   | `/auth/register`  | `{name, email, password, phone?}`     | `{token, user}`       |
| POST   | `/auth/login`     | `{email, password}`                   | `{token, user}`       |
| GET    | `/auth/me`        | —                                     | `user`                |
| PUT    | `/auth/me`        | `user`                                | `user` (actualizado)  |

`user`: `{ id, name, email, phone?, createdAt }`

## Bicicletas

| Método | Ruta                      | Body   | Respuesta              |
|--------|---------------------------|--------|------------------------|
| GET    | `/bikes`                  | —      | `{data: [bike]}`       |
| POST   | `/bikes`                  | `bike` | `bike`                 |
| PUT    | `/bikes/{id}`             | `bike` | `bike`                 |
| DELETE | `/bikes/{id}`             | —      | `204`                  |
| GET    | `/bikes/{id}/odometer`    | —      | `{odometerKm}`         |

`bike`: `{ id, name, brand?, model?, year?, batteryWh?, baselineKm, purchaseDate? }`

> **Odómetro:** distancia total = `baselineKm` + suma de recorridos. El cliente
> ya lo calcula de forma reactiva, pero el endpoint `/odometer` queda disponible
> si el backend prefiere ser la fuente de verdad.

## Recorridos (estimados en v1)

| Método | Ruta                    | Body   | Respuesta          |
|--------|-------------------------|--------|--------------------|
| GET    | `/bikes/{id}/rides`     | —      | `{data: [ride]}`   |
| POST   | `/bikes/{id}/rides`     | `ride` | `ride`             |
| DELETE | `/rides/{id}`           | —      | `204`              |

`ride`: `{ id, bikeId, title, date, distanceKm, durationMinutes?, source, notes? }`
`source`: `"estimated" | "manual" | "tracked"`

## Preferencias (modo de seguimiento)

El usuario elige cómo se alimenta el odómetro: **estimación** (privacidad, sin
GPS) o **tracking** (asistente). `ridingMode == null` ⇒ aún no completó el
onboarding.

| Método | Ruta               | Body          | Respuesta     |
|--------|--------------------|---------------|---------------|
| GET    | `/me/preferences`  | —             | `preferences` |
| PUT    | `/me/preferences`  | `preferences` | `preferences` |

`preferences`: `{ ridingMode, dailyProfile? }`
`ridingMode`: `"estimation" | "tracking" | null`
`dailyProfile`: `{ dailyKm, activeWeekdays: number[1..7], since }` (solo en
modo estimación; `activeWeekdays` usa 1=Lunes .. 7=Domingo)

> **Odómetro en modo estimación:** el cliente suma una acumulación recurrente
> = (días activos completos desde `since`) × `dailyKm`, más los recorridos
> puntuales. En modo tracking solo cuentan los recorridos registrados.

> En v1 no hay GPS: la distancia se ingresa manualmente o se estima como
> `velocidad × tiempo`.

## Mantenimiento

| Método | Ruta                          | Body     | Respuesta            |
|--------|-------------------------------|----------|----------------------|
| GET    | `/maintenance/tasks`          | —        | `{data: [task]}`     |
| GET    | `/bikes/{id}/maintenance`     | —        | `{data: [record]}`   |
| POST   | `/bikes/{id}/maintenance`     | `record` | `record`             |
| DELETE | `/maintenance/{id}`           | —        | `204`                |

`task`: `{ id, name, description, intervalKm?, intervalDays? }`
`record`: `{ id, bikeId, taskId, date, odometerKm, notes?, costCents? }`

### Recomendaciones

Las recomendaciones se **calculan en el cliente** (motor puro
`buildRecommendations`) comparando el odómetro/fecha actuales contra el último
`record` de cada `task` y sus intervalos. No requiere endpoint, pero si el
backend quisiera servirlas, debería devolver por tarea: `status`
(`ok|dueSoon|overdue`), `reason`, `kmUntilDue?`, `daysUntilDue?`, `progress`.
