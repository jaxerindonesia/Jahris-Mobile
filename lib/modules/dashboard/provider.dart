import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/network/dio_client.dart';
import 'model.dart';
import 'service.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  if (Env.useMock) return const MockDashboardService();
  return ApiDashboardService(ref.watch(dioProvider));
});

final dashboardProvider =
    AsyncNotifierProvider<DashboardController, DashboardSummary>(
      DashboardController.new,
    );

class DashboardController extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() {
    return ref.read(dashboardServiceProvider).getSummary();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      ref.read(dashboardServiceProvider).getSummary,
    );
  }
}
