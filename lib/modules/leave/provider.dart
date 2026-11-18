import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/network/dio_client.dart';
import '../auth/provider.dart';
import 'model.dart';
import 'service.dart';

final leaveServiceProvider = Provider<LeaveService>((ref) {
  if (Env.useMock) {
    return MockLeaveService(
      userName: ref.watch(authProvider).user?.name ?? 'Pengguna JAHRIS',
    );
  }
  return ApiLeaveService(
    ref.watch(dioProvider),
    userId: ref.watch(authProvider).user?.id ?? '',
  );
});

final leaveProvider = AsyncNotifierProvider<LeaveController, LeaveState>(
  LeaveController.new,
);
final leaveDetailProvider = FutureProvider.family<LeaveRequest, String>(
  (ref, id) => ref.watch(leaveServiceProvider).detail(id),
);
final submissionTypesProvider = FutureProvider<List<SubmissionType>>(
  (ref) => ref.watch(leaveServiceProvider).types(),
);

class LeaveController extends AsyncNotifier<LeaveState> {
  static const _limit = 10;

  @override
  Future<LeaveState> build() async {
    final results = await Future.wait([
      ref.read(leaveServiceProvider).balance(),
      ref.read(leaveServiceProvider).list(limit: _limit),
    ]);
    final balance = results[0] as LeaveBalance;
    final page = results[1] as LeavePage;
    return LeaveState(
      balance: balance,
      items: page.items,
      page: page.page,
      total: page.total,
      hasMore: page.hasMore,
    );
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    final results = await Future.wait([
      ref.read(leaveServiceProvider).balance(),
      ref
          .read(leaveServiceProvider)
          .list(limit: _limit, status: current.statusFilter),
    ]);
    final page = results[1] as LeavePage;
    state = AsyncData(
      current.copyWith(
        balance: results[0] as LeaveBalance,
        items: page.items,
        page: 1,
        total: page.total,
        hasMore: page.hasMore,
        clearMessage: true,
      ),
    );
  }

  Future<void> setFilter(String filter) async {
    final current = state.value;
    if (current == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await ref
          .read(leaveServiceProvider)
          .list(limit: _limit, status: filter);
      return current.copyWith(
        items: page.items,
        page: 1,
        total: page.total,
        hasMore: page.hasMore,
        statusFilter: filter,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final page = await ref
        .read(leaveServiceProvider)
        .list(
          page: current.page + 1,
          limit: _limit,
          status: current.statusFilter,
        );
    state = AsyncData(
      current.copyWith(
        items: [...current.items, ...page.items],
        page: page.page,
        total: page.total,
        hasMore: page.hasMore,
      ),
    );
  }

  Future<bool> submit({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentPath,
  }) async {
    final current = state.value;
    if (current == null) return false;
    if (reason.trim().length < 5 || endDate.isBefore(startDate)) {
      state = AsyncData(
        current.copyWith(
          message: 'Periksa tanggal dan isi alasan minimal 5 karakter.',
        ),
      );
      return false;
    }
    state = AsyncData(current.copyWith(isSubmitting: true, clearMessage: true));
    try {
      final item = await ref
          .read(leaveServiceProvider)
          .create(
            type: type,
            startDate: startDate,
            endDate: endDate,
            reason: reason.trim(),
            attachmentPath: attachmentPath,
          );
      state = AsyncData(
        current.copyWith(
          items: [item, ...current.items],
          total: current.total + 1,
          isSubmitting: false,
          message: 'Pengajuan cuti berhasil dikirim.',
        ),
      );
      return true;
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isSubmitting: false,
          message: error is StateError
              ? error.message
              : networkErrorMessage(
                  error,
                  fallback: 'Pengajuan cuti gagal dikirim.',
                ),
        ),
      );
      return false;
    }
  }

  Future<void> decide(String id, {required bool approve, String? note}) async {
    final current = state.value;
    if (current == null) return;
    try {
      final updated = await ref
          .read(leaveServiceProvider)
          .decide(id, approve: approve, note: note);
      state = AsyncData(
        current.copyWith(
          items: [
            for (final item in current.items)
              if (item.id == id) updated else item,
          ],
          message: approve ? 'Pengajuan disetujui.' : 'Pengajuan ditolak.',
        ),
      );
      ref.invalidate(leaveDetailProvider(id));
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          message: networkErrorMessage(
            error,
            fallback: 'Keputusan gagal disimpan.',
          ),
        ),
      );
    }
  }
}
