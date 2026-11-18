class WorkingSchedule {
  const WorkingSchedule({
    required this.id,
    required this.branchId,
    required this.dayOfWeek,
    required this.isWorkDay,
    this.startTime,
    this.endTime,
    this.breakStart,
    this.breakEnd,
  });

  final String id;
  final String branchId;
  final String dayOfWeek;
  final bool isWorkDay;
  final String? startTime;
  final String? endTime;
  final String? breakStart;
  final String? breakEnd;

  factory WorkingSchedule.fromJson(Map<String, dynamic> json) =>
      WorkingSchedule(
        id: json['id']?.toString() ?? '',
        branchId: json['branchId']?.toString() ?? '',
        dayOfWeek: json['dayOfWeek']?.toString().toUpperCase() ?? '',
        isWorkDay: json['isWorkDay'] as bool? ?? false,
        startTime: _nullableText(json['startTime']),
        endTime: _nullableText(json['endTime']),
        breakStart: _nullableText(json['breakStartTime'] ?? json['breakStart']),
        breakEnd: _nullableText(json['breakEndTime'] ?? json['breakEnd']),
      );

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    if (branchId.isNotEmpty) 'branchId': branchId,
    'dayOfWeek': dayOfWeek,
    'isWorkDay': isWorkDay,
    'startTime': startTime,
    'endTime': endTime,
    if (breakStart != null) 'breakStartTime': breakStart,
    if (breakEnd != null) 'breakEndTime': breakEnd,
  };
}

class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.tenantId = '',
    this.active = true,
    this.locationLockEnabled = false,
    this.customWorkingHoursEnabled = false,
    this.scheduleType = 'REGULAR',
    this.officeStartTime = '09:00',
    this.officeEndTime = '17:00',
    this.workingSchedules = const [],
    this.raw = const {},
  });
  final String id;
  final String name;
  final String code;
  final String address;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String tenantId;
  final bool active;
  final bool locationLockEnabled;
  final bool customWorkingHoursEnabled;
  final String scheduleType;
  final String officeStartTime;
  final String officeEndTime;
  final List<WorkingSchedule> workingSchedules;
  final Map<String, dynamic> raw;

  // Terverifikasi dari GET /branches pada 21 Oktober 2026.
  factory Branch.fromJson(Map<String, dynamic> json) {
    final location = _jsonMap(json['location']);
    final coordinates = _jsonMap(json['coordinates']);
    return Branch(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      name: json['name'] as String? ?? '-',
      code: json['code'] as String? ?? '-',
      address: json['address'] as String? ?? '-',
      latitude: _firstDouble([
        json['latitude'],
        json['lat'],
        json['officeLatitude'],
        location['latitude'],
        location['lat'],
        coordinates['latitude'],
        coordinates['lat'],
      ]),
      longitude: _firstDouble([
        json['longitude'],
        json['lng'],
        json['officeLongitude'],
        location['longitude'],
        location['lng'],
        coordinates['longitude'],
        coordinates['lng'],
      ]),
      radiusMeters: _firstDouble([
        json['attendanceRadiusMeters'],
        json['radiusMeters'],
        json['radius'],
        location['radiusMeters'],
        location['radius'],
      ], fallback: 100),
      locationLockEnabled: json['locationLockEnabled'] as bool? ?? false,
      customWorkingHoursEnabled:
          json['customWorkingHoursEnabled'] as bool? ?? false,
      scheduleType: json['scheduleType']?.toString() ?? 'REGULAR',
      officeStartTime: json['officeStartTime']?.toString() ?? '09:00',
      officeEndTime: json['officeEndTime']?.toString() ?? '17:00',
      workingSchedules: (json['workingSchedules'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(WorkingSchedule.fromJson)
          .toList(growable: false),
      active: json['isActive'] as bool? ?? true,
      raw: Map.unmodifiable(json),
    );
  }
  Map<String, dynamic> toJson() => {
    ...raw,
    if (id.isNotEmpty) 'id': id,
    if (tenantId.isNotEmpty) 'tenantId': tenantId,
    'name': name,
    'code': code,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'attendanceRadiusMeters': radiusMeters,
    'locationLockEnabled': locationLockEnabled,
    'customWorkingHoursEnabled': customWorkingHoursEnabled,
    'scheduleType': scheduleType,
    'officeStartTime': officeStartTime,
    'officeEndTime': officeEndTime,
    if (workingSchedules.isNotEmpty)
      'workingSchedules': workingSchedules
          .map((item) => item.toJson())
          .toList(),
    'isActive': active,
  };
}

String? _nullableText(dynamic value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

double _double(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return value is String ? double.tryParse(value) ?? fallback : fallback;
}

Map<String, dynamic> _jsonMap(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};

double _firstDouble(List<dynamic> values, {double fallback = 0}) {
  for (final value in values) {
    final parsed = _double(value, fallback: double.nan);
    if (!parsed.isNaN) return parsed;
  }
  return fallback;
}

class BranchPage {
  const BranchPage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });
  final List<Branch> items;
  final int page;
  final int total;
  final bool hasMore;
}

class BranchState {
  const BranchState({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
    this.query = '',
    this.message,
    this.pickedLatitude,
    this.pickedLongitude,
    this.isLocating = false,
  });
  final List<Branch> items;
  final int page;
  final int total;
  final bool hasMore;
  final String query;
  final String? message;
  final double? pickedLatitude;
  final double? pickedLongitude;
  final bool isLocating;

  BranchState copyWith({
    List<Branch>? items,
    int? page,
    int? total,
    bool? hasMore,
    String? query,
    String? message,
    bool clearMessage = false,
    double? pickedLatitude,
    double? pickedLongitude,
    bool? isLocating,
  }) => BranchState(
    items: items ?? this.items,
    page: page ?? this.page,
    total: total ?? this.total,
    hasMore: hasMore ?? this.hasMore,
    query: query ?? this.query,
    message: clearMessage ? null : message ?? this.message,
    pickedLatitude: pickedLatitude ?? this.pickedLatitude,
    pickedLongitude: pickedLongitude ?? this.pickedLongitude,
    isLocating: isLocating ?? this.isLocating,
  );
}

class ShiftScheduleState {
  const ShiftScheduleState({
    required this.branch,
    required this.weekStart,
    required this.selectedDate,
  });

  final Branch branch;
  final DateTime weekStart;
  final DateTime selectedDate;

  List<DateTime> get weekDates => List.generate(
    7,
    (index) => DateTime(weekStart.year, weekStart.month, weekStart.day + index),
    growable: false,
  );

  WorkingSchedule? scheduleFor(DateTime date) {
    final day = switch (date.weekday) {
      DateTime.monday => 'MONDAY',
      DateTime.tuesday => 'TUESDAY',
      DateTime.wednesday => 'WEDNESDAY',
      DateTime.thursday => 'THURSDAY',
      DateTime.friday => 'FRIDAY',
      DateTime.saturday => 'SATURDAY',
      _ => 'SUNDAY',
    };
    for (final schedule in branch.workingSchedules) {
      if (schedule.dayOfWeek == day) return schedule;
    }
    return null;
  }

  ShiftScheduleState copyWith({DateTime? weekStart, DateTime? selectedDate}) =>
      ShiftScheduleState(
        branch: branch,
        weekStart: weekStart ?? this.weekStart,
        selectedDate: selectedDate ?? this.selectedDate,
      );
}
