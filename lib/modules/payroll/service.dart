import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import 'model.dart';

abstract interface class PayrollService {
  Future<PayrollSummary> summary();
  Future<PayrollPage> slips({int page = 1, int limit = 10});
  Future<PayrollSlip> slipDetail(String id);
  Future<Uint8List> downloadSlip(String id);
  Future<List<PayrollComponent>> components();
  Future<PayrollComponent> saveComponent(PayrollComponent component);
  Future<void> deleteComponent(String id);
}

class ApiPayrollService implements PayrollService {
  const ApiPayrollService(this._dio);
  final Dio _dio;

  @override
  Future<PayrollSummary> summary() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.payrollSummary,
      queryParameters: {'year': DateTime.now().year},
    );
    return PayrollSummary.fromJson(_data(response.data));
  }

  @override
  Future<PayrollPage> slips({int page = 1, int limit = 10}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.payrolls,
      queryParameters: {'page': page, 'limit': limit},
    );
    final body = response.data ?? const <String, dynamic>{};
    final raw = apiList(body, collectionKeys: const ['payrolls']);
    final meta = apiPageMeta(
      body,
      fallbackPage: page,
      itemCount: raw.length,
      limit: limit,
    );
    return PayrollPage(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(PayrollSlip.fromJson)
          .toList(),
      page: meta.page,
      total: meta.total,
      hasMore: meta.hasMore,
    );
  }

  @override
  Future<PayrollSlip> slipDetail(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.payroll(id),
    );
    return PayrollSlip.fromJson(_data(response.data));
  }

  @override
  Future<Uint8List> downloadSlip(String id) async {
    final slip = await slipDetail(id);
    // API web membangun PDF di browser dan belum menyediakan endpoint PDF.
    return Uint8List.fromList(
      utf8.encode(
        '%PDF-1.4\n% JAHRIS ${slip.employeeName} ${slip.period} ${slip.net}\n%%EOF',
      ),
    );
  }

  @override
  Future<List<PayrollComponent>> components() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.payrollComponentConfig,
    );
    final body = response.data ?? const <String, dynamic>{};
    final raw = body['data'] as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PayrollComponent.fromJson)
        .toList();
  }

  @override
  Future<PayrollComponent> saveComponent(PayrollComponent component) async {
    final response = component.id.isEmpty
        ? await _dio.post<Map<String, dynamic>>(
            ApiEndpoints.payrollComponentConfig,
            data: component.toJson(),
          )
        : await _dio.put<Map<String, dynamic>>(
            ApiEndpoints.payrollComponent(component.id),
            data: component.toJson(),
          );
    return PayrollComponent.fromJson(_data(response.data));
  }

  @override
  Future<void> deleteComponent(String id) =>
      _dio.delete<void>(ApiEndpoints.payrollComponent(id));

  Map<String, dynamic> _data(Map<String, dynamic>? envelope) {
    final body = envelope ?? const <String, dynamic>{};
    return body['data'] as Map<String, dynamic>? ?? body;
  }
}

class MockPayrollService implements PayrollService {
  MockPayrollService();

  final List<PayrollSlip> _slips = List.generate(18, (index) {
    final period = DateTime(2026, 10 - index);
    final overtime = index == 0 ? 487500 : 300000 - (index % 3) * 50000;
    final pph = index == 0
        ? 422500
        : index <= 2
        ? 672500 - (index - 1) * 50000
        : 380000;
    final lines = [
      const PayrollLine(name: 'Gaji Pokok', amount: 7500000),
      const PayrollLine(name: 'Tunjangan Transport', amount: 750000),
      const PayrollLine(name: 'Tunjangan Makan', amount: 660000),
      PayrollLine(
        name: index == 0 ? 'Lembur (6j 30m)' : 'Lembur',
        amount: overtime,
      ),
      const PayrollLine(
        name: 'BPJS Kesehatan',
        amount: 75000,
        isDeduction: true,
      ),
      const PayrollLine(
        name: 'BPJS Ketenagakerjaan',
        amount: 150000,
        isDeduction: true,
      ),
      PayrollLine(name: 'PPh 21', amount: pph, isDeduction: true),
    ];
    final gross = lines
        .where((line) => !line.isDeduction)
        .fold(0, (sum, line) => sum + line.amount);
    final deductions = lines
        .where((line) => line.isDeduction)
        .fold(0, (sum, line) => sum + line.amount);
    return PayrollSlip(
      id: 'slip-${index + 1}',
      employeeName: index.isEven ? 'Nadia Putri' : 'Rizky Pratama',
      period: '${_monthNames[period.month - 1]} ${period.year}',
      gross: gross,
      deductions: deductions,
      net: gross - deductions,
      status: 'Dibayar',
      paidAt: DateTime(period.year, period.month, 25),
      periodDate: period,
      lines: lines,
    );
  });

  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  final List<PayrollComponent> _components = [
    const PayrollComponent(
      id: 'component-1',
      name: 'Gaji Pokok',
      type: 'Pendapatan',
      amount: 7500000,
      active: true,
    ),
    const PayrollComponent(
      id: 'component-2',
      name: 'Tunjangan Transportasi',
      type: 'Pendapatan',
      amount: 500000,
      active: true,
    ),
    const PayrollComponent(
      id: 'component-3',
      name: 'BPJS',
      type: 'Potongan',
      amount: 250000,
      active: true,
    ),
  ];

  @override
  Future<PayrollSummary> summary() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final paid = _slips
        .where((item) => item.status == 'Dibayar')
        .fold(0, (sum, item) => sum + item.net);
    final pending = _slips
        .where((item) => item.status == 'Pending')
        .fold(0, (sum, item) => sum + item.net);
    return PayrollSummary(
      paid: paid,
      pending: pending,
      total: paid + pending,
      year: 2026,
    );
  }

  @override
  Future<PayrollPage> slips({int page = 1, int limit = 10}) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, _slips.length);
    return PayrollPage(
      items: start >= _slips.length ? [] : _slips.sublist(start, end),
      page: page,
      total: _slips.length,
      hasMore: end < _slips.length,
    );
  }

  @override
  Future<PayrollSlip> slipDetail(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return _slips.firstWhere((item) => item.id == id);
  }

  @override
  Future<Uint8List> downloadSlip(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // TODO-BACKEND: mock menghasilkan dokumen PDF minimal; API menyediakan PDF resmi.
    return Uint8List.fromList(
      utf8.encode('%PDF-1.4\n% JAHRIS mock slip $id\n%%EOF'),
    );
  }

  @override
  Future<List<PayrollComponent>> components() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return List.unmodifiable(_components);
  }

  @override
  Future<PayrollComponent> saveComponent(PayrollComponent component) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (component.id.isEmpty) {
      final created = PayrollComponent(
        id: 'component-${_components.length + 1}',
        name: component.name,
        type: component.type,
        amount: component.amount,
        active: component.active,
      );
      _components.add(created);
      return created;
    }
    final index = _components.indexWhere((item) => item.id == component.id);
    if (index < 0) throw StateError('Komponen tidak ditemukan.');
    _components[index] = component;
    return component;
  }

  @override
  Future<void> deleteComponent(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _components.removeWhere((item) => item.id == id);
  }
}
