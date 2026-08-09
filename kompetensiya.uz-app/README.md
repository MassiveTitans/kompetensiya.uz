# Flutter

A modern Flutter-based mobile application utilizing the latest mobile development technologies and tools for building responsive cross-platform applications.

## 📋 Prerequisites

- Flutter SDK (^3.38.4)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android SDK / Xcode (for iOS development)

## 🛠️ Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the application:
```bash
flutter run
```

## 🔌 Backend (kompetensiya.uz)

Ilovada qat'iy yozilgan (demo) ma'lumot yo'q — yangiliklar, bannerlar,
vakansiyalar, kurslar, testlar, hamjamiyat, reyting, KPI va davomat **to'liq
kompetensiya.uz backendidagi ma'lumotlar bazasidan** olinadi (`lib/core/api_service.dart`).

Backend manzili `API_BASE_URL` orqali beriladi (berilmasa Android emulatorda
`http://10.0.2.2:8000`, qolganida `http://localhost:8000`):

```bash
flutter run --dart-define=API_BASE_URL=https://kompetensiya.uz
```

Kirish faqat **ONE ID** orqali: ilova `/api/auth/one-id/` dan avtorizatsiya
manzilini oladi, WebView'da ochadi, qaytgan `code`ni `/api/auth/one-id/exchange/`
ga yuboradi va olingan kalitni qurilmada saqlaydi. Profil, KPI va davomat
ekranlari shu kalit bilan ishlaydi; kalit bo'lmasa "ONE ID orqali kiring" holati
ko'rsatiladi.

## 📁 Project Structure

```
flutter_app/
├── android/            # Android-specific configuration
├── ios/                # iOS-specific configuration
├── lib/
│   ├── core/           # Core utilities and services
│   │   └── utils/      # Utility classes
│   ├── presentation/   # UI screens and widgets
│   │   └── splash_screen/ # Splash screen implementation
│   ├── routes/         # Application routing
│   ├── theme/          # Theme configuration
│   ├── widgets/        # Reusable UI components
│   └── main.dart       # Application entry point
├── assets/             # Static assets (images, fonts, etc.)
├── pubspec.yaml        # Project dependencies and configuration
└── README.md           # Project documentation
```

## 🧩 Adding Routes

To add new routes to the application, update the `lib/routes/app_routes.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:package_name/presentation/home_screen/home_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    // Add more routes as needed
  }
}
```

## 🎨 Theming

This project includes a comprehensive theming system with both light and dark themes:

```dart
// Access the current theme
ThemeData theme = Theme.of(context);

// Use theme colors
Color primaryColor = theme.colorScheme.primary;
```

The theme configuration includes:
- Color schemes for light and dark modes
- Typography styles
- Button themes
- Input decoration themes
- Card and dialog themes

## 📱 Responsive Design

The app is built with responsive design using the Sizer package:

```dart
// Example of responsive sizing
Container(
  width: 50.w, // 50% of screen width
  height: 20.h, // 20% of screen height
  child: Text('Responsive Container'),
)
```
## 📦 Deployment

Build the application for production:

```bash
# For Android
flutter build apk --release

# For iOS
flutter build ios --release
```

## 🙏 Acknowledgments
- Built with [Rocket.new](https://rocket.new)
- Powered by [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- Styled with Material Design

Built with ❤️ on Rocket.new
