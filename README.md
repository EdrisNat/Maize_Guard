# Maize Guard

Maize Guard is an offline-first Flutter app for on-device maize leaf disease detection using TensorFlow Lite. The redesigned app now includes a premium field dashboard, local farmer onboarding, a disease library driven by local metadata, richer result interpretation, scan history analytics, field notes, and offline PDF report export.

## Core capabilities

- Fully offline TFLite inference using `assets/models/maize_model.tflite`
- Dynamic disease catalog from `assets/config/disease_catalog.json`
- Guided camera scan plus gallery-based analysis
- Local SQLite history with report path, model version, disease ID, and quality score
- Offline PDF report generation and sharing
- Local farmer profile with low-literacy mode

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

## Local smoke verification

A lightweight non-Flutter smoke script validates the new catalog and legacy record fallback logic:

```bash
dart run tool/redesign_smoke.dart
```

## Report output

Prediction reports are saved on-device as `.pdf` files inside the local `reports` directory resolved by `path_provider`.
