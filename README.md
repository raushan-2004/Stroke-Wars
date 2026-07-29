# Stroke Wars

A premium real-time multiplayer drawing game built with Flutter.

## Features

- 🌐 **Online Multiplayer** — Global matchmaking
- 📡 **LAN Play** — Same Wi-Fi network
- 🔵 **Bluetooth** — Nearby peer-to-peer
- 📶 **Hotspot** — Mobile hotspot gaming

## Architecture

Feature-First Clean Architecture with Riverpod state management.

```
lib/
├── main.dart
├── app/           # App-level config, routing, theming
├── core/          # Shared infrastructure (storage, services, widgets)
├── features/      # Feature modules (splash, home, profile, settings, ...)
└── shared/        # Cross-feature shared providers & models
```

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.44.0
- Dart SDK ≥ 3.12.0

### Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Code Quality

```bash
flutter analyze
dart format .
flutter test
```

## Tech Stack

| Concern | Package |
|---------|---------|
| State Management | `flutter_riverpod` + `riverpod_annotation` |
| Navigation | `go_router` |
| Local Storage | `hive_flutter` |
| Responsive UI | `flutter_screenutil` |
| Immutable Models | `freezed` |
| Typography | `google_fonts` |
| Animations | `rive` + `lottie` |
| Linting | `very_good_analysis` |

## Stages

- ✅ Stage 0: Project Foundation & Architecture
- ⬜ Stage 1: (TBD)
