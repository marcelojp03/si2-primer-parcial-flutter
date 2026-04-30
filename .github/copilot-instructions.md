# Instrucciones Flutter — Auxilio Mecánico · SI2 2026

> Documentación completa en el workspace raíz `.github/`:
> - `API.md` → contrato de endpoints (URLs, payloads, respuestas)
> - `FLUTTER.md` → plan de implementación, pantallas, flujos
> - `DATABASE.md` → referencia de campos para modelado de datos

---

## Stack

- Flutter 3.x, Dart (null-safe)
- State management: **Riverpod** (preferido) o Bloc (mantener consistente con el avance existente)
- `flutter_secure_storage` para JWT
- `firebase_messaging` para notificaciones push (FCM)
- Actor: **CLIENTE** exclusivamente

## Estructura de carpetas

```
lib/
  core/
    api/          → dio_client.dart (base URL, interceptor JWT)
    models/       → clases Dart mapeadas a respuestas API
    services/     → llamadas HTTP por dominio
    storage/      → secure_storage_service.dart
    utils/        → formatters, validators
  features/
    auth/
      screens/    → login_screen.dart, register_screen.dart
      providers/  → auth_provider.dart
    incidents/
      screens/    → incident_list_screen.dart, incident_detail_screen.dart
                     new_incident_screen.dart (flujo multimodal)
      providers/  → incident_provider.dart
    vehicles/
      screens/    → vehicle_list_screen.dart, vehicle_form_screen.dart
    payments/
      screens/    → payment_screen.dart
    profile/
      screens/    → profile_screen.dart
  main.dart
```

## Reglas críticas

1. **Solo habla con FastAPI** (`http://localhost:8000/api/v1/`). Ningún otro servicio directamente.
2. **JWT en `flutter_secure_storage`** bajo la clave `access_token`.
3. **Interceptor Dio** inyecta `Authorization: Bearer <token>` en cada request.
4. **Polling cada 15 segundos** para estado del incidente activo (no WebSockets).
5. `camelCase` en Dart. Screens en `features/`. Modelos en `core/models/`.
6. **Null-safety** obligatorio. No usar `!` sin validar primero.
7. FCM token se registra en el backend tras login: `POST /api/v1/users/fcm-token`.

## Flujo principal: Reportar Emergencia

```
1. Verificar GPS activo → capturar latitud/longitud
2. Capturar foto (image_picker) → opcional
3. Grabar audio (record) → opcional
4. POST /api/v1/incidents (con título, descripción, vehículo, coordenadas)
   → respuesta: { id: incidente_id }
5. POST /api/v1/incidents/{id}/evidences (multipart: foto)
6. POST /api/v1/incidents/{id}/evidences (multipart: audio)
7. POST /api/v1/incidents/{id}/analyze → lanza IA y motor de asignación
8. Pantalla de seguimiento con polling 15s sobre GET /api/v1/incidents/{id}
```

## Modelos Dart — campos clave

```dart
class Incident {
  final int id;
  final String titulo;
  final String nivelPrioridad;   // 'BAJA','MEDIA','ALTA','CRITICA','INCIERTA'
  final bool requiereRemolque;
  final int estadoIncidenteId;
  final String fechaSolicitud;
  // Mapear de snake_case con json_annotation o manualmente
}

class Vehicle {
  final int id;
  final String placa;
  final String marca;
  final String modelo;
  final String estado;           // 'ACTIVO','INACTIVO'
}

class ServiceAssignment {
  final int id;
  final String estadoAsignacion; // 'ASIGNADO','EN_CAMINO','EN_PROCESO','ATENDIDO','CANCELADO','PENDIENTE_PAGO','PAGADO'
  final double? costoFinal;
}
```

## Pantallas principales (CLIENTE)

1. **Login / Registro**
2. **Home** — botón "Solicitar Auxilio" + incidente activo si hay uno en progreso
3. **Nueva Emergencia** — paso a paso: descripción → vehículo → GPS → foto → audio → enviar
4. **Seguimiento** — estado del incidente con polling 15s, datos del taller asignado
5. **Mis Vehículos** — CRUD vehículos
6. **Historial** — incidentes pasados con opción de calificar
7. **Pago** — formulario según método (QR/EFECTIVO/TRANSFERENCIA)
8. **Perfil** — datos del usuario, logout

## Notificaciones FCM

- Al iniciar la app, obtener token FCM y enviarlo al backend
- Manejar mensajes en primer plano con `FirebaseMessaging.onMessage`
- Al tocar notificación: navegar a pantalla de seguimiento del incidente

## Manejo de estado del incidente (UI)

| `estado_incidente_id` → nombre | Mensaje al usuario |
|-------------------------------|---------------------|
| PENDIENTE                     | "Buscando talleres disponibles..." |
| NOTIFICADO                    | "Notificando talleres cercanos..." |
| ACEPTADO                      | "¡Un taller aceptó tu solicitud!" |
| EN_PROCESO                    | "El técnico está en camino" |
| ATENDIDO                      | "Servicio completado. Proceder al pago." |
| PENDIENTE_PAGO                | "Pendiente de pago" |
| PAGADO                        | "Pago confirmado. Califica el servicio." |
| CANCELADO                     | "Servicio cancelado" |
