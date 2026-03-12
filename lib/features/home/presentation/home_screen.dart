import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maize_leaf_prediction/core/constants/app_constants.dart';
import 'package:maize_leaf_prediction/core/theme/app_theme.dart';
import 'package:maize_leaf_prediction/core/widgets/loading_overlay.dart';
import 'package:maize_leaf_prediction/core/widgets/primary_action_card.dart';
import 'package:maize_leaf_prediction/data/models/prediction_result.dart';
import 'package:maize_leaf_prediction/features/history/presentation/history_screen.dart';
import 'package:maize_leaf_prediction/features/results/presentation/result_screen.dart';
import 'package:maize_leaf_prediction/features/scan/presentation/camera_scan_screen.dart';
import 'package:maize_leaf_prediction/features/scan/presentation/image_editor_screen.dart';
import 'package:maize_leaf_prediction/features/shared/providers.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _pickFromGallery(BuildContext context, WidgetRef ref) async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gallery permission denied.')),
          );
        }
        return;
      }
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !context.mounted) return;
    
    // Navigate to image editor before running inference
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageEditorScreen(
          imagePath: file.path,
          onConfirm: (editedPath) async {
            Navigator.of(context).pop(); // Close editor
            await _runInferenceAndNavigate(context, ref, editedPath);
          },
        ),
      ),
    );
  }

  Future<void> _runInferenceAndNavigate(
    BuildContext context,
    WidgetRef ref,
    String imagePath,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const LoadingOverlay(message: 'Running offline inference...'),
    );

    try {
      final service = ref.read(tfliteServiceProvider);
      final PredictionResult result = await service.runInference(imagePath);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imagePath: imagePath,
            prediction: result,
            saveToHistory: true,
          ),
        ),
      );
      ref.invalidate(scanHistoryProvider);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inference failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initModel = ref.watch(tfliteInitProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: initModel.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _HomeError(error: err.toString()),
            data: (_) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  AppConstants.appSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                PrimaryActionCard(
                  title: 'Scan with Camera',
                  subtitle: 'Capture a leaf and get instant AI diagnosis.',
                  icon: Icons.camera_alt_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CameraScanScreen()),
                    );
                  },
                ),
                PrimaryActionCard(
                  title: 'Pick from Gallery',
                  subtitle: 'Analyze an existing image from your device.',
                  icon: Icons.photo_library_rounded,
                  onTap: () => _pickFromGallery(context, ref),
                ),
                PrimaryActionCard(
                  title: 'View Scan History',
                  subtitle: 'Review previous diagnoses and reports.',
                  icon: Icons.history_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentContainerColor(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.wifi_off_rounded,
                          color: AppTheme.iconOnAccentColor(context),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Works Offline',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'No internet required for diagnosis',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // AI Disclaimer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2520)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF5A4A3A)
                          : const Color(0xFFFFE082),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF4A3A2A)
                              : const Color(0xFFFFECB3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFFFD54F)
                              : const Color(0xFFF9A825),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Advisory Notice',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFFFD54F)
                                    : const Color(0xFFF57F17),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This AI tool provides guidance only and is not 100% accurate. It does not replace professional agricultural advice. Please consult a specialist for critical decisions.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE0D0C0)
                                    : const Color(0xFF5D4037),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48),
            const SizedBox(height: 10),
            Text(
              'Model failed to load. Check assets/models/maize_model.tflite and labels.txt.\n$error',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
