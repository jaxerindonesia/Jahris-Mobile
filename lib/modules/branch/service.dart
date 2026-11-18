import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import 'model.dart';

abstract interface class BranchService {
  Future<BranchPage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? tenantId,
  });
  Future<Branch> detail(String id);
  Future<Branch> save(Branch branch);
  Future<void> delete(String id);
}

class ApiBranchService implements BranchService {
  const ApiBranchService(this._dio);
  final Dio _dio;

  @override
  Future<BranchPage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? tenantId,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.branches,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (query != null && query.isNotEmpty) 'search': query,
        if (tenantId != null && tenantId.isNotEmpty) 'tenantId': tenantId,
      },
    );
    final raw = apiList(response.data, collectionKeys: const ['branches']);
    final meta = apiPageMeta(
      response.data,
      fallbackPage: page,
      itemCount: raw.length,
      limit: limit,
    );
    return BranchPage(
      items: raw.map(Branch.fromJson).toList(),
      page: meta.page,
      total: meta.total,
      hasMore: meta.hasMore,
    );
  }

  @override
  Future<Branch> detail(String id) async {
    final response = await _dio.get<dynamic>(ApiEndpoints.branch(id));
    final data = apiObject(response.data);
    final branch = data['branch'];
    return Branch.fromJson(branch is Map<String, dynamic> ? branch : data);
  }

  @override
  Future<Branch> save(Branch branch) async {
    final response = branch.id.isEmpty
        ? await _dio.post<Map<String, dynamic>>(
            ApiEndpoints.branches,
            data: branch.toJson(),
          )
        : await _dio.put<Map<String, dynamic>>(
            ApiEndpoints.branch(branch.id),
            data: branch.toJson(),
          );
    return Branch.fromJson(apiObject(response.data));
  }

  @override
  Future<void> delete(String id) => _dio.delete<void>(ApiEndpoints.branch(id));
}

class MockBranchService implements BranchService {
  MockBranchService();
  static const _workingSchedules = <WorkingSchedule>[
    WorkingSchedule(
      id: 'schedule-mon',
      branchId: 'branch-1',
      dayOfWeek: 'MONDAY',
      isWorkDay: true,
      startTime: '08:15',
      endTime: '17:15',
      breakStart: '12:00',
      breakEnd: '13:00',
    ),
    WorkingSchedule(
      id: 'schedule-tue',
      branchId: 'branch-1',
      dayOfWeek: 'TUESDAY',
      isWorkDay: true,
      startTime: '13:00',
      endTime: '22:00',
      breakStart: '17:00',
      breakEnd: '18:00',
    ),
    WorkingSchedule(
      id: 'schedule-wed',
      branchId: 'branch-1',
      dayOfWeek: 'WEDNESDAY',
      isWorkDay: true,
      startTime: '08:15',
      endTime: '17:15',
      breakStart: '12:00',
      breakEnd: '13:00',
    ),
    WorkingSchedule(
      id: 'schedule-thu',
      branchId: 'branch-1',
      dayOfWeek: 'THURSDAY',
      isWorkDay: true,
      startTime: '08:15',
      endTime: '17:15',
      breakStart: '12:00',
      breakEnd: '13:00',
    ),
    WorkingSchedule(
      id: 'schedule-fri',
      branchId: 'branch-1',
      dayOfWeek: 'FRIDAY',
      isWorkDay: true,
      startTime: '08:15',
      endTime: '17:15',
      breakStart: '12:00',
      breakEnd: '13:00',
    ),
    WorkingSchedule(
      id: 'schedule-sat',
      branchId: 'branch-1',
      dayOfWeek: 'SATURDAY',
      isWorkDay: false,
    ),
    WorkingSchedule(
      id: 'schedule-sun',
      branchId: 'branch-1',
      dayOfWeek: 'SUNDAY',
      isWorkDay: false,
    ),
  ];
  static final List<Branch> _items = [
    const Branch(
      id: 'branch-1',
      name: 'Batam',
      code: 'BATAM',
      address: 'Batam Center, Kepulauan Riau',
      latitude: 1.1301,
      longitude: 104.0529,
      radiusMeters: 100,
      scheduleType: 'SHIFT',
      customWorkingHoursEnabled: true,
      workingSchedules: _workingSchedules,
    ),
    const Branch(
      id: 'branch-2',
      name: 'Medan',
      code: 'MEDAN',
      address: 'Medan Kota, Sumatera Utara',
      latitude: 3.5952,
      longitude: 98.6722,
      radiusMeters: 100,
      customWorkingHoursEnabled: true,
      workingSchedules: _workingSchedules,
    ),
    const Branch(
      id: 'branch-3',
      name: 'Pusat',
      code: 'PUSAT',
      address: 'Jakarta Pusat, DKI Jakarta',
      latitude: -6.1754,
      longitude: 106.8272,
      radiusMeters: 50,
      customWorkingHoursEnabled: true,
      workingSchedules: _workingSchedules,
    ),
  ];

  @override
  Future<Branch> detail(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _items.firstWhere((item) => item.id == id);
  }

  @override
  Future<BranchPage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? tenantId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 380));
    final filtered = query == null || query.isEmpty
        ? _items
        : _items
              .where(
                (item) =>
                    item.name.toLowerCase().contains(query.toLowerCase()) ||
                    item.code.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, filtered.length);
    return BranchPage(
      items: start >= filtered.length ? [] : filtered.sublist(start, end),
      page: page,
      total: filtered.length,
      hasMore: end < filtered.length,
    );
  }

  @override
  Future<Branch> save(Branch branch) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (branch.id.isEmpty) {
      final created = Branch(
        id: 'branch-${_items.length + 1}',
        name: branch.name,
        code: branch.code,
        address: branch.address,
        latitude: branch.latitude,
        longitude: branch.longitude,
        radiusMeters: branch.radiusMeters,
        active: branch.active,
      );
      _items.add(created);
      return created;
    }
    final index = _items.indexWhere((item) => item.id == branch.id);
    if (index < 0) throw StateError('Cabang tidak ditemukan.');
    _items[index] = branch;
    return branch;
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _items.removeWhere((item) => item.id == id);
  }
}
