import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/network/dio_client.dart';
import 'model.dart';
import 'service.dart';

final taskServiceProvider = Provider<TaskService>((ref) {
  if (Env.useMock) return MockTaskService();
  return ApiTaskService(ref.watch(dioProvider));
});

final taskProvider = AsyncNotifierProvider<TaskController, TaskState>(
  TaskController.new,
);
final taskDetailProvider = FutureProvider.family<TaskItem, String>(
  (ref, id) => ref.watch(taskServiceProvider).detail(id),
);

class TaskController extends AsyncNotifier<TaskState> {
  static const _limit = 10;

  @override
  Future<TaskState> build() async {
    final page = await ref.read(taskServiceProvider).list(limit: _limit);
    return TaskState(
      items: page.items,
      page: page.page,
      total: page.total,
      hasMore: page.hasMore,
      allItems: page.allItems,
    );
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    final page = await ref
        .read(taskServiceProvider)
        .list(limit: _limit, status: current.filter);
    state = AsyncData(
      current.copyWith(
        items: page.items,
        page: 1,
        total: page.total,
        hasMore: page.hasMore,
        clearMessage: true,
        allItems: page.allItems,
      ),
    );
  }

  Future<void> setFilter(String filter) async {
    final current = state.value;
    if (current == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await ref
          .read(taskServiceProvider)
          .list(limit: _limit, status: filter);
      return current.copyWith(
        items: page.items,
        page: 1,
        total: page.total,
        hasMore: page.hasMore,
        filter: filter,
        allItems: page.allItems,
      );
    });
  }

  /// Pilih tanggal untuk memfilter tugas. Mengetuk tanggal yang sama lagi
  /// (atau mengirim `null`) mengembalikan tampilan ke semua tanggal.
  void selectDate(DateTime? date) {
    final current = state.value;
    if (current == null) return;
    final selected = current.selectedDate;
    final clear =
        date == null ||
        (selected != null && DateUtilsX.isSameDay(selected, date));
    state = AsyncData(
      current.copyWith(
        selectedDate: clear ? null : DateTime(date.year, date.month, date.day),
        clearSelectedDate: clear,
        clearMessage: true,
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final page = await ref
        .read(taskServiceProvider)
        .list(page: current.page + 1, limit: _limit, status: current.filter);
    state = AsyncData(
      current.copyWith(
        items: [...current.items, ...page.items],
        page: page.page,
        total: page.total,
        hasMore: page.hasMore,
        allItems: page.allItems,
      ),
    );
  }

  Future<bool> updateTask(String id, {String? status, String? comment}) async {
    final current = state.value;
    if (current == null) return false;
    try {
      final updated = await ref
          .read(taskServiceProvider)
          .update(id, status: status, comment: comment);
      final overview = [
        for (final item in current.overviewItems)
          if (item.id == id) updated else item,
      ];
      final filteredTotal = current.filter == 'Semua'
          ? current.total
          : overview.where((item) => item.matchesFilter(current.filter)).length;
      state = AsyncData(
        current.copyWith(
          items: [
            for (final item in current.items)
              if (item.id == id) updated else item,
          ].where((item) => item.matchesFilter(current.filter)).toList(),
          total: filteredTotal,
          message: 'Tugas berhasil diperbarui.',
          allItems: overview,
        ),
      );
      ref.invalidate(taskDetailProvider(id));
      return true;
    } catch (_) {
      state = AsyncData(current.copyWith(message: 'Tugas gagal diperbarui.'));
      return false;
    }
  }
}
