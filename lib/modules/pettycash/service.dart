import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import 'model.dart';

abstract interface class PettyCashService {
  Future<PettyCashPage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? status,
  });
}

class ApiPettyCashService implements PettyCashService {
  const ApiPettyCashService(this._dio);
  final Dio _dio;

  @override
  Future<PettyCashPage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? status,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.pettyCash,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (query != null && query.isNotEmpty) 'search': query,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final rows = apiList(response.data, collectionKeys: const ['pettycash']);
    final meta = apiPageMeta(
      response.data,
      fallbackPage: page,
      itemCount: rows.length,
      limit: limit,
    );
    return PettyCashPage(
      items: rows.map(PettyCashRecord.fromJson).toList(),
      page: meta.page,
      total: meta.total,
      hasMore: meta.hasMore,
    );
  }
}

class MockPettyCashService implements PettyCashService {
  const MockPettyCashService();

  @override
  Future<PettyCashPage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final now = DateTime.now();
    DateTime ago(int days, int hour, int minute) =>
        DateTime(now.year, now.month, now.day - days, hour, minute);
    final all = <PettyCashRecord>[
      PettyCashRecord(
        id: 'pc-1',
        employeeName: 'Nadia Putri',
        purpose: 'Konsumsi rapat mingguan',
        category: 'Konsumsi',
        amount: 185000,
        date: ago(0, 10, 12),
        status: 'Disetujui',
        type: 'out',
      ),
      PettyCashRecord(
        id: 'pc-2',
        employeeName: 'Rizky Pratama',
        purpose: 'Kurir dokumen',
        category: 'Kurir',
        amount: 45000,
        date: ago(2, 15, 40),
        status: 'Disetujui',
        type: 'out',
      ),
      PettyCashRecord(
        id: 'pc-3',
        employeeName: 'Finance',
        purpose: 'Top up dari Finance',
        category: 'Top Up',
        amount: 2000000,
        date: ago(4, 9, 0),
        status: 'Disetujui',
        type: 'in',
      ),
      PettyCashRecord(
        id: 'pc-4',
        employeeName: 'Nadia Putri',
        purpose: 'Fotokopi berkas tender',
        category: 'ATK',
        amount: 30000,
        date: ago(5, 13, 25),
        status: 'Disetujui',
        type: 'out',
      ),
      PettyCashRecord(
        id: 'pc-5',
        employeeName: 'Rizky Pratama',
        purpose: 'Bensin operasional',
        category: 'Transportasi',
        amount: 200000,
        date: ago(6, 8, 10),
        status: 'Menunggu',
        type: 'out',
      ),
      PettyCashRecord(
        id: 'pc-6',
        employeeName: 'Finance',
        purpose: 'Saldo awal bulan',
        category: 'Top Up',
        amount: 3000000,
        date: ago(10, 8, 0),
        status: 'Disetujui',
        type: 'in',
      ),
    ];
    final filtered = all.where((item) {
      final term = query?.toLowerCase();
      final matchesQuery =
          term == null ||
          term.isEmpty ||
          (item.employeeName ?? '').toLowerCase().contains(term) ||
          (item.purpose ?? '').toLowerCase().contains(term);
      final matchesStatus =
          status == null ||
          status.isEmpty ||
          (item.status ?? '').toLowerCase() == status.toLowerCase();
      return matchesQuery && matchesStatus;
    }).toList();
    return PettyCashPage(
      items: filtered,
      page: page,
      total: filtered.length,
      hasMore: false,
    );
  }
}
