import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maize_leaf_prediction/core/theme/app_theme.dart';
import 'package:maize_leaf_prediction/features/shared/providers.dart';

class DiseaseLibraryScreen extends ConsumerWidget {
  const DiseaseLibraryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(diseaseCatalogProvider);
    final lowLiteracyMode =
        ref.watch(sessionProvider).valueOrNull?.profile?.lowLiteracyMode ??
            false;

    final body = catalog.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Unable to load disease library: $error')),
      data: (catalogData) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Text('Disease Library',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Tap any card to expand and view detailed information about each disease.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          ...catalogData.orderedDiseases.map((disease) {
            return _CollapsibleDiseaseCard(
              key: ValueKey(disease.id),
              disease: disease,
              lowLiteracyMode: lowLiteracyMode,
            );
          }),
        ],
      ),
    );

    if (embedded) {
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

class _CollapsibleDiseaseCard extends StatefulWidget {
  const _CollapsibleDiseaseCard({
    super.key,
    required this.disease,
    required this.lowLiteracyMode,
  });

  final dynamic disease;
  final bool lowLiteracyMode;

  @override
  State<_CollapsibleDiseaseCard> createState() => _CollapsibleDiseaseCardState();
}

class _CollapsibleDiseaseCardState extends State<_CollapsibleDiseaseCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final disease = widget.disease;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityColor = switch (disease.severity) {
      'critical' => isDark ? const Color(0xFFCF6679) : const Color(0xFFE57373),
      'high' => isDark ? const Color(0xFFD4915C) : const Color(0xFFF6B26B),
      'medium' => isDark ? const Color(0xFFD4B54A) : const Color(0xFFF1C75B),
      _ => isDark ? const Color(0xFF5A6E5A) : const Color(0xFFC7D9C2),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpansion,
          borderRadius: BorderRadius.circular(28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _isExpanded
                    ? AppTheme.sage.withValues(alpha: 0.5)
                    : AppTheme.borderColor(context),
                width: _isExpanded ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - always visible
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disease.displayName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if ((disease.scientificName ?? '').isNotEmpty)
                            Text(
                              disease.scientificName!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppTheme.secondaryTextColor(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        disease.severity.toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.secondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Brief summary - always visible
                Text(
                  widget.lowLiteracyMode
                      ? disease.lowLiteracyTip
                      : disease.summary,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: _isExpanded ? null : 2,
                  overflow: _isExpanded ? null : TextOverflow.ellipsis,
                ),
                // Expandable content
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  axisAlignment: -1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      _BulletGroup(title: 'Symptoms', items: disease.symptoms),
                      const SizedBox(height: 14),
                      _BulletGroup(title: 'Management', items: disease.management),
                      const SizedBox(height: 14),
                      _BulletGroup(title: 'Prevention', items: disease.prevention),
                      const SizedBox(height: 14),
                      _BulletGroup(title: 'Next Actions', items: disease.nextSteps),
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.refresh_rounded,
                        label: 'Rescan advice',
                        value: disease.rescanAdvice,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.warning_amber_rounded,
                        label: 'Escalate when',
                        value: disease.escalateWhen,
                      ),
                    ],
                  ),
                ),
                // Tap hint when collapsed
                if (!_isExpanded) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 14,
                        color: AppTheme.secondaryTextColor(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap for details',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BulletGroup extends StatelessWidget {
  const _BulletGroup({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.sage,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryTextColor(context),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.sage,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
