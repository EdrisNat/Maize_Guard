import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maize_leaf_prediction/core/theme/app_theme.dart';
import 'package:maize_leaf_prediction/core/utils/date_time_formatter.dart';
import 'package:maize_leaf_prediction/features/results/presentation/result_screen.dart';
import 'package:maize_leaf_prediction/features/shared/providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedDisease = 'All';
  bool _reportOnly = false;
  double _minimumConfidence = 0.0;

  Future<void> _deleteSingleRecord(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this record?'),
        content:
            const Text('This scan result will be removed from local history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await ref.read(scanHistoryProvider.notifier).deleteById(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Record deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(scanHistoryProvider);
    final catalog = ref.watch(diseaseCatalogProvider);

    Widget body = history.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load history: $error'),
        ),
      ),
      data: (records) {
        return catalog.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Catalog unavailable: $error')),
          data: (catalogData) {
            final diseaseOptions = <String>{'All'}
              ..addAll(records.map((record) =>
                  catalogData.resolveLabel(record.predictedLabel).displayName));
            final filtered = records.where((record) {
              final diseaseName =
                  catalogData.resolveLabel(record.predictedLabel).displayName;
              final matchesDisease =
                  _selectedDisease == 'All' || diseaseName == _selectedDisease;
              final matchesReport =
                  !_reportOnly || (record.reportPath ?? '').isNotEmpty;
              final matchesConfidence = record.confidence >= _minimumConfidence;
              return matchesDisease && matchesReport && matchesConfidence;
            }).toList(growable: false);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                Text('History & trends',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Filter stored diagnoses, revisit older decisions, and track disease pressure over time.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: diseaseOptions.map((option) {
                    final isSelected = option == _selectedDisease;
                    return ChoiceChip(
                      label: Text(
                        option,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.iconOnAccentColor(context)
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.accentContainerColor(context),
                      backgroundColor: AppTheme.cardColor(context),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.gold
                            : AppTheme.borderColor(context),
                        width: isSelected ? 2 : 1,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedDisease = option),
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _reportOnly,
                  title: const Text('Show only scans with PDF reports'),
                  onChanged: (value) => setState(() => _reportOnly = value),
                ),
                Text(
                    'Minimum confidence ${(_minimumConfidence * 100).toStringAsFixed(0)}%'),
                Slider(
                  value: _minimumConfidence,
                  onChanged: (value) =>
                      setState(() => _minimumConfidence = value),
                  min: 0,
                  max: 1,
                  divisions: 10,
                ),
                const SizedBox(height: 6),
                if (filtered.isEmpty)
                  const _EmptyHistoryState()
                else
                  ...filtered.map((record) {
                    final disease =
                        catalogData.resolveLabel(record.predictedLabel);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.borderColor(context)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: Image.file(
                                File(record.imagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  child: const Icon(Icons.broken_image_rounded),
                                ),
                              ),
                            ),
                          ),
                          title: Text(disease.displayName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(
                            '${(record.confidence * 100).toStringAsFixed(1)}%  |  ${DateTimeFormatter.format(record.timestamp)}\n${(record.reportPath ?? '').isNotEmpty ? 'PDF ready' : 'PDF not generated yet'}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'delete') {
                                await _deleteSingleRecord(
                                    context, ref, record.id);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded),
                                    SizedBox(width: 8),
                                    Text('Delete record'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ResultScreen.fromRecord(record),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );

    if (widget.embedded) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(child: body),
      );
    }

    return Scaffold(body: body);
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 58,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No scans match the current filters',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Capture and analyze more leaves to build a stronger offline field record.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
