# Maize Guard

Maize Guard is an offline-first Flutter app for on-device maize leaf disease detection using TensorFlow Lite. The app includes a premium field dashboard, local farmer onboarding, a disease library driven by local metadata, richer result interpretation, scan history analytics, field notes, and offline PDF report export.

## Core capabilities

- Fully offline TFLite inference using `assets/models/maize_model.tflite`
- Dynamic disease catalog from `assets/config/disease_catalog.json`
- Guided camera scan with image editing plus gallery-based analysis
- Local SQLite history with report path, model version, disease ID, and quality score
- Professional PDF report generation with color-coded confidence indicators
- Local farmer profile with low-literacy mode
- Dark theme support with comprehensive theme-aware styling
- Collapsible disease library cards for easier navigation
- AI advisory notice reminding users to consult specialists

## Theme support

The app includes full light and dark theme support. Toggle between themes in Settings. All screens, cards, containers, and UI elements adapt properly to the selected theme.

## PDF reports

Reports are saved as professionally designed PDF files with:
- Forest green header with gold accents
- Color-coded confidence bar (green/gold/red based on level)
- Captured leaf image thumbnail
- Two-column layout for probabilities and farmer details
- Numbered recommended actions
- Clear disclaimer footer

**Default save location:** `Downloads/MaizeGuard/reports` (publicly accessible in your file manager)

**Custom location:** Set a custom PDF save folder in Settings → PDF Save Location. Changes are saved automatically.

## Disease scalability

Disease display content is no longer hardcoded. To change supported diseases without rewriting the UI:

1. Update `assets/models/labels.txt`
2. Replace `assets/models/maize_model.tflite` if needed
3. Update `assets/config/disease_catalog.json`

Unknown labels still render through a safe fallback card so the app remains stable while the catalog evolves.

## Run the app

```bash
flutter pub get
flutter run
```

## Build release APK

```bash
flutter clean
flutter pub get
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

**Note:** If your project is on a different drive than your Flutter pub cache (e.g., project on E: and cache on C:), Kotlin incremental compilation is disabled in `android/gradle.properties` to prevent cross-drive cache errors.

## Local smoke verification

A lightweight non-Flutter smoke script validates the catalog and legacy record fallback logic:

```bash
dart run tool/redesign_smoke.dart
```

## Project structure

```
lib/
├── main.dart
├── app/                    # App configuration
├── core/
│   ├── constants/          # App constants
│   ├── services/           # TFLite, report generation
│   ├── theme/              # AppTheme with light/dark support
│   ├── utils/              # Formatters, helpers
│   └── widgets/            # Shared widgets
├── data/
│   ├── local/              # SQLite database
│   ├── models/             # Data models
│   └── repositories/       # Data repositories
└── features/
    ├── dashboard/          # Main home dashboard
    ├── history/            # Scan history
    ├── library/            # Disease library (collapsible cards)
    ├── onboarding/         # Farmer profile setup
    ├── results/            # Prediction results
    ├── scan/               # Camera and image editor
    ├── settings/           # Profile and app settings
    └── shell/              # Bottom navigation shell
```

## Requirements

- Flutter SDK ≥3.4.0
- Android SDK (minSdk 21)
- TensorFlow Lite model in `assets/models/`
