import 'package:maize_leaf_prediction/data/models/farmer_profile.dart';

enum AccessMode { offlineLocal, googleReady }

class AppSession {
  const AppSession({
    required this.onboardingComplete,
    required this.profile,
    this.accessMode = AccessMode.offlineLocal,
  });

  final bool onboardingComplete;
  final FarmerProfile? profile;
  final AccessMode accessMode;

  AppSession copyWith({
    bool? onboardingComplete,
    FarmerProfile? profile,
    AccessMode? accessMode,
  }) {
    return AppSession(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      profile: profile ?? this.profile,
      accessMode: accessMode ?? this.accessMode,
    );
  }

  factory AppSession.empty() {
    return const AppSession(onboardingComplete: false, profile: null);
  }
}
