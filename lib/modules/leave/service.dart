import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import 'model.dart';

abstract interface class LeaveService {
  Future<LeavePage> list({int page = 1, int limit = 10, String? status});
  Future<LeaveBalance> balance();
  Future<List<SubmissionType>> types();
  Future<LeaveRequest> create({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentPath,
  });
  Future<LeaveRequest> decide(String id, {required bool approve, String? note});
  Future<LeaveRequest> detail(String id);
}

class ApiLeaveService implements LeaveService {
  const ApiLeaveService(this._dio, {required this.userId});
  final Dio _dio;
  final String userId;

  @override
  Future<LeavePage> list({int page = 1, int limit = 10, String? status}) async {
    // Backend /submissions tidak mendukung query params (404 jika ada params).
    // Ambil semua data sekaligus, lalu lakukan filtering & pagination di sisi klien.
    final response = await _dio.get<dynamic>(ApiEndpoints.submissions);
    var raw = apiList(response.data, collectionKeys: const ['submissions']);
    // Filter status di sisi klien jika diperlukan
    if (status != null && status != 'Semua') {
      final statusLower = status.toLowerCase();
      raw = raw.where((item) {
        final itemStatus = (item['status'] as String? ?? '').toLowerCase();
        return itemStatus == statusLower ||
            itemStatus.contains(statusLower) ||
            statusLower.contains(itemStatus);
      }).toList();
    }
    final total = raw.length;
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, total);
    final items = start >= total
        ? <Map<String, dynamic>>[]
        : raw.sublist(start, end);
    return LeavePage(
      items: items.map(LeaveRequest.fromJson).toList(),
      page: page,
      total: total,
      hasMore: end < total,
    );
  }

  @override
  Future<LeaveBalance> balance() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.leaveConfigs);
      final configs = apiList(
        response.data,
        collectionKeys: const ['leaveConfigs'],
      );
      final total = configs.fold<int>(
        0,
        (sum, item) => sum + ((item['maxDays'] as num?)?.toInt() ?? 0),
      );
      return LeaveBalance(total: total, used: 0, remaining: total);
    } catch (_) {
      // Endpoint /leave-configs memerlukan hak akses admin (403 Forbidden untuk karyawan).
      // Fallback ke kuota standar 12 hari agar halaman Cuti karyawan tetap terbuka lancar.
      return const LeaveBalance(total: 12, used: 0, remaining: 12);
    }
  }

  @override
  Future<List<SubmissionType>> types() async {
    // Backend /submission-types tidak mendukung query params.
    final response = await _dio.get<dynamic>(ApiEndpoints.submissionTypes);
    return apiList(
      response.data,
      collectionKeys: const ['submissionTypes'],
    ).map(SubmissionType.fromJson).toList();
  }

  @override
  Future<LeaveRequest> create({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentPath,
  }) async {
    if (userId.isEmpty) {
      throw StateError('Sesi pengguna tidak tersedia. Silakan login kembali.');
    }
    final availableTypes = await types();
    SubmissionType? selectedType;
    for (final item in availableTypes) {
      if (item.id == type || item.name.toLowerCase() == type.toLowerCase()) {
        selectedType = item;
        break;
      }
    }
    if (selectedType == null || selectedType.id.isEmpty) {
      throw StateError('Jenis cuti tidak valid. Muat ulang daftar jenis cuti.');
    }
    final form = FormData.fromMap({
      'userId': userId,
      'submissionTypeId': selectedType.id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      if (attachmentPath != null)
        'attachment': await MultipartFile.fromFile(attachmentPath),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.submissions,
      data: form,
    );
    return LeaveRequest.fromJson(apiObject(response.data));
  }

  @override
  Future<LeaveRequest> decide(
    String id, {
    required bool approve,
    String? note,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiEndpoints.submission(id),
      data: {
        'approvalAction': approve ? 'APPROVE' : 'REJECT',
        if (!approve) 'rejectionReason': note,
      },
    );
    return LeaveRequest.fromJson(apiObject(response.data));
  }

  @override
  Future<LeaveRequest> detail(String id) async {
    final response = await _dio.get<dynamic>(ApiEndpoints.submission(id));
    return LeaveRequest.fromJson(apiObject(response.data));
  }
}

class MockLeaveService implements LeaveService {
  MockLeaveService({this.userName = 'Pengguna JAHRIS'});

  final String userName;

  @override
  Future<List<SubmissionType>> types() async => const [
    SubmissionType(id: 'annual-leave', name: 'Cuti Tahunan'),
    SubmissionType(id: 'sick-leave', name: 'Cuti Sakit'),
    SubmissionType(id: 'permission', name: 'Izin'),
  ];

  final List<LeaveRequest> _items = [
    LeaveRequest(
      id: 'submission-1',
      employeeName: 'Budi Santoso',
      type: 'Cuti Tahunan',
      startDate: DateTime(2026, 10, 24),
      endDate: DateTime(2026, 10, 26),
      reason: 'Acara keluarga di luar kota.',
      status: 'Menunggu',
      submittedAt: DateTime(2026, 10, 20),
      department: 'IT Support',
      durationLabel: '3 Hari',
    ),
    LeaveRequest(
      id: 'leave-2',
      employeeName: 'Citra Dewi',
      type: 'Cuti Sakit',
      startDate: DateTime(2026, 10, 18),
      endDate: DateTime(2026, 10, 19),
      reason: 'Pemulihan kesehatan.',
      status: 'Disetujui',
      submittedAt: DateTime(2026, 10, 17),
      attachmentName: 'Surat_Dokter_Terlampir.pdf',
      department: 'Marketing',
      durationLabel: '2 Hari',
      reviewedBy: 'HR Manager (R. Pratama)',
    ),
    LeaveRequest(
      id: 'leave-3',
      employeeName: 'Annisa Permata',
      type: 'Cuti Melahirkan',
      startDate: DateTime(2026, 11),
      endDate: DateTime(2027, 2),
      reason: 'Rekomendasi dokter spesialis kandungan terlampir di lampiran berkas.',
      status: 'Menunggu',
      submittedAt: DateTime(2026, 10, 18),
      department: 'Finance',
      durationLabel: '3 Bulan',
    ),
    LeaveRequest(
      id: 'leave-4',
      employeeName: 'Reza Pahlevi',
      type: 'Izin Setengah Hari',
      startDate: DateTime(2026, 10, 12),
      endDate: DateTime(2026, 10, 12),
      reason:
          'Jadwal piket maintenance darurat unit server sedang berlangsung.',
      status: 'Ditolak',
      submittedAt: DateTime(2026, 10, 10),
      department: 'Operasional',
      durationLabel: '4 Jam',
      reviewedBy: 'HR Manager (R. Pratama)',
    ),
    LeaveRequest(
      id: 'leave-5',
      employeeName: 'Maya Sari',
      type: 'Cuti Tahunan',
      startDate: DateTime(2026, 12, 21),
      endDate: DateTime(2026, 12, 23),
      reason: 'Keperluan keluarga.',
      status: 'Disetujui',
      submittedAt: DateTime(2026, 10, 9),
      department: 'Human Resources',
      durationLabel: '3 Hari',
    ),
  ];

  @override
  Future<LeavePage> list({int page = 1, int limit = 10, String? status}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final filtered = status == null || status == 'Semua'
        ? _items
        : _items.where((item) => item.status == status).toList();
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, filtered.length);
    return LeavePage(
      items: start >= filtered.length ? [] : filtered.sublist(start, end),
      page: page,
      total: filtered.length,
      hasMore: end < filtered.length,
    );
  }

  @override
  Future<LeaveBalance> balance() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const LeaveBalance(total: 12, used: 4, remaining: 8);
  }

  @override
  Future<LeaveRequest> create({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentPath,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final item = LeaveRequest(
      id: 'leave-new-${_items.length}',
      employeeName: userName,
      type: type,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: 'Menunggu',
      submittedAt: DateTime.now(),
      attachmentName: attachmentPath?.split(RegExp(r'[/\\]')).last,
    );
    _items.insert(0, item);
    return item;
  }

  @override
  Future<LeaveRequest> decide(
    String id, {
    required bool approve,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Pengajuan tidak ditemukan.');
    final updated = _items[index].copyWith(
      status: approve ? 'Disetujui' : 'Ditolak',
      approvalNote: note,
    );
    _items[index] = updated;
    return updated;
  }

  @override
  Future<LeaveRequest> detail(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _items.firstWhere((item) => item.id == id);
  }
}
