import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maize_leaf_prediction/core/theme/app_theme.dart';
import 'package:maize_leaf_prediction/features/root/presentation/root_screen.dart';
import 'package:maize_leaf_prediction/features/shared/providers.dart';

class MaizeGuardApp extends ConsumerWidget {
  const MaizeGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final themeMode = ref.watch(themeModeProvider);
    final lowLiteracyMode =
        session.valueOrNull?.profile?.lowLiteracyMode ?? false;

    return MaterialApp(
      title: 'Maize Guard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(lowLiteracyMode ? 1.12 : 1.0),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const RootScreen(),
    );
  }
}
