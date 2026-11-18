import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/network/dio_client.dart';
import 'model.dart';
import 'service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  if (Env.useMock) return MockNotificationService();
  return ApiNotificationService(ref.watch(dioProvider));
});
final notificationProvider =
    AsyncNotifierProvider<NotificationController, NotificationState>(
      NotificationController.new,
    );

class NotificationController extends AsyncNotifier<NotificationState> {
  static const _limit = 10;
  @override
  Future<NotificationState> build() async {
    final page = await ref
        .read(notificationServiceProvider)
        .list(limit: _limit);
    // TODO-FIREBASE: ganti token stub dengan FirebaseMessaging.instance.getToken().
    final token = Env.useMock
        ? 'mock-fcm-token'
        : const String.fromEnvironment('FCM_TOKEN', defaultValue: '');
    var registered = false;
    if (token.isNotEmpty) {
      await ref
          .read(notificationServiceProvider)
          .registerDevice(
            token: token,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
      registered = true;
    }
    return NotificationState(
      items: page.items,
      page: page.page,
      total: page.total,
      hasMore: page.hasMore,
      deviceRegistered: registered,
    );
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    final page = await ref
        .read(notificationServiceProvider)
        .list(limit: _limit);
    state = AsyncData(
      current.copyWith(
        items: page.items,
        page: 1,
        total: page.total,
        hasMore: page.hasMore,
        clearMessage: true,
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final page = await ref
        .read(notificationServiceProvider)
        .list(page: current.page + 1, limit: _limit);
    state = AsyncData(
      current.copyWith(
        items: [...current.items, ...page.items],
        page: page.page,
        total: page.total,
        hasMore: page.hasMore,
      ),
    );
  }

  Future<void> markRead(String id) async {
    final current = state.value;
    if (current == null) return;
    await ref.read(notificationServiceProvider).markRead(id);
    state = AsyncData(
      current.copyWith(
        items: [
          for (final item in current.items)
            if (item.id == id) item.copyWith(isRead: true) else item,
        ],
      ),
    );
  }

  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null) return;
    await ref.read(notificationServiceProvider).markAllRead();
    state = AsyncData(
      current.copyWith(
        items: current.items
            .map((item) => item.copyWith(isRead: true))
            .toList(),
        message: 'Semua notifikasi ditandai telah dibaca.',
      ),
    );
  }
}
