import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maize_leaf_prediction/core/services/user_access_repository.dart';
import 'package:maize_leaf_prediction/data/models/app_session.dart';
import 'package:maize_leaf_prediction/data/models/farmer_profile.dart';

class SessionNotifier extends AsyncNotifier<AppSession> {
  late final UserAccessRepository _repository;

  @override
  Future<AppSession> build() async {
    _repository = await UserAccessRepository.create();
    return _repository.loadSession();
  }

  Future<void> completeOnboarding(FarmerProfile profile) async {
    state = const AsyncLoading();
    state =
        await AsyncValue.guard(() => _repository.completeOnboarding(profile));
  }

  Future<void> updateProfile(FarmerProfile profile) async {
    final previous = state.valueOrNull;
    state =
        AsyncData(previous?.copyWith(profile: profile) ?? AppSession.empty());
    state = await AsyncValue.guard(() => _repository.updateProfile(profile));
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await _repository.logout();
    state = AsyncData(AppSession.empty());
  }
}
