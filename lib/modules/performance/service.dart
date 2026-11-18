import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import 'model.dart';

abstract interface class PerformanceService {
  Future<PerformancePage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? status,
  });
}

class ApiPerformanceService implements PerformanceService {
  const ApiPerformanceService(this._dio);
  final Dio _dio;

  @override
  Future<PerformancePage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? status,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.performances,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (query != null && query.isNotEmpty) 'search': query,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final rows = apiList(response.data, collectionKeys: const ['performances']);
    final meta = apiPageMeta(
      response.data,
      fallbackPage: page,
      itemCount: rows.length,
      limit: limit,
    );
    return PerformancePage(
      items: rows.map(PerformanceRecord.fromJson).toList(),
      page: meta.page,
      total: meta.total,
      hasMore: meta.hasMore,
    );
  }
}

class MockPerformanceService implements PerformanceService {
  const MockPerformanceService();

  @override
  Future<PerformancePage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    const all = <PerformanceRecord>[
      PerformanceRecord(
        id: 'pf-1',
        employeeName: 'Nadia Putri',
        period: 'Oktober 2026',
        score: 88,
        status: 'Selesai',
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
    return PerformancePage(
      items: filtered,
      page: page,
      total: filtered.length,
      hasMore: false,
    );
  }
}
