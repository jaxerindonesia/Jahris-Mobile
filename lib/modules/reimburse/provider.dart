import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/network/dio_client.dart';
import '../auth/provider.dart';
import 'model.dart';
import 'service.dart';

final reimburseServiceProvider = Provider<ReimburseService>((ref) {
  if (Env.useMock) {
    return MockReimburseService(
      userName: ref.watch(authProvider).user?.name ?? 'Pengguna JAHRIS',
    );
  }
  return ApiReimburseService(
    ref.watch(dioProvider),
    userId: ref.watch(authProvider).user?.id ?? '',
  );
});

final reimburseProvider =
    AsyncNotifierProvider<ReimburseController, ReimburseState>(
      ReimburseController.new,
    );
final reimburseDetailProvider = FutureProvider.family<Reimbursement, String>(
  (ref, id) => ref.watch(reimburseServiceProvider).detail(id),
);

final reimburseCategoryFilterProvider =
    NotifierProvider<ReimburseCategoryFilter, String>(
      ReimburseCategoryFilter.new,
    );

final filteredReimbursementsProvider = Provider<List<Reimbursement>>((ref) {
  final items = ref.watch(reimburseProvider).value?.items ?? const [];
  final filter = ref.watch(reimburseCategoryFilterProvider);
  if (filter == 'Semua') return items;
  return items.where((item) {
    final category = item.category.toLowerCase();
    return switch (filter) {
      'Transport' =>
        category.contains('transport') || category.contains('parkir'),
      'Makan' => category.contains('makan') || category.contains('konsumsi'),
      'Kesehatan' =>
        category.contains('kesehatan') ||
            category.contains('obat') ||
            category.contains('klinik'),
      _ => true,
    };
  }).toList();
});

class ReimburseCategoryFilter extends Notifier<String> {
  @override
  String build() => 'Semua';

  void select(String value) => state = value;
}

class ReimburseController extends AsyncNotifier<ReimburseState> {
  static const _limit = 10;

  @override
  Future<ReimburseState> build() async {
    final results = await Future.wait([
      ref.read(reimburseServiceProvider).summary(),
      ref.read(reimburseServiceProvider).list(limit: _limit),
    ]);
    final page = results[1] as ReimbursePage;
    return ReimburseState(
      summary: results[0] as ReimburseSummary,
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
      ref.read(reimburseServiceProvider).summary(),
      ref
          .read(reimburseServiceProvider)
          .list(limit: _limit, status: current.filter),
    ]);
    final page = results[1] as ReimbursePage;
    state = AsyncData(
      current.copyWith(
        summary: results[0] as ReimburseSummary,
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
          .read(reimburseServiceProvider)
          .list(limit: _limit, status: filter);
      return current.copyWith(
        items: page.items,
        page: 1,
        total: page.total,
        hasMore: page.hasMore,
        filter: filter,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final page = await ref
        .read(reimburseServiceProvider)
        .list(page: current.page + 1, limit: _limit, status: current.filter);
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
    required String category,
    required int amount,
    required DateTime date,
    required String description,
    required String? receiptPath,
  }) async {
    final current = state.value;
    if (current == null) return false;
    if (amount <= 0 || description.trim().length < 5 || receiptPath == null) {
      state = AsyncData(
        current.copyWith(
          message: 'Nominal, keterangan, dan foto struk wajib diisi.',
        ),
      );
      return false;
    }
    state = AsyncData(current.copyWith(isSubmitting: true, clearMessage: true));
    try {
      final item = await ref
          .read(reimburseServiceProvider)
          .create(
            category: category,
            amount: amount,
            date: date,
            description: description.trim(),
            receiptPath: receiptPath,
          );
      state = AsyncData(
        current.copyWith(
          items: [item, ...current.items],
          total: current.total + 1,
          isSubmitting: false,
          message: 'Reimburse berhasil diajukan.',
        ),
      );
      return true;
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isSubmitting: false,
          message: networkErrorMessage(
            error,
            fallback: 'Reimburse gagal diajukan.',
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
          .read(reimburseServiceProvider)
          .decide(id, approve: approve, note: note);
      state = AsyncData(
        current.copyWith(
          items: [
            for (final item in current.items)
              if (item.id == id) updated else item,
          ],
          message: approve ? 'Reimburse disetujui.' : 'Reimburse ditolak.',
        ),
      );
      ref.invalidate(reimburseDetailProvider(id));
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
