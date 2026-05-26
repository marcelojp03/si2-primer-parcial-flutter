# AuxilioMecánico — App Móvil

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg)](https://dart.dev/)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.x-00BCD4.svg)](https://riverpod.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28.svg)](https://firebase.google.com/)
[![Secure Storage](https://img.shields.io/badge/Storage-SecureStorage-4CAF50.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Mobile client for an intelligent vehicle emergency assistance platform. Clients report roadside incidents with photos, audio and GPS location — then track the assigned technician in real time until the service is completed.

---

## Overview

- Submit a vehicle emergency with multimodal evidence: camera, voice recording and automatic GPS location
- AI-powered backend analyzes the evidence and dispatches the nearest available workshop
- Track the technician's arrival on a live map
- Receive real-time status updates through WebSocket and push notifications (FCM)
- Offline-safe: incidents are created with a local UUID and synced when connectivity is restored

---

## Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.x |
| **Language** | Dart 3.x (null-safe) |
| **State Management** | Riverpod 2.x |
| **Auth** | JWT stored in `flutter_secure_storage` |
| **HTTP** | Dio |
| **Maps** | Google Maps Flutter / flutter_map |
| **Location** | Geolocator |
| **Camera / Audio** | image_picker · record |
| **Notifications** | Firebase Cloud Messaging (FCM) |
| **Real-time** | WebSocket (`web_socket_channel`) |

---

## Prerequisites

- Flutter 3.x SDK
- Dart 3.x
- Android Studio / Xcode (for device/emulator)
- Firebase project with `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Backend API running at `http://localhost:8000`

---

## Setup

### 1. Clone and install dependencies

```bash
git clone https://github.com/marcelojp03/si2-primer-parcial-flutter.git
cd si2-primer-parcial-flutter

flutter pub get
```

### 2. Configure Firebase

- Place `google-services.json` in `android/app/`
- Place `GoogleService-Info.plist` in `ios/Runner/`

### 3. Configure API URL

Edit `lib/core/constants/api_constants.dart` (or the equivalent constants file):

```dart
const String kApiBaseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator
// const String kApiBaseUrl = 'http://localhost:8000/api/v1'; // iOS simulator
```

### 4. Run the app

```bash
flutter run
```

---

## Required Permissions

| Permission | Purpose |
|------------|---------|
| `ACCESS_FINE_LOCATION` | GPS location on incident report |
| `CAMERA` | Capture photos of the vehicle incident |
| `RECORD_AUDIO` | Voice description of the incident |
| `POST_NOTIFICATIONS` | Push notifications (Android 13+) |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/      # API URLs, keys
│   ├── models/         # Data models (incident, user, workshop…)
│   ├── providers/      # Riverpod global providers
│   └── services/       # HTTP client, auth, WebSocket, FCM
├── features/
│   ├── auth/           # Login & registration screens
│   ├── incidents/      # Report + status tracking
│   ├── map/            # Live technician tracking map
│   ├── payments/       # Payment registration
│   └── profile/        # User profile & vehicles
└── main.dart
```

---

## Related

| Repository | Description |
|------------|-------------|
| [si2-primer-parcial-fastapi](https://github.com/marcelojp03/si2-primer-parcial-fastapi) | FastAPI backend API |
| [si2-primer-parcial-angular](https://github.com/marcelojp03/si2-primer-parcial-angular) | Angular admin dashboard |
