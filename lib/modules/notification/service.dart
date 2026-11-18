import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import 'model.dart';

abstract interface class NotificationService {
  Future<NotificationPage> list({int page = 1, int limit = 10});
  Future<void> registerDevice({
    required String token,
    required String platform,
  });
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class ApiNotificationService implements NotificationService {
  const ApiNotificationService(this._dio);
  final Dio _dio;

  @override
  Future<NotificationPage> list({int page = 1, int limit = 10}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.notifications,
      queryParameters: {'page': page, 'limit': limit},
    );
    final body = response.data ?? const <String, dynamic>{};
    final raw = body['data'] as List<dynamic>? ?? const [];
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};
    return NotificationPage(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList(),
      page: (meta['page'] as num?)?.toInt() ?? page,
      total: (meta['total'] as num?)?.toInt() ?? raw.length,
      hasMore: meta['hasMore'] as bool? ?? false,
    );
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) => _dio.post<void>(
    ApiEndpoints.devices,
    data: {'token': token, 'platform': platform},
  );

  @override
  Future<void> markRead(String id) =>
      _dio.patch<void>(ApiEndpoints.notificationRead(id));

  @override
  Future<void> markAllRead() =>
      _dio.patch<void>(ApiEndpoints.notificationsReadAll);
}

class MockNotificationService implements NotificationService {
  MockNotificationService();
  final List<AppNotification> _items = [
    AppNotification(
      id: 'notification-1',
      title: 'Pengajuan cuti menunggu',
      body: 'Pengajuan Nadia Putri memerlukan persetujuan Anda.',
      type: 'approval',
      createdAt: DateTime(2026, 10, 20, 14, 30),
      isRead: false,
      route: '/leave?approval=true',
    ),
    AppNotification(
      id: 'notification-2',
      title: 'Pengingat Check Out',
      body: 'Jangan lupa melakukan Check Out sebelum meninggalkan kantor.',
      type: 'attendance',
      createdAt: DateTime(2026, 10, 20, 16, 45),
      isRead: false,
      route: '/attendance',
    ),
    AppNotification(
      id: 'notification-3',
      title: 'Reimburse disetujui',
      body: 'Klaim transportasi Anda telah disetujui.',
      type: 'reimburse',
      createdAt: DateTime(2026, 10, 19, 10, 15),
      isRead: true,
      route: '/reimburse/detail/submission-2',
    ),
    ...List.generate(
      14,
      (index) => AppNotification(
        id: 'notification-${index + 4}',
        title: index.isEven ? 'Tugas diperbarui' : 'Informasi HR',
        body: index.isEven
            ? 'Status tugas Anda baru saja diperbarui.'
            : 'Ada informasi terbaru dari tim HR.',
        type: index.isEven ? 'task' : 'info',
        createdAt: DateTime(2026, 10, 18).subtract(Duration(days: index)),
        isRead: index > 2,
        route: index.isEven ? '/task' : null,
      ),
    ),
  ];

  @override
  Future<NotificationPage> list({int page = 1, int limit = 10}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, _items.length);
    return NotificationPage(
      items: start >= _items.length ? [] : _items.sublist(start, end),
      page: page,
      total: _items.length,
      hasMore: end < _items.length,
    );
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> markRead(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) _items[index] = _items[index].copyWith(isRead: true);
  }

  @override
  Future<void> markAllRead() async {
    for (var index = 0; index < _items.length; index++) {
      _items[index] = _items[index].copyWith(isRead: true);
    }
  }
}
