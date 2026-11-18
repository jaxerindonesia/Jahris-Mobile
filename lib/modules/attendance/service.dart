import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import 'model.dart';

abstract interface class AttendanceService {
  Future<AttendancePage> list({
    int page = 1,
    int limit = 10,
    DateTime? from,
    DateTime? to,
    String? userId,
  });
  Future<AttendanceConfig> getConfig();
  Future<AttendanceConfig> saveConfig(AttendanceConfig config);
  Future<AttendanceRecord> check({
    required bool isIn,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String faceVerificationToken,
    required String employeeId,
    required String faceCaptureBase64,
  });
  Future<Uint8List> export({DateTime? from, DateTime? to});
}

class ApiAttendanceService implements AttendanceService {
  const ApiAttendanceService(this._dio);

  final Dio _dio;

  @override
  Future<AttendancePage> list({
    int page = 1,
    int limit = 10,
    DateTime? from,
    DateTime? to,
    String? userId,
  }) async {
    final response = await _dio.get<dynamic>(
      userId == null
          ? ApiEndpoints.attendances
          : ApiEndpoints.userAttendances(userId),
      queryParameters: {
        'page': page,
        'limit': limit,
        if (from != null) 'startDate': from.toIso8601String(),
        if (to != null) 'endDate': to.toIso8601String(),
      },
    );
    final raw = apiList(response.data, collectionKeys: const ['attendances']);
    final meta = apiPageMeta(
      response.data,
      fallbackPage: page,
      itemCount: raw.length,
      limit: limit,
    );
    return AttendancePage(
      items: raw.map(AttendanceRecord.fromJson).toList(),
      page: meta.page,
      total: meta.total,
      hasMore: meta.hasMore,
    );
  }

  @override
  Future<AttendanceConfig> getConfig() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.attendanceConfig);
      return AttendanceConfig.fromJson(apiObject(response.data));
    } catch (_) {
      // Endpoint /attendance-config tidak dapat diakses, gunakan config default.
      // branchName dikosongkan agar nama cabang diambil dari data user/API, bukan hardcode.
      return const AttendanceConfig(
        startHour: '08:00',
        endHour: '17:00',
        toleranceMinutes: 15,
        branchName: '',
        latitude: 0,
        longitude: 0,
        radiusMeters: 100,
      );
    }
  }

  @override
  Future<AttendanceConfig> saveConfig(AttendanceConfig config) async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiEndpoints.attendanceConfig,
      data: config.toJson(),
    );
    return AttendanceConfig.fromJson(apiObject(response.data));
  }

  @override
  Future<AttendanceRecord> check({
    required bool isIn,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String faceVerificationToken,
    required String employeeId,
    required String faceCaptureBase64,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      isIn ? ApiEndpoints.attendanceCheckIn : ApiEndpoints.attendanceCheckOut,
      data: {
        'userId': employeeId,
        isIn ? 'checkInLocation' : 'checkOutLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
        },
        'faceCaptureBase64': faceCaptureBase64,
        'faceVerificationToken': faceVerificationToken,
      },
    );
    final data = apiObject(response.data);
    final nested = data['attendance'] ?? data['record'];
    return AttendanceRecord.fromJson(
      nested is Map<String, dynamic> ? nested : data,
    );
  }

  @override
  Future<Uint8List> export({DateTime? from, DateTime? to}) async {
    final page = await list(page: 1, limit: 999999, from: from, to: to);
    final rows = <String>[
      'Nama,Tanggal,Check In,Check Out,Status,Cabang,Verifikasi Wajah',
      ...page.items.map(
        (item) => [
          item.employeeName,
          item.date.toIso8601String(),
          item.checkIn?.toIso8601String() ?? '',
          item.checkOut?.toIso8601String() ?? '',
          item.status,
          item.branchName,
          item.faceVerified ? 'Ya' : 'Tidak',
        ].map(_csvCell).join(','),
      ),
    ];
    return Uint8List.fromList(utf8.encode(rows.join('\n')));
  }

  String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';
}

class MockAttendanceService implements AttendanceService {
  MockAttendanceService({this.userName = 'Pengguna JAHRIS'});

  final String userName;

  static AttendanceConfig _config = const AttendanceConfig(
    startHour: '08:00',
    endHour: '17:00',
    toleranceMinutes: 15,
    branchName: 'Kantor Pusat',
    latitude: -6.2088,
    longitude: 106.8456,
    radiusMeters: 100,
  );

  final List<AttendanceRecord> _records = List.generate(24, (index) {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day - index - 1);
    if (index == 3) {
      return AttendanceRecord(
        id: 'attendance-${index + 1}',
        employeeName: 'Nadia Putri',
        date: date,
        status: 'Izin Sakit',
        branchName: 'Surat dokter terlampir',
      );
    }
    return AttendanceRecord(
      id: 'attendance-${index + 1}',
      employeeName: index.isEven ? 'Nadia Putri' : 'Rizky Pratama',
      date: date,
      checkIn: DateTime(
        date.year,
        date.month,
        date.day,
        8,
        index.isEven ? 7 : 23,
      ),
      checkOut: DateTime(date.year, date.month, date.day, 17, 18),
      status: index.isEven ? 'Tepat Waktu' : 'Terlambat',
      branchName: index % 3 == 0 ? 'Pusat' : 'Batam',
      faceVerified: true,
    );
  });

  @override
  Future<AttendancePage> list({
    int page = 1,
    int limit = 10,
    DateTime? from,
    DateTime? to,
    String? userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final filtered = _records.where((item) {
      final after = from == null || !item.date.isBefore(from);
      final before =
          to == null || !item.date.isAfter(to.add(const Duration(days: 1)));
      return after && before;
    }).toList();
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, filtered.length);
    final items = start >= filtered.length
        ? <AttendanceRecord>[]
        : filtered.sublist(start, end);
    return AttendancePage(
      items: items,
      page: page,
      total: filtered.length,
      hasMore: end < filtered.length,
    );
  }

  @override
  Future<AttendanceConfig> getConfig() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _config;
  }

  @override
  Future<AttendanceConfig> saveConfig(AttendanceConfig config) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _config = config;
    return _config;
  }

  @override
  Future<AttendanceRecord> check({
    required bool isIn,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String faceVerificationToken,
    required String employeeId,
    required String faceCaptureBase64,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final now = DateTime.now();
    return AttendanceRecord(
      id: 'attendance-now',
      employeeName: userName,
      date: DateTime(now.year, now.month, now.day),
      checkIn: isIn ? now : _records.first.checkIn,
      checkOut: isIn ? null : now,
      status: 'Tepat Waktu',
      branchName: _config.branchName,
      faceVerified: true,
    );
  }

  @override
  Future<Uint8List> export({DateTime? from, DateTime? to}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final rows = <String>['Nama,Tanggal,Check In,Check Out,Status,Cabang'];
    for (final item in _records) {
      rows.add(
        '${item.employeeName},${item.date.toIso8601String()},${item.checkIn?.toIso8601String() ?? ''},${item.checkOut?.toIso8601String() ?? ''},${item.status},${item.branchName}',
      );
    }
    return Uint8List.fromList(utf8.encode(rows.join('\n')));
  }
}
