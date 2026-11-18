import 'dart:typed_data';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../core/utils/mock_account_store.dart';
import 'model.dart';

abstract interface class EmployeeService {
  Future<EmployeePage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? department,
    String? status,
  });
  Future<Employee> detail(String id);
  Future<Employee> create(EmployeeCreateRequest request);
  Future<Employee> save(Employee employee);
  Future<void> resetPassword(String id, EmployeePasswordReset request);
  Future<void> delete(String id);
  Future<List<Department>> departments();
  Future<List<RoleOption>> roles();
  Future<Department> saveDepartment(String name);
  Future<Uint8List> export(String type);
  Future<void> importFile(String path);
}

class ApiEmployeeService implements EmployeeService {
  const ApiEmployeeService(this._dio);
  final Dio _dio;

  @override
  Future<EmployeePage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? department,
    String? status,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.users,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (query != null && query.isNotEmpty) 'search': query,
        if (department != null && department != 'Semua')
          'departmentId': department,
        if (status != null && status != 'Semua')
          'status': status.toLowerCase() == 'aktif'
              ? 'active'
              : status.toLowerCase().contains('tidak')
              ? 'inactive'
              : status.toLowerCase(),
      },
    );
    final raw = apiList(response.data, collectionKeys: const ['users']);
    final meta = apiPageMeta(
      response.data,
      fallbackPage: page,
      itemCount: raw.length,
      limit: limit,
    );
    return EmployeePage(
      items: raw.map(Employee.fromJson).toList(),
      page: meta.page,
      total: meta.total,
      hasMore: meta.hasMore,
    );
  }

  @override
  Future<Employee> detail(String id) async {
    final response = await _dio.get<dynamic>(ApiEndpoints.user(id));
    return Employee.fromJson(apiObject(response.data));
  }

  @override
  Future<Employee> save(Employee employee) async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiEndpoints.user(employee.id),
      data: employee.toJson(),
    );
    return Employee.fromJson(apiObject(response.data));
  }

  @override
  Future<Employee> create(EmployeeCreateRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.users,
      data: request.toJson(),
    );
    return Employee.fromJson(apiObject(response.data));
  }

  @override
  Future<void> resetPassword(String id, EmployeePasswordReset request) =>
      _dio.put<void>(ApiEndpoints.user(id), data: request.toJson());

  @override
  Future<void> delete(String id) => _dio.delete<void>(ApiEndpoints.user(id));

  @override
  Future<List<Department>> departments() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.departments);
    return apiList(
      response.data,
      collectionKeys: const ['departments'],
    ).map(Department.fromJson).toList();
  }

  @override
  Future<List<RoleOption>> roles() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.roles);
    return apiList(
      response.data,
      collectionKeys: const ['roles'],
    ).map(RoleOption.fromJson).toList();
  }

  @override
  Future<Department> saveDepartment(String name) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.departments,
      data: {'name': name},
    );
    return Department.fromJson(apiObject(response.data));
  }

  @override
  Future<Uint8List> export(String type) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.users,
      queryParameters: {'limit': 999999},
    );
    final rows = apiList(response.data, collectionKeys: const ['users']);
    final csv = <String>['NIK,Nama,Email,Role,Posisi,Departemen,Cabang,Status'];
    for (final row in rows) {
      final employee = Employee.fromJson(row);
      csv.add(
        [
          employee.nik,
          employee.name,
          employee.email,
          employee.role,
          employee.position,
          employee.department,
          employee.branch,
          employee.status,
        ].map(_csvCell).join(','),
      );
    }
    return Uint8List.fromList(csv.join('\r\n').codeUnits);
  }

  @override
  Future<void> importFile(String path) async {
    throw UnsupportedError(
      'Import API membutuhkan JSON {rows}; file spreadsheet harus diparsing di aplikasi terlebih dahulu.',
    );
  }

  String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';
}

class MockEmployeeService implements EmployeeService {
  MockEmployeeService();

  final List<Employee> _items = List.generate(
    30,
    (index) => Employee(
      id: 'employee-${index + 1}',
      name: [
        'Nadia Putri',
        'Rizky Pratama',
        'Siti Rahma',
        'Dimas Saputra',
        'Maya Sari',
      ][index % 5],
      nik: 'JGI-${(index + 1).toString().padLeft(4, '0')}',
      email: 'karyawan${index + 1}@jahris.id',
      department: ['HR', 'Finance', 'Operasional', 'IT', 'Sales'][index % 5],
      branch: ['Batam', 'Medan', 'Pusat'][index % 3],
      position: ['Staf', 'Supervisor', 'Manajer'][index % 3],
      status: index % 7 == 0 ? 'Tidak Aktif' : 'Aktif',
    ),
  );
  final List<Department> _departments = const [
    Department(id: 'dept-1', name: 'HR', employeeCount: 5),
    Department(id: 'dept-2', name: 'Finance', employeeCount: 6),
    Department(id: 'dept-3', name: 'Operasional', employeeCount: 8),
    Department(id: 'dept-4', name: 'IT', employeeCount: 5),
    Department(id: 'dept-5', name: 'Sales', employeeCount: 6),
  ];

  @override
  Future<EmployeePage> list({
    int page = 1,
    int limit = 10,
    String? query,
    String? department,
    String? status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final filtered = _items.where((item) {
      final matchesQuery =
          query == null ||
          query.isEmpty ||
          item.name.toLowerCase().contains(query.toLowerCase()) ||
          item.nik.toLowerCase().contains(query.toLowerCase());
      final matchesDepartment =
          department == null ||
          department == 'Semua' ||
          item.department == department;
      final matchesStatus =
          status == null || status == 'Semua' || item.status == status;
      return matchesQuery && matchesDepartment && matchesStatus;
    }).toList();
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, filtered.length);
    return EmployeePage(
      items: start >= filtered.length ? [] : filtered.sublist(start, end),
      page: page,
      total: filtered.length,
      hasMore: end < filtered.length,
    );
  }

  @override
  Future<Employee> detail(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _items.firstWhere((item) => item.id == id);
  }

  @override
  Future<Employee> save(Employee employee) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final index = _items.indexWhere((item) => item.id == employee.id);
    if (index < 0) throw StateError('Karyawan tidak ditemukan.');
    _items[index] = employee;
    MockAccountStore.updateEmployee(
      id: employee.id,
      name: employee.name,
      email: employee.email,
      role: employee.role,
      branchName: employee.branch,
    );
    return employee;
  }

  @override
  Future<Employee> create(EmployeeCreateRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final source = request.employee;
    final created = Employee(
      id: 'employee-${DateTime.now().microsecondsSinceEpoch}',
      name: source.name,
      nik: source.nik,
      email: source.email,
      department: source.department,
      branch: source.branch,
      position: source.position,
      status: source.status,
      role: source.role,
    );
    _items.insert(0, created);
    MockAccountStore.register(
      id: created.id,
      name: created.name,
      email: created.email,
      role: created.role,
      branchName: created.branch,
      password: request.password,
      mustChangePassword: request.mustChangePassword,
    );
    return created;
  }

  @override
  Future<void> resetPassword(String id, EmployeePasswordReset request) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final employee = _items.firstWhere((item) => item.id == id);
    MockAccountStore.resetPassword(
      email: employee.email,
      password: request.password,
      mustChangePassword: request.mustChangePassword,
    );
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final email = _items
        .where((item) => item.id == id)
        .map((item) => item.email)
        .firstOrNull;
    _items.removeWhere((item) => item.id == id);
    if (email != null) MockAccountStore.remove(email);
  }

  @override
  Future<List<Department>> departments() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List.unmodifiable(_departments);
  }

  @override
  Future<List<RoleOption>> roles() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return const [
      RoleOption(id: 'employee', name: 'Karyawan'),
      RoleOption(id: 'supervisor', name: 'Atasan'),
      RoleOption(id: 'manager', name: 'Manajer'),
      RoleOption(id: 'admin', name: 'Admin'),
    ];
  }

  @override
  Future<Department> saveDepartment(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final item = Department(
      id: 'dept-${_departments.length + 1}',
      name: name,
      employeeCount: 0,
    );
    _departments.add(item);
    return item;
  }

  @override
  Future<Uint8List> export(String type) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final content = type == 'pdf'
        ? '%PDF-1.4\n% JAHRIS mock employees\n%%EOF'
        : [
            'NIK,Nama,Email,Departemen,Cabang,Status',
            ..._items.map(
              (item) =>
                  '${item.nik},${item.name},${item.email},${item.department},${item.branch},${item.status}',
            ),
          ].join('\n');
    return Uint8List.fromList(utf8.encode(content));
  }

  @override
  Future<void> importFile(String path) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}
