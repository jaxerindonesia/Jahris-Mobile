import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import 'model.dart';

abstract interface class OvertimeService {
  Future<OvertimePage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? status,
  });
}

class ApiOvertimeService implements OvertimeService {
  const ApiOvertimeService(this._dio);
  final Dio _dio;

  @override
  Future<OvertimePage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? status,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.overtimes,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (query != null && query.isNotEmpty) 'search': query,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final rows = apiList(response.data, collectionKeys: const ['overtimes']);
    final meta = apiPageMeta(
      response.data,
      fallbackPage: page,
      itemCount: rows.length,
      limit: limit,
    );
    return OvertimePage(
      items: rows.map(OvertimeRecord.fromJson).toList(),
      page: meta.page,
      total: meta.total,
      hasMore: meta.hasMore,
    );
  }
}

class MockOvertimeService implements OvertimeService {
  const MockOvertimeService();

  @override
  Future<OvertimePage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final all = <OvertimeRecord>[
      OvertimeRecord(
        id: 'ot-1',
        employeeName: 'Kamu',
        date: DateTime(2026, 10, 30),
        hours: 3.5,
        status: 'Menunggu',
        startAt: DateTime(2026, 10, 30, 18),
        endAt: DateTime(2026, 10, 30, 20, 30),
        note: 'Deploy rilis Jahris v1.0',
        estimatedPay: 262500,
      ),
      OvertimeRecord(
        id: 'ot-2',
        employeeName: 'Kamu',
        date: DateTime(2026, 10, 21),
        hours: 2,
        status: 'Disetujui',
        startAt: DateTime(2026, 10, 21, 17, 30),
        endAt: DateTime(2026, 10, 21, 19, 30),
        note: 'Persiapan demo klien',
        estimatedPay: 150000,
      ),
      OvertimeRecord(
        id: 'ot-3',
        employeeName: 'Kamu',
        date: DateTime(2026, 10, 12),
        hours: 2,
        status: 'Disetujui',
        startAt: DateTime(2026, 10, 12, 17, 30),
        endAt: DateTime(2026, 10, 12, 19, 30),
        note: 'Bug fixing modul cuti',
        estimatedPay: 150000,
      ),
      OvertimeRecord(
        id: 'ot-4',
        employeeName: 'Kamu',
        date: DateTime(2026, 10, 2),
        hours: 1,
        status: 'Ditolak',
        startAt: DateTime(2026, 10, 2, 18),
        endAt: DateTime(2026, 10, 2, 19),
        note: 'Rapat evaluasi Q3',
        estimatedPay: 75000,
      ),
    ];
    final filtered = all.where((item) {
      final matchesQuery =
          query == null ||
          (item.employeeName ?? '').toLowerCase().contains(query.toLowerCase());
      final matchesStatus =
          status == null ||
          status.isEmpty ||
          (item.status ?? '').toLowerCase() == status.toLowerCase();
      return matchesQuery && matchesStatus;
    }).toList();
    return OvertimePage(
      items: filtered,
      page: page,
      total: filtered.length,
      hasMore: false,
    );
  }
}
