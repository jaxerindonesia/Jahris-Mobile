import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import 'model.dart';

abstract interface class ReimburseService {
  Future<ReimbursePage> list({int page = 1, int limit = 10, String? status});
  Future<ReimburseSummary> summary();
  Future<Reimbursement> detail(String id);
  Future<Reimbursement> create({
    required String category,
    required int amount,
    required DateTime date,
    required String description,
    required String receiptPath,
  });
  Future<Reimbursement> decide(
    String id, {
    required bool approve,
    String? note,
  });
}

class ApiReimburseService implements ReimburseService {
  const ApiReimburseService(this._dio, {required this.userId});
  final Dio _dio;
  final String userId;

  @override
  Future<ReimbursePage> list({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.reimbursements,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status != 'Semua') 'status': _statusValue(status),
      },
    );
    final raw = apiList(
      response.data,
      collectionKeys: const ['reimbursements'],
    );
    final meta = apiPageMeta(
      response.data,
      fallbackPage: page,
      itemCount: raw.length,
      limit: limit,
    );
    return ReimbursePage(
      items: raw.map(Reimbursement.fromJson).toList(),
      page: meta.page,
      total: meta.total,
      hasMore: meta.hasMore,
    );
  }

  @override
  Future<ReimburseSummary> summary() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.reimbursements,
      queryParameters: {'limit': 999999},
    );
    final items = apiList(
      response.data,
      collectionKeys: const ['reimbursements'],
    ).map(Reimbursement.fromJson).toList();
    int sum(String status) => items
        .where((item) => item.status.toUpperCase() == status)
        .fold(0, (sum, item) => sum + item.amount);
    return ReimburseSummary(
      submitted: items.fold(0, (sum, item) => sum + item.amount),
      approved: sum('APPROVED'),
      pending: sum('PENDING'),
    );
  }

  @override
  Future<Reimbursement> detail(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.reimbursement(id),
    );
    return Reimbursement.fromJson(apiObject(response.data));
  }

  @override
  Future<Reimbursement> create({
    required String category,
    required int amount,
    required DateTime date,
    required String description,
    required String receiptPath,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.reimbursements,
      data: FormData.fromMap({
        'userId': userId,
        'title': category,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'description': description,
        'status': 'PENDING',
        'details': jsonEncode([
          {
            'category': category,
            'description': description,
            'amount': amount,
            'date': date.toIso8601String(),
            'receiptUrls': <String>[],
          },
        ]),
        'receipt-0': await MultipartFile.fromFile(receiptPath),
      }),
    );
    return Reimbursement.fromJson(apiObject(response.data));
  }

  @override
  Future<Reimbursement> decide(
    String id, {
    required bool approve,
    String? note,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiEndpoints.reimbursement(id),
      data: {
        'status': approve ? 'APPROVED' : 'REJECTED',
        'approvedAt': DateTime.now().toIso8601String(),
      },
    );
    return Reimbursement.fromJson(apiObject(response.data));
  }

  String _statusValue(String status) => switch (status.toLowerCase()) {
    'menunggu' => 'PENDING',
    'disetujui' => 'APPROVED',
    'ditolak' => 'REJECTED',
    'dibayar' => 'PAID',
    _ => status,
  };
}

class MockReimburseService implements ReimburseService {
  MockReimburseService({this.userName = 'Pengguna JAHRIS'});

  final String userName;

  final List<Reimbursement> _items = [
    Reimbursement(
      id: 'reimburse-1',
      employeeName: 'Pengguna JAHRIS',
      category: 'Transportasi',
      amount: 150000,
      date: DateTime(2026, 10, 28),
      status: 'Menunggu',
      description: 'Transport ke klien',
    ),
    Reimbursement(
      id: 'reimburse-2',
      employeeName: 'Pengguna JAHRIS',
      category: 'Konsumsi',
      amount: 325000,
      date: DateTime(2026, 10, 22),
      status: 'Disetujui',
      description: 'Makan siang klien',
    ),
    Reimbursement(
      id: 'reimburse-3',
      employeeName: 'Pengguna JAHRIS',
      category: 'Kesehatan',
      amount: 210000,
      date: DateTime(2026, 10, 15),
      status: 'Disetujui',
      description: 'Obat & klinik',
    ),
    Reimbursement(
      id: 'reimburse-4',
      employeeName: 'Pengguna JAHRIS',
      category: 'Transportasi',
      amount: 115000,
      date: DateTime(2026, 10, 9),
      status: 'Disetujui',
      description: 'Parkir & tol',
    ),
    Reimbursement(
      id: 'reimburse-5',
      employeeName: 'Pengguna JAHRIS',
      category: 'Operasional',
      amount: 89000,
      date: DateTime(2026, 10, 3),
      status: 'Ditolak',
      description: 'Pembelian ATK',
    ),
  ];

  @override
  Future<ReimbursePage> list({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 430));
    final filtered = status == null || status == 'Semua'
        ? _items
        : _items.where((item) => item.status == status).toList();
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, filtered.length);
    return ReimbursePage(
      items: start >= filtered.length ? [] : filtered.sublist(start, end),
      page: page,
      total: filtered.length,
      hasMore: end < filtered.length,
    );
  }

  @override
  Future<ReimburseSummary> summary() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return ReimburseSummary(
      submitted: _items.fold(0, (sum, item) => sum + item.amount),
      approved: _items
          .where(
            (item) => item.status == 'Disetujui' || item.status == 'Dibayar',
          )
          .fold(0, (sum, item) => sum + item.amount),
      pending: _items
          .where((item) => item.status == 'Menunggu')
          .fold(0, (sum, item) => sum + item.amount),
    );
  }

  @override
  Future<Reimbursement> detail(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return _items.firstWhere((item) => item.id == id);
  }

  @override
  Future<Reimbursement> create({
    required String category,
    required int amount,
    required DateTime date,
    required String description,
    required String receiptPath,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final item = Reimbursement(
      id: 'reimburse-new-${_items.length}',
      employeeName: userName,
      category: category,
      amount: amount,
      date: date,
      status: 'Menunggu',
      description: description,
      receiptPath: receiptPath,
    );
    _items.insert(0, item);
    return item;
  }

  @override
  Future<Reimbursement> decide(
    String id, {
    required bool approve,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Reimburse tidak ditemukan.');
    final updated = _items[index].copyWith(
      status: approve ? 'Disetujui' : 'Ditolak',
      approvalNote: note,
    );
    _items[index] = updated;
    return updated;
  }
}
