import 'dart:convert';

import 'package:maize_leaf_prediction/data/models/app_session.dart';
import 'package:maize_leaf_prediction/data/models/farmer_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserAccessRepository {
  UserAccessRepository(this._prefs);

  static const _onboardingKey = 'session.onboarding_complete';
  static const _profileKey = 'session.profile';
  static const _accessModeKey = 'session.access_mode';
  static const _darkModeKey = 'app.dark_mode';

  final SharedPreferences _prefs;

  static Future<UserAccessRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return UserAccessRepository(prefs);
  }

  bool get isDarkMode => _prefs.getBool(_darkModeKey) ?? false;

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(_darkModeKey, value);
  }

  Future<AppSession> loadSession() async {
    final onboardingComplete = _prefs.getBool(_onboardingKey) ?? false;
    final profileJson = _prefs.getString(_profileKey);
    final accessModeIndex = _prefs.getInt(_accessModeKey) ?? 0;
    FarmerProfile? profile;

    if (profileJson != null && profileJson.isNotEmpty) {
      profile = FarmerProfile.fromMap(
        jsonDecode(profileJson) as Map<String, dynamic>,
      );
    }

    final safeIndex = accessModeIndex.clamp(0, AccessMode.values.length - 1);
    return AppSession(
      onboardingComplete: onboardingComplete,
      profile: profile,
      accessMode: AccessMode.values[safeIndex],
    );
  }

  Future<AppSession> completeOnboarding(FarmerProfile profile) async {
    await _prefs.setBool(_onboardingKey, true);
    await _prefs.setString(_profileKey, jsonEncode(profile.toMap()));
    await _prefs.setInt(_accessModeKey, AccessMode.offlineLocal.index);
    return AppSession(
      onboardingComplete: true,
      profile: profile,
      accessMode: AccessMode.offlineLocal,
    );
  }

  Future<AppSession> updateProfile(FarmerProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toMap()));
    final current = await loadSession();
    return current.copyWith(profile: profile);
  }

  Future<void> logout() async {
    await _prefs.remove(_onboardingKey);
    await _prefs.remove(_profileKey);
    await _prefs.remove(_accessModeKey);
  }
}
