import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maize_leaf_prediction/core/theme/app_theme.dart';
import 'package:maize_leaf_prediction/features/onboarding/presentation/onboarding_screen.dart';
import 'package:maize_leaf_prediction/features/shared/providers.dart';
import 'package:maize_leaf_prediction/features/shell/presentation/app_shell.dart';

class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return session.when(
      loading: () => const _LaunchLoadingScreen(),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Unable to open Maize Guard: $error')),
      ),
      data: (state) {
        if (!state.onboardingComplete || state.profile == null) {
          return const OnboardingScreen();
        }
        return const AppShell();
      },
    );
  }
}

class _LaunchLoadingScreen extends StatelessWidget {
  const _LaunchLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient(context),
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
                    size: 48, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Maize Guard',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
