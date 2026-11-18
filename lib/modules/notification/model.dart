class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.route,
  });
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final String? route;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '-',
        body: json['body'] as String? ?? '-',
        type: json['type'] as String? ?? 'info',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
        route: json['route'] as String?,
      );
  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    body: body,
    type: type,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
    route: route,
  );
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });
  final List<AppNotification> items;
  final int page;
  final int total;
  final bool hasMore;
}

class NotificationState {
  const NotificationState({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
    required this.deviceRegistered,
    this.message,
  });
  final List<AppNotification> items;
  final int page;
  final int total;
  final bool hasMore;
  final bool deviceRegistered;
  final String? message;
  int get unreadCount => items.where((item) => !item.isRead).length;

  NotificationState copyWith({
    List<AppNotification>? items,
    int? page,
    int? total,
    bool? hasMore,
    bool? deviceRegistered,
    String? message,
    bool clearMessage = false,
  }) => NotificationState(
    items: items ?? this.items,
    page: page ?? this.page,
    total: total ?? this.total,
    hasMore: hasMore ?? this.hasMore,
    deviceRegistered: deviceRegistered ?? this.deviceRegistered,
    message: clearMessage ? null : message ?? this.message,
  );
}
