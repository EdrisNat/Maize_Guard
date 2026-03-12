import 'package:flutter/material.dart';
import 'package:maize_leaf_prediction/core/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message = 'Processing image...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentContainerColor(context),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.iconOnAccentColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                style: TextStyle(
                  color: AppTheme.primaryTextColor(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
