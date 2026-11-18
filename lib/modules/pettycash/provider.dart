import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/network/dio_client.dart';
import 'model.dart';
import 'service.dart';

final pettyCashServiceProvider = Provider<PettyCashService>(
  (ref) => Env.useMock
      ? const MockPettyCashService()
      : ApiPettyCashService(ref.watch(dioProvider)),
);

final pettyCashProvider =
    AsyncNotifierProvider<PettyCashController, PettyCashState>(
      PettyCashController.new,
    );

class PettyCashState {
  const PettyCashState({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
    this.query = '',
    this.status = '',
  });
  final List<PettyCashRecord> items;
  final int page;
  final int total;
  final bool hasMore;
  final String query;
  final String status;

  PettyCashState copyWith({
    List<PettyCashRecord>? items,
    int? page,
    int? total,
    bool? hasMore,
    String? query,
    String? status,
  }) => PettyCashState(
    items: items ?? this.items,
    page: page ?? this.page,
    total: total ?? this.total,
    hasMore: hasMore ?? this.hasMore,
    query: query ?? this.query,
    status: status ?? this.status,
  );
}

class PettyCashController extends AsyncNotifier<PettyCashState> {
  static const _limit = 10;

  @override
  Future<PettyCashState> build() => _fetch();

  Future<PettyCashState> _fetch({
    int page = 1,
    String query = '',
    String status = '',
  }) async {
    final result = await ref
        .read(pettyCashServiceProvider)
        .list(page: page, limit: _limit, query: query, status: status);
    return PettyCashState(
      items: result.items,
      page: result.page,
      total: result.total,
      hasMore: result.hasMore,
      query: query,
      status: status,
    );
  }

  Future<void> search(String query) async {
    final status = state.value?.status ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(query: query.trim(), status: status),
    );
  }

  Future<void> filter(String status) async {
    final query = state.value?.query ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(query: query, status: status));
  }

  Future<void> refresh() async {
    final current = state.value;
    state = await AsyncValue.guard(
      () => _fetch(query: current?.query ?? '', status: current?.status ?? ''),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final result = await ref
        .read(pettyCashServiceProvider)
        .list(
          page: current.page + 1,
          limit: _limit,
          query: current.query,
          status: current.status,
        );
    state = AsyncData(
      current.copyWith(
        items: [...current.items, ...result.items],
        page: result.page,
        total: result.total,
        hasMore: result.hasMore,
      ),
    );
  }
}
