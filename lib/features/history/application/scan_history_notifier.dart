import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maize_leaf_prediction/data/models/scan_record.dart';
import 'package:maize_leaf_prediction/features/shared/providers.dart';

class ScanHistoryNotifier extends AsyncNotifier<List<ScanRecord>> {
  @override
  Future<List<ScanRecord>> build() async {
    final repo = ref.read(scanRepositoryProvider);
    return repo.getAllScans();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(scanRepositoryProvider);
      return repo.getAllScans();
    });
  }

  Future<void> deleteById(String id) async {
    final repo = ref.read(scanRepositoryProvider);
    await repo.deleteScan(id);
    await refresh();
  }

  Future<void> clearAll() async {
    final repo = ref.read(scanRepositoryProvider);
    await repo.clearAll();
    await refresh();
  }
}
