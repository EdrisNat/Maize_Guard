import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maize_leaf_prediction/core/theme/app_theme.dart';
import 'package:maize_leaf_prediction/core/utils/date_time_formatter.dart';
import 'package:maize_leaf_prediction/core/utils/label_formatter.dart';
import 'package:maize_leaf_prediction/core/widgets/loading_overlay.dart';
import 'package:maize_leaf_prediction/data/models/prediction_result.dart';
import 'package:maize_leaf_prediction/data/models/scan_record.dart';
import 'package:maize_leaf_prediction/features/results/presentation/result_screen.dart';
import 'package:maize_leaf_prediction/features/scan/presentation/camera_scan_screen.dart';
import 'package:maize_leaf_prediction/features/scan/presentation/image_editor_screen.dart';
import 'package:maize_leaf_prediction/features/shared/providers.dart';
import 'package:permission_handler/permission_handler.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenLibrary,
    required this.onOpenHistory,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;

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
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 96);
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
    final session = ref.watch(sessionProvider).valueOrNull;
    final initModel = ref.watch(tfliteInitProvider);
    final history = ref.watch(scanHistoryProvider);
    final catalog = ref.watch(diseaseCatalogProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: initModel.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text('Model failed to load: $err')),
            data: (_) => catalog.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Catalog failed to load: $error')),
              data: (catalogData) {
                final records = history.valueOrNull ?? const <ScanRecord>[];
                final insights = _DashboardInsights.from(records, catalogData);
                final farmerName =
                    session?.profile?.name.split(' ').firstOrNull ?? 'Farmer';

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Good field day, $farmerName',
                                  style: Theme.of(context).textTheme.bodyLarge),
                              const SizedBox(height: 6),
                              Text('Offline crop intelligence',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),
                              const SizedBox(height: 8),
                              Text(
                                'Scan leaves, compare disease patterns, generate PDF reports, and track outbreaks without needing internet.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.borderColor(context)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.wifi_off_rounded,
                                  color: AppTheme.iconOnAccentColor(context)),
                              const SizedBox(height: 6),
                              Text(
                                'Offline',
                                style: TextStyle(
                                  color: AppTheme.iconOnAccentColor(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [AppTheme.leaf, AppTheme.freshGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.leaf.withOpacity(0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick scan workspace',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use the camera for live guidance or analyze a saved image from the gallery.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    color: Colors.white.withOpacity(0.82)),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.gold,
                                    foregroundColor: AppTheme.forest,
                                    elevation: 0,
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const CameraScanScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.camera_alt_rounded),
                                  label: const Text('Scan now'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side:
                                        const BorderSide(color: Colors.white38, width: 1.5),
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                  onPressed: () =>
                                      _pickFromGallery(context, ref),
                                  icon: const Icon(Icons.photo_library_rounded),
                                  label: const Text('Gallery'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _InsightCard(
                            title: 'Scans logged',
                            value: '${records.length}',
                            subtitle: 'Local field records on this device',
                            icon: Icons.layers_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InsightCard(
                            title: 'Reports saved',
                            value: '${insights.savedReports}',
                            subtitle: 'PDF files ready for sharing',
                            icon: Icons.picture_as_pdf_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _InsightCard(
                            title: 'Top concern',
                            value: insights.topConcern,
                            subtitle: 'Most repeated disease this month',
                            icon: Icons.warning_amber_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InsightCard(
                            title: 'Avg confidence',
                            value:
                                '${(insights.averageConfidence * 100).toStringAsFixed(0)}%',
                            subtitle: 'Model confidence across saved scans',
                            icon: Icons.track_changes_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'What to do next',
                      actionLabel: 'Profile',
                      onAction: onOpenSettings,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ActionChip(
                              icon: Icons.menu_book_rounded,
                              label: 'Disease library',
                              onTap: onOpenLibrary),
                          _ActionChip(
                              icon: Icons.query_stats_rounded,
                              label: 'History & trends',
                              onTap: onOpenHistory),
                          _ActionChip(
                              icon: Icons.person_pin_circle_rounded,
                              label: 'Update farmer profile',
                              onTap: onOpenSettings),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Field alerts',
                      child: insights.alerts.isEmpty
                          ? Text(
                              'No urgent pattern yet. Keep scanning representative plants across the field.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          : Column(
                              children: insights.alerts
                                  .map(
                                    (alert) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            AppTheme.alertBadgeColor(context),
                                        child: Icon(
                                            Icons.campaign_rounded,
                                            color: AppTheme.alertIconColor(context)),
                                      ),
                                      title: Text(alert.title),
                                      subtitle: Text(alert.subtitle),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Recent diagnoses',
                      actionLabel: 'Open history',
                      onAction: onOpenHistory,
                      child: records.isEmpty
                          ? Text(
                              'Your recent scans will appear here with confidence, timing, and report status.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          : Column(
                              children: records.take(4).map((record) {
                                final disease = catalogData
                                    .resolveLabel(record.predictedLabel);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(22),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ResultScreen.fromRecord(record),
                                        ),
                                      );
                                    },
                                    child: Ink(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(22),
                                        color: AppTheme.cardAltColor(context),
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            child: SizedBox(
                                              width: 64,
                                              height: 64,
                                              child: Image.file(
                                                File(record.imagePath),
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    ColoredBox(
                                                  color: AppTheme.imagePlaceholderColor(context),
                                                  child: const Icon(Icons
                                                      .broken_image_rounded),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(disease.displayName,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium),
                                                const SizedBox(height: 4),
                                                Text(DateTimeFormatter.format(
                                                    record.timestamp)),
                                                const SizedBox(height: 6),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    _StatusPill(
                                                        label:
                                                            '${(record.confidence * 100).toStringAsFixed(0)}% confidence'),
                                                    if ((record.reportPath ??
                                                            '')
                                                        .isNotEmpty)
                                                      const _StatusPill(
                                                          label: 'PDF saved'),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(growable: false),
                            ),
                    ),
                    const SizedBox(height: 18),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentContainerColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.iconOnAccentColor(context), size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryTextColor(context),
          )),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium)),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(actionLabel!),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.accentContainerColor(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.iconOnAccentColor(context)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.iconOnAccentColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainerColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.primaryTextColor(context),
              )),
    );
  }
}

class _DashboardInsights {
  const _DashboardInsights({
    required this.savedReports,
    required this.averageConfidence,
    required this.topConcern,
    required this.alerts,
  });

  final int savedReports;
  final double averageConfidence;
  final String topConcern;
  final List<_DashboardAlert> alerts;

  factory _DashboardInsights.from(List<ScanRecord> records, dynamic catalog) {
    final savedReports =
        records.where((record) => (record.reportPath ?? '').isNotEmpty).length;
    final averageConfidence = records.isEmpty
        ? 0.0
        : records.fold<double>(0, (sum, record) => sum + record.confidence) /
            records.length;

    final counts = <String, int>{};
    for (final record in records) {
      final disease = catalog.resolveLabel(record.predictedLabel);
      if (LabelFormatter.normalizedKey(disease.displayName) == 'healthy') {
        continue;
      }
      counts[disease.displayName] = (counts[disease.displayName] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final alerts = sorted.take(2).map((entry) {
      return _DashboardAlert(
        title: entry.key,
        subtitle:
            '${entry.value} recent scans show this disease pattern. Compare multiple plants before acting.',
      );
    }).toList(growable: false);

    return _DashboardInsights(
      savedReports: savedReports,
      averageConfidence: averageConfidence,
      topConcern: sorted.isEmpty ? 'No active alert' : sorted.first.key,
      alerts: alerts,
    );
  }
}

class _DashboardAlert {
  const _DashboardAlert({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
