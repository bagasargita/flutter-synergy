# Flutter Synergy

A production-ready Flutter boilerplate project featuring feature-based architecture, Riverpod state management, and clean separation of concerns.

## 🏗️ Architecture

This project follows a **feature-based architecture** with clear separation between:

- **UI Layer** (`*_page.dart`) - Widgets and UI components
- **State Layer** (`*_controller.dart`) - StateNotifier controllers managing feature state
- **Service Layer** (`*_service.dart`) - API calls and business logic
- **Provider Layer** (`*_provider.dart`) - Riverpod dependency injection

### Project Structure

```
lib/
├── core/                    # Shared utilities and infrastructure
│   ├── api/                 # API client, interceptors, base models
│   ├── constants/           # App-wide constants
│   ├── router/              # Navigation configuration
│   ├── theme/               # Material 3 theme setup
│   ├── utils/               # Logger, environment, token storage
│   └── widgets/             # Reusable UI components
│
└── features/                 # Feature modules
    ├── auth/                # Authentication flow
    ├── dashboard/           # Dashboard with pull-to-refresh
    └── approval/            # Approval list management
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.10.7 or higher)
- Dart SDK (3.10.7 or higher)
- Android Studio / VS Code with Flutter extensions
- iOS Simulator (macOS) or Android Emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd flutter-synergy
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify Flutter setup**
   ```bash
   flutter doctor
   ```

## ▶️ Running the Project

### Run on Connected Device/Emulator

```bash
# List available devices
flutter devices

# Run the app (defaults to debug mode)
flutter run

# Run on specific device
flutter run -d <device-id>

# Run in release mode
flutter run --release
```

### Run on Specific Platforms

```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### Development Commands

```bash
# Run static analysis
flutter analyze

# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Format code
flutter format lib/

# Build APK (Android)
flutter build apk

# Build iOS (macOS only)
flutter build ios

# Build web
flutter build web
```

## 🧪 Testing

### Run All Tests

```bash
flutter test
```

### Run Specific Test File

```bash
flutter test test/features/auth/auth_controller_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📦 Key Dependencies

- **flutter_riverpod** (^2.6.1) - State management
- **dio** (^5.7.0) - HTTP client
- **go_router** (^14.8.1) - Declarative routing
- **shared_preferences** (^2.3.5) - Local storage
- **logger** (^2.5.0) - Logging utility
- **mocktail** (^1.0.4) - Testing mocks

## 🔧 Configuration

### Environment Setup

The app supports multiple environments (dev/prod). Configure in `lib/main.dart`:

```dart
// Development
final environment = Environment.dev();

// Production
final environment = Environment.prod();
```

### API Configuration

Update base URLs in `lib/core/utils/environment.dart`:

```dart
factory Environment.dev() => const Environment(
  env: Env.dev,
  baseUrl: 'https://your-dev-api.com',
);
```

## 📱 Features

### Authentication
- Login form with validation
- Token storage and automatic injection
- Mock login API (ready to swap for real endpoint)

### Dashboard
- Pull-to-refresh functionality
- List of dashboard items with status indicators
- Loading and error state handling

### Approvals
- Approval request list
- Status badges (pending/approved/rejected)
- Empty state handling

## 🏛️ Architecture Patterns

### State Management
- Uses `StateNotifier` for each feature controller
- Async state handled via `AsyncValue` pattern
- Providers wired through Riverpod dependency graph

### API Layer
- Centralized `ApiClient` with Dio
- Request/response interceptors for auth and logging
- Unified error handling via `ApiException`

### Navigation
- Declarative routing with `go_router`
- Named routes via `RoutePaths` constants
- Deep linking support ready

## 🧩 Adding a New Feature

1. Create feature folder: `lib/features/your_feature/`
2. Add four files:
   - `your_feature_page.dart` - UI widget
   - `your_feature_controller.dart` - StateNotifier
   - `your_feature_service.dart` - API calls
   - `your_feature_provider.dart` - Riverpod providers
3. Add route in `lib/core/router/app_router.dart`
4. Follow existing patterns from `auth/`, `dashboard/`, or `approval/`

## 📝 Code Style

- Follows Flutter/Dart style guide
- Uses `flutter_lints` package
- Prefers `const` constructors
- Package imports only (no relative `../../`)
- Null safety enabled

## 🐛 Troubleshooting

### Build Issues

```bash
# Clean build cache
flutter clean
flutter pub get

# Reset Flutter
flutter doctor -v
```

### Dependency Conflicts

```bash
# Update dependencies
flutter pub upgrade

# Check outdated packages
flutter pub outdated
```

## 📄 License

[Add your license here]

## 👥 Contributing

[Add contribution guidelines here]
