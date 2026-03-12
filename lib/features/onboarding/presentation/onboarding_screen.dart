import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maize_leaf_prediction/core/theme/app_theme.dart';
import 'package:maize_leaf_prediction/data/models/farmer_profile.dart';
import 'package:maize_leaf_prediction/features/shared/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _lowLiteracyMode = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_nameController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter the farmer name and location to continue.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(sessionProvider.notifier).completeOnboarding(
            FarmerProfile(
              name: _nameController.text.trim(),
              location: _locationController.text.trim(),
              languageCode: 'en',
              lowLiteracyMode: _lowLiteracyMode,
            ),
          );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 20),
              // App logo and welcome
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.leaf, AppTheme.freshGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.leaf.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Maize Guard',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Smart crop disease detection',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Features
              Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.wifi_off_rounded,
                      title: 'Offline',
                      subtitle: 'Works anywhere',
                      color: AppTheme.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.speed_rounded,
                      title: 'Fast AI',
                      subtitle: 'Instant results',
                      color: AppTheme.freshGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.picture_as_pdf_rounded,
                      title: 'Reports',
                      subtitle: 'PDF export',
                      color: AppTheme.leaf,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Profile form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.borderColor(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get started',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your details to personalize your experience',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Your name',
                        hintText: 'e.g. John Kamau',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _locationController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Village or location',
                        hintText: 'e.g. Nyeri County',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainerColor(context),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.text_fields_rounded,
                              color: AppTheme.iconOnAccentColor(context)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Large text mode',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontSize: 15,
                                        )),
                                Text('Easier to read guidance',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontSize: 13,
                                        )),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _lowLiteracyMode,
                            onChanged: (value) =>
                                setState(() => _lowLiteracyMode = value),
                            activeColor: AppTheme.leaf,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // CTA button
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _continue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.forest,
                  minimumSize: const Size.fromHeight(58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.forest),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _isSubmitting ? 'Setting up...' : 'Start scanning',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your data stays on this device. No internet required.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.25) : color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
