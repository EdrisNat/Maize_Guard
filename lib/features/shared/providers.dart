import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maize_leaf_prediction/core/services/disease_catalog_service.dart';
import 'package:maize_leaf_prediction/core/services/model_config.dart';
import 'package:maize_leaf_prediction/core/services/tflite_service.dart';
import 'package:maize_leaf_prediction/core/services/user_access_repository.dart';
import 'package:maize_leaf_prediction/data/local/app_database.dart';
import 'package:maize_leaf_prediction/data/models/app_session.dart';
import 'package:maize_leaf_prediction/data/models/scan_record.dart';
import 'package:maize_leaf_prediction/data/repositories/scan_repository.dart';
import 'package:maize_leaf_prediction/features/history/application/scan_history_notifier.dart';
import 'package:maize_leaf_prediction/features/session/application/session_notifier.dart';

// Theme mode provider
class ThemeModeNotifier extends Notifier<ThemeMode> {
  late UserAccessRepository _repository;

  @override
  ThemeMode build() {
    // Initialize synchronously with default, then update
    _initAsync();
    return ThemeMode.light;
  }

  Future<void> _initAsync() async {
    _repository = await UserAccessRepository.create();
    final isDark = _repository.isDarkMode;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    _repository = await UserAccessRepository.create();
    await _repository.setDarkMode(newMode == ThemeMode.dark);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    _repository = await UserAccessRepository.create();
    await _repository.setDarkMode(mode == ThemeMode.dark);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final modelConfigProvider = Provider<ModelConfig>((ref) {
  return const ModelConfig(
    modelAssetPath: 'assets/models/maize_model.tflite',
    labelsAssetPath: 'assets/models/labels.txt',
    diseaseCatalogAssetPath: 'assets/config/disease_catalog.json',
    modelVersion: 'maize_guard_field_v2',
    inputWidth: 224,
    inputHeight: 224,
    channels: 3,
    outputTensorType: OutputTensorType.float32,
    inputMean: 0.0,
    inputStd: 1.0,
    dequantizeUint8Output: true,
    enableDeterministicTta: false,
    enableModelDiagnostics: true,
    confidenceThreshold: 0.50,
  );
});

final diseaseCatalogServiceProvider = Provider<DiseaseCatalogService>((ref) {
  return DiseaseCatalogService(
      ref.watch(modelConfigProvider).diseaseCatalogAssetPath);
});

final diseaseCatalogProvider = FutureProvider<DiseaseCatalog>((ref) async {
  return ref.watch(diseaseCatalogServiceProvider).load();
});

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepository(ref.watch(databaseProvider));
});

final tfliteServiceProvider = Provider<TFLiteService>((ref) {
  final service = TFLiteService(ref.watch(modelConfigProvider));
  ref.onDispose(service.dispose);
  return service;
});

final tfliteInitProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(tfliteServiceProvider);
  await service.initialize();
});

final scanHistoryProvider =
    AsyncNotifierProvider<ScanHistoryNotifier, List<ScanRecord>>(
  ScanHistoryNotifier.new,
);

final sessionProvider = AsyncNotifierProvider<SessionNotifier, AppSession>(
  SessionNotifier.new,
);
