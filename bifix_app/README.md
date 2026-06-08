# Bifix

App Flutter para el **control de mantenimiento de bicicletas eléctricas**.
Registra recorridos (estimados en v1), lleva un odómetro por bici y **recomienda
mantenimientos** según la distancia y el tiempo transcurrido.

El backend/API se desarrolla por separado; este repo es el cliente Flutter. Ver
[`API_CONTRACT.md`](API_CONTRACT.md) para los endpoints esperados.

## Funcionalidad

- **Auth**: registro e inicio de sesión, token guardado de forma segura.
- **Perfil**: datos del usuario + administración de bicicletas.
- **Recorridos**: distancia manual o estimada (`velocidad × tiempo`).
- **Mantenimiento**: tareas con intervalos (km y/o días), historial y
  recomendaciones (al día / próximo / vencido) calculadas en el cliente.

## Arquitectura

```
lib/
  core/        config, red (Dio), token storage, tema, router, providers
  features/
    auth/        domain · data (repo mock/http) · application · presentation
    profile/     bicicletas
    rides/       recorridos
    maintenance/ tareas, registros, motor de recomendaciones
```

- **Riverpod** para estado, **go_router** para navegación, **Dio** para HTTP.
- Cada feature depende de un **repositorio abstracto** con dos implementaciones:
  `Mock*` (datos en memoria, para correr sin backend) y `Http*` (API real).
- El interruptor está en `core/config/app_config.dart`.

## Cómo correr

```bash
flutter pub get
flutter run                      # modo demo (mock, datos precargados)
```

Cuenta demo: `demo@bifix.app` / `demo1234`.

Apuntar a la API real:

```bash
flutter run \
  --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=https://tu-api.com
```

## Pruebas

```bash
flutter test       # motor de recomendaciones y estimación de distancia
flutter analyze
```
