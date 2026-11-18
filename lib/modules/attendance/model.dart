enum LocationAccessStatus { belum, ditolak, diizinkan, layananNonaktif }

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.employeeName,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.branchName = '-',
    this.faceVerified = false,
  });

  final String id;
  final String employeeName;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status;
  final String branchName;
  final bool faceVerified;

  bool get isLate =>
      const ['terlambat', 'late'].any(status.toLowerCase().contains);
  bool get isLeave => const [
    'izin',
    'cuti',
    'sakit',
    'leave',
    'sick',
  ].any(status.toLowerCase().contains);
  bool get isAbsent =>
      const ['alpha', 'alpa', 'absent'].any(status.toLowerCase().contains);
  String get statusLabel => isLate
      ? 'Terlambat'
      : isLeave
      ? 'Izin'
      : isAbsent
      ? 'Alpha'
      : 'Tepat Waktu';
  Duration get duration =>
      checkIn != null && checkOut != null && !checkOut!.isBefore(checkIn!)
      ? checkOut!.difference(checkIn!)
      : Duration.zero;

  // Terverifikasi dari GET /attendances pada 21 Oktober 2026.
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      employeeName: user is Map<String, dynamic>
          ? user['name'] as String? ?? '-'
          : json['employeeName'] as String? ?? '-',
      date:
          _apiDateTime(json['attendanceDay'] ?? json['date']) ?? DateTime.now(),
      checkIn: _apiDateTime(
        json['checkIn'] ?? json['checkInTime'] ?? json['check_in'],
      ),
      checkOut: _apiDateTime(
        json['checkOut'] ?? json['checkOutTime'] ?? json['check_out'],
      ),
      status: json['status'] as String? ?? 'Tepat Waktu',
      branchName: json['branchName'] as String? ?? '-',
      faceVerified:
          json['checkInFaceImage'] != null || json['checkOutFaceImage'] != null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeName': employeeName,
    'date': date.toIso8601String(),
    'checkIn': checkIn?.toIso8601String(),
    'checkOut': checkOut?.toIso8601String(),
    'status': status,
    'branchName': branchName,
    'faceVerified': faceVerified,
  };
}

DateTime? _apiDateTime(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

class AttendanceCheckRequest {
  const AttendanceCheckRequest({
    required this.isIn,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.employeeId,
  });

  final bool isIn;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String employeeId;
}

class AttendanceConfig {
  const AttendanceConfig({
    required this.startHour,
    required this.endHour,
    required this.toleranceMinutes,
    required this.branchName,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.raw = const {},
  });

  final String startHour;
  final String endHour;
  final int toleranceMinutes;
  final String branchName;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final Map<String, dynamic> raw;

  // Terverifikasi dari GET /attendance-config pada 22 Oktober 2026.
  // Catatan: endpoint tidak mengembalikan koordinat cabang (lat/lng/radius),
  // koordinat diambil dari data cabang user secara terpisah.
  factory AttendanceConfig.fromJson(Map<String, dynamic> json) {
    return AttendanceConfig(
      startHour: json['officeStartTime'] as String? ?? '08:00',
      endHour: json['officeEndTime'] as String? ?? '17:00',
      toleranceMinutes: (json['lateToleranceMinutes'] as num?)?.toInt() ?? 15,
      branchName: json['branchName'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 100,
      raw: Map.unmodifiable(json),
    );
  }

  Map<String, dynamic> toJson() => {
    ...raw,
    'officeStartTime': startHour,
    'officeEndTime': endHour,
    'lateToleranceMinutes': toleranceMinutes,
  };

  AttendanceConfig withBranch({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) => AttendanceConfig(
    startHour: startHour,
    endHour: endHour,
    toleranceMinutes: toleranceMinutes,
    branchName: name,
    latitude: latitude,
    longitude: longitude,
    radiusMeters: radiusMeters,
    raw: raw,
  );
}

class AttendancePage {
  const AttendancePage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });

  final List<AttendanceRecord> items;
  final int page;
  final int total;
  final bool hasMore;
}

class AttendanceState {
  const AttendanceState({
    required this.records,
    required this.config,
    required this.now,
    required this.locationStatus,
    required this.page,
    required this.total,
    required this.hasMore,
    this.from,
    this.to,
    this.checkIn,
    this.checkOut,
    this.distanceMeters,
    this.message,
    this.isChecking = false,
    this.isExporting = false,
  });

  final List<AttendanceRecord> records;
  final AttendanceConfig config;
  final DateTime now;
  final LocationAccessStatus locationStatus;
  final int page;
  final int total;
  final bool hasMore;
  final DateTime? from;
  final DateTime? to;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final double? distanceMeters;
  final String? message;
  final bool isChecking;
  final bool isExporting;

  DateTime get selectedMonth =>
      DateTime((from ?? now).year, (from ?? now).month);
  List<AttendanceRecord> get monthRecords =>
      records
          .where(
            (item) =>
                item.date.year == selectedMonth.year &&
                item.date.month == selectedMonth.month,
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  AttendanceMonthlySummary get monthlySummary =>
      AttendanceMonthlySummary.fromRecords(monthRecords);
  bool get isWorking => checkIn != null && checkOut == null;
  String get todayStatus => isWorking
      ? 'Sedang Bekerja'
      : checkOut != null
      ? 'Selesai'
      : 'Belum Masuk';
  Duration get workingDuration {
    final start = checkIn;
    final end = checkOut ?? now;
    return start == null || end.isBefore(start)
        ? Duration.zero
        : end.difference(start);
  }

  AttendanceState copyWith({
    List<AttendanceRecord>? records,
    AttendanceConfig? config,
    DateTime? now,
    LocationAccessStatus? locationStatus,
    int? page,
    int? total,
    bool? hasMore,
    DateTime? from,
    DateTime? to,
    DateTime? checkIn,
    DateTime? checkOut,
    double? distanceMeters,
    String? message,
    bool clearMessage = false,
    bool? isChecking,
    bool? isExporting,
  }) {
    return AttendanceState(
      records: records ?? this.records,
      config: config ?? this.config,
      now: now ?? this.now,
      locationStatus: locationStatus ?? this.locationStatus,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      from: from ?? this.from,
      to: to ?? this.to,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      message: clearMessage ? null : message ?? this.message,
      isChecking: isChecking ?? this.isChecking,
      isExporting: isExporting ?? this.isExporting,
    );
  }
}

class AttendanceMonthlySummary {
  const AttendanceMonthlySummary({
    required this.onTime,
    required this.late,
    required this.leave,
    required this.absent,
  });
  final int onTime;
  final int late;
  final int leave;
  final int absent;
  double get rate {
    final total = onTime + late + leave + absent;
    return total == 0 ? 0 : (onTime + late) / total;
  }

  factory AttendanceMonthlySummary.fromRecords(List<AttendanceRecord> records) {
    var onTime = 0, late = 0, leave = 0, absent = 0;
    for (final record in records) {
      if (record.isLeave) {
        leave++;
      } else if (record.isAbsent) {
        absent++;
      } else if (record.isLate) {
        late++;
      } else {
        onTime++;
      }
    }
    return AttendanceMonthlySummary(
      onTime: onTime,
      late: late,
      leave: leave,
      absent: absent,
    );
  }
}

/// State halaman Riwayat Absen (kalender bulanan).
class AttendanceHistoryState {
  const AttendanceHistoryState({
    required this.month,
    required this.records,
    this.statusFilter = 'Semua',
  });

  /// Hari pertama bulan yang ditampilkan.
  final DateTime month;
  final List<AttendanceRecord> records;

  /// Semua, Tepat Waktu, Terlambat, atau Izin.
  final String statusFilter;

  static const statusFilters = ['Semua', 'Tepat Waktu', 'Terlambat', 'Izin'];

  AttendanceRecord? recordOn(DateTime day) {
    for (final record in records) {
      if (record.date.year == day.year &&
          record.date.month == day.month &&
          record.date.day == day.day) {
        return record;
      }
    }
    return null;
  }

  /// Detail harian terbaru di atas, sesuai filter status.
  List<AttendanceRecord> get dailyRecords {
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
    if (statusFilter == 'Semua') return sorted;
    return sorted.where((r) => r.statusLabel == statusFilter).toList();
  }

  List<AttendanceRecord> get _worked =>
      records.where((r) => r.checkIn != null && !r.isLeave).toList();

  /// Rata-rata jam masuk, `null` bila belum ada data.
  Duration? get averageCheckIn {
    final worked = _worked;
    if (worked.isEmpty) return null;
    final totalMinutes = worked.fold<int>(
      0,
      (sum, r) => sum + r.checkIn!.hour * 60 + r.checkIn!.minute,
    );
    return Duration(minutes: (totalMinutes / worked.length).round());
  }

  Duration get totalWorked =>
      records.fold(Duration.zero, (sum, r) => sum + r.duration);

  int get lateCount => records.where((r) => r.isLate).length;

  AttendanceHistoryState copyWith({
    DateTime? month,
    List<AttendanceRecord>? records,
    String? statusFilter,
  }) => AttendanceHistoryState(
    month: month ?? this.month,
    records: records ?? this.records,
    statusFilter: statusFilter ?? this.statusFilter,
  );
}
