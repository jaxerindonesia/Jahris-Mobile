import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import 'model.dart';

abstract interface class DashboardService {
  Future<DashboardSummary> getSummary();
}

class ApiDashboardService implements DashboardService {
  const ApiDashboardService(this._dio);

  final Dio _dio;

  @override
  Future<DashboardSummary> getSummary() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.dashboard,
    );
    final envelope = response.data ?? const <String, dynamic>{};
    final data = (envelope['data'] as Map<String, dynamic>?) ?? envelope;
    return DashboardSummary.fromJson(data);
  }
}

class MockDashboardService implements DashboardService {
  const MockDashboardService();

  @override
  Future<DashboardSummary> getSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    return DashboardSummary(
      stats: const [
        DashboardStat(
          key: 'employees',
          label: 'Total Karyawan',
          value: '30',
          description: 'Karyawan di tenant Anda',
        ),
        DashboardStat(
          key: 'active',
          label: 'Karyawan Aktif',
          value: '22',
          description: '8 tidak aktif',
        ),
        DashboardStat(
          key: 'departments',
          label: 'Total Departemen',
          value: '5',
          description: 'Departemen terdaftar',
        ),
        DashboardStat(
          key: 'pending',
          label: 'Perlu Persetujuan',
          value: '7',
          description: 'Cuti dan reimburse',
        ),
      ],
      recentSubmissions: [
        RecentSubmission(
          id: 'submission-1',
          employeeName: 'Nadia Putri',
          type: 'Cuti Tahunan',
          status: 'Menunggu',
          submittedAt: DateTime(2026, 11, 3),
          detail: '3–5 Nov 2026',
        ),
        RecentSubmission(
          id: 'submission-2',
          employeeName: 'Nadia Putri',
          type: 'Reimburse Transport',
          status: 'Disetujui',
          submittedAt: DateTime(2026, 11, 2),
          detail: 'Rp 150.000',
        ),
      ],
    );
  }
}
