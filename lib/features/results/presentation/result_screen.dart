import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maize_leaf_prediction/core/services/report_service.dart';
import 'package:maize_leaf_prediction/core/theme/app_theme.dart';
import 'package:maize_leaf_prediction/core/utils/date_time_formatter.dart';
import 'package:maize_leaf_prediction/data/models/image_quality_assessment.dart';
import 'package:maize_leaf_prediction/data/models/prediction_result.dart';
import 'package:maize_leaf_prediction/data/models/scan_record.dart';
import 'package:maize_leaf_prediction/features/history/presentation/history_screen.dart';
import 'package:maize_leaf_prediction/features/shared/providers.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    required this.imagePath,
    required this.prediction,
    super.key,
    this.saveToHistory = false,
    this.timestamp,
    this.recordId,
    this.reportPath,
    this.farmerNotes,
  });

  factory ResultScreen.fromRecord(ScanRecord record) {
    return ResultScreen(
      imagePath: record.imagePath,
      prediction: PredictionResult(
        predictedLabel: record.predictedLabel,
        confidence: record.confidence,
        classProbabilities: record.classProbabilities,
        modelVersion: record.modelVersion,
        qualityAssessment:
            ImageQualityAssessment.fromStoredScore(record.qualityScore),
      ),
      timestamp: record.timestamp,
      recordId: record.id,
      reportPath: record.reportPath,
      farmerNotes: record.farmerNotes,
      saveToHistory: false,
    );
  }

  final String imagePath;
  final PredictionResult prediction;
  final bool saveToHistory;
  final DateTime? timestamp;
  final String? recordId;
  final String? reportPath;
  final String? farmerNotes;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _isSaving = false;
  bool _isExporting = false;
  bool _isSavingNotes = false;
  String? _saveError;
  DateTime? _savedTimestamp;
  String? _recordId;
  String? _reportPath;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _savedTimestamp = widget.timestamp;
    _recordId = widget.recordId;
    _reportPath = widget.reportPath;
    _notesController = TextEditingController(text: widget.farmerNotes ?? '');
    if (widget.saveToHistory) {
      _saveRecord();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      final catalog = await ref.read(diseaseCatalogProvider.future);
      final disease = catalog.resolveLabel(widget.prediction.predictedLabel);
      final now = DateTime.now();
      final record = ScanRecord(
        id: const Uuid().v4(),
        imagePath: widget.imagePath,
        predictedLabel: widget.prediction.predictedLabel,
        confidence: widget.prediction.confidence,
        timestamp: now,
        classProbabilities: widget.prediction.classProbabilities,
        reportPath: _reportPath,
        modelVersion: widget.prediction.modelVersion,
        qualityScore: widget.prediction.qualityAssessment.score,
        diseaseId: disease.id,
        farmerNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      await ref.read(scanRepositoryProvider).insertScan(record);
      ref.invalidate(scanHistoryProvider);
      if (!mounted) return;
      setState(() {
        _savedTimestamp = now;
        _recordId = record.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveError = 'Failed to save scan record: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveNotes() async {
    if (_recordId == null) return;
    setState(() => _isSavingNotes = true);
    try {
      await ref.read(scanRepositoryProvider).updateFarmerNotes(
            _recordId!,
            _notesController.text.trim(),
          );
      ref.invalidate(scanHistoryProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field notes updated.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingNotes = false);
    }
  }

  Future<File> _buildReport() async {
    final catalog = await ref.read(diseaseCatalogProvider.future);
    final session = ref.read(sessionProvider).valueOrNull;
    final disease = catalog.resolveLabel(widget.prediction.predictedLabel);
    final guidance = [
      ...disease.management.take(3),
      ...disease.nextSteps.take(3),
      'Rescan advice: ${disease.rescanAdvice}',
      'Escalate when: ${disease.escalateWhen}',
    ];
    
    final reportInput = PredictionReportInput(
      imagePath: widget.imagePath,
      predictedLabel: widget.prediction.predictedLabel,
      confidence: widget.prediction.confidence,
      classProbabilities: widget.prediction.classProbabilities,
      guidance: guidance,
      timestamp: _savedTimestamp ?? DateTime.now(),
      modelVersion: widget.prediction.modelVersion,
      catalogVersion: catalog.catalogVersion,
      diseaseSummary: disease.summary,
      qualityScore: widget.prediction.qualityAssessment.score,
      farmerName: session?.profile?.name,
      farmerLocation: session?.profile?.location,
    );
    
    // Use custom save path from profile if available
    final customPath = session?.profile?.pdfSavePath;
    final File file;
    if (customPath != null && customPath.isNotEmpty) {
      file = await ReportService.exportPredictionReportToPath(reportInput, customPath);
    } else {
      file = await ReportService.exportPredictionReport(reportInput);
    }

    if (_recordId != null) {
      await ref
          .read(scanRepositoryProvider)
          .updateReportPath(_recordId!, file.path);
      ref.invalidate(scanHistoryProvider);
      if (mounted) {
        setState(() => _reportPath = file.path);
      }
    }
    return file;
  }

  Future<void> _downloadReport() async {
    setState(() => _isExporting = true);
    try {
      final file = await _buildReport();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF report saved to: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save report: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareReport() async {
    try {
      final file = _reportPath != null && await File(_reportPath!).exists()
          ? File(_reportPath!)
          : await _buildReport();
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Maize Guard prediction report',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share report: $e')),
      );
    }
  }

  Future<void> _openReport() async {
    if (_reportPath == null || !await File(_reportPath!).exists()) {
      // Build and save report first if not available
      setState(() => _isExporting = true);
      try {
        final file = await _buildReport();
        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open PDF: ${result.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open report: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isExporting = false);
      }
    } else {
      final result = await OpenFilex.open(_reportPath!);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF: ${result.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedProbabilities = widget.prediction.classProbabilities.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final catalog = ref.watch(diseaseCatalogProvider);

    return catalog.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
          body: Center(child: Text('Unable to load result details: $error'))),
      data: (catalogData) {
        final disease =
            catalogData.resolveLabel(widget.prediction.predictedLabel);
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient(context),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      if ((_reportPath ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor(context),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppTheme.borderColor(context)),
                          ),
                          child: const Text('PDF ready'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                child: const Icon(Icons.broken_image_rounded,
                                    size: 56),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('Prediction story',
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 6),
                        Text(disease.displayName,
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(disease.summary,
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _MetricPill(
                              label: 'Confidence',
                              value:
                                  '${(widget.prediction.confidence * 100).toStringAsFixed(1)}%',
                            ),
                            _MetricPill(
                              label: 'Capture quality',
                              value:
                                  '${(widget.prediction.qualityAssessment.score * 100).toStringAsFixed(0)}%',
                            ),
                            _MetricPill(
                              label: 'Severity',
                              value: disease.severity.toUpperCase(),
                            ),
                          ],
                        ),
                        if (_savedTimestamp != null) ...[
                          const SizedBox(height: 12),
                          Text(
                              'Saved ${DateTimeFormatter.format(_savedTimestamp!)}'),
                        ],
                        if (_isSaving) ...[
                          const SizedBox(height: 10),
                          const LinearProgressIndicator(minHeight: 3),
                        ],
                        if (_saveError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _saveError!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ResultSection(
                    title: 'Capture guidance',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.prediction.qualityAssessment.statusLabel,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 10),
                        ...widget.prediction.qualityAssessment.guidance
                            .map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('- $item'),
                                )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ResultSection(
                    title: 'Recommended next steps',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...disease.nextSteps.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('- $item'),
                            )),
                        const SizedBox(height: 10),
                        Text('Rescan advice: ${disease.rescanAdvice}'),
                        const SizedBox(height: 6),
                        Text('Escalate when: ${disease.escalateWhen}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ResultSection(
                    title: 'Management and prevention',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Management',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...disease.management.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('- $item'),
                            )),
                        const SizedBox(height: 10),
                        Text('Prevention',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...disease.prevention.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('- $item'),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ResultSection(
                    title: 'Alternative predictions',
                    child: Column(
                      children: sortedProbabilities.take(5).map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(catalogData
                                          .resolveLabel(entry.key)
                                          .displayName)),
                                  Text(
                                      '${(entry.value * 100).toStringAsFixed(1)}%'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                  value: entry.value, minHeight: 10),
                            ],
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ResultSection(
                    title: 'Field journal',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Add notes about field conditions, disease spread, or treatment decisions.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _recordId == null || _isSavingNotes
                              ? null
                              : _saveNotes,
                          icon: _isSavingNotes
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.note_alt_rounded),
                          label: const Text('Save field note'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Primary PDF action - Open PDF
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : _openReport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.open_in_new_rounded),
                    label: Text(_reportPath != null ? 'Open PDF report' : 'Generate & Open PDF'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isExporting ? null : _downloadReport,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Save PDF report'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _shareReport,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share PDF report'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const HistoryScreen()),
                      );
                    },
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('Open scan history'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardAltColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
