import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/env.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../auth/provider.dart';
import '../branch/provider.dart';
import 'model.dart';
import 'service.dart';

final employeeServiceProvider = Provider<EmployeeService>((ref) {
  if (Env.useMock) return MockEmployeeService();
  return ApiEmployeeService(ref.watch(dioProvider));
});
final employeeProvider =
    AsyncNotifierProvider<EmployeeController, EmployeeState>(
      EmployeeController.new,
    );
final employeeDetailProvider = FutureProvider.family<Employee, String>(
  (ref, id) => ref.watch(employeeServiceProvider).detail(id),
);
final employeeRolesProvider = FutureProvider<List<RoleOption>>(
  (ref) => ref.watch(employeeServiceProvider).roles(),
);

class EmployeeController extends AsyncNotifier<EmployeeState> {
  static const _limit = 10;
  @override
  Future<EmployeeState> build() async {
    final results = await Future.wait([
      ref.read(employeeServiceProvider).list(limit: _limit),
      ref.read(employeeServiceProvider).departments(),
    ]);
    final page = results[0] as EmployeePage;
    return EmployeeState(
      items: page.items,
      departments: results[1] as List<Department>,
      page: page.page,
      total: page.total,
      hasMore: page.hasMore,
    );
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    final page = await ref
        .read(employeeServiceProvider)
        .list(
          limit: _limit,
          query: current.query,
          department: _departmentId(current.departmentFilter),
          status: current.statusFilter,
        );
    state = AsyncData(
      current.copyWith(
        items: page.items,
        page: 1,
        total: page.total,
        hasMore: page.hasMore,
        clearMessage: true,
      ),
    );
  }

  Future<void> search(String query) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(query: query));
    await refresh();
  }

  Future<void> filter({String? department, String? status}) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(departmentFilter: department, statusFilter: status),
    );
    await refresh();
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final page = await ref
        .read(employeeServiceProvider)
        .list(
          page: current.page + 1,
          limit: _limit,
          query: current.query,
          department: _departmentId(current.departmentFilter),
          status: current.statusFilter,
        );
    state = AsyncData(
      current.copyWith(
        items: [...current.items, ...page.items],
        page: page.page,
        total: page.total,
        hasMore: page.hasMore,
      ),
    );
  }

  Future<Employee?> save(Employee employee) async {
    final current = state.value;
    if (current == null) return null;
    if (employee.name.trim().isEmpty ||
        employee.nik.trim().isEmpty ||
        !employee.email.contains('@')) {
      state = AsyncData(
        current.copyWith(message: 'Nama, NIK, dan email valid wajib diisi.'),
      );
      return null;
    }
    try {
      final saved = await ref
          .read(employeeServiceProvider)
          .save(await _withRelationIds(employee));
      await refresh();
      state = AsyncData(
        state.requireValue.copyWith(message: 'Data karyawan disimpan.'),
      );
      return saved;
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          message: networkErrorMessage(
            error,
            fallback: 'Data karyawan gagal disimpan.',
          ),
        ),
      );
      return null;
    }
  }

  Future<Employee?> create(EmployeeCreateRequest request) async {
    final current = state.value;
    if (current == null) return null;
    final employee = request.employee;
    final emailError = Validators.email(employee.email);
    final passwordError = Validators.employeePassword(request.password);
    if (employee.name.trim().isEmpty || employee.nik.trim().isEmpty) {
      state = AsyncData(current.copyWith(message: 'Nama dan NIK wajib diisi.'));
      return null;
    }
    if (emailError != null || passwordError != null) {
      state = AsyncData(current.copyWith(message: emailError ?? passwordError));
      return null;
    }
    try {
      final payload = EmployeeCreateRequest(
        employee: await _withRelationIds(request.employee),
        password: request.password,
        mustChangePassword: request.mustChangePassword,
      );
      final saved = await ref.read(employeeServiceProvider).create(payload);
      await refresh();
      return saved;
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          message: networkErrorMessage(
            error,
            fallback: 'Akun karyawan gagal dibuat.',
          ),
        ),
      );
      return null;
    }
  }

  Future<bool> resetPassword(String id, EmployeePasswordReset request) async {
    final current = state.value;
    if (current == null) return false;
    final error = Validators.employeePassword(request.password);
    if (error != null) {
      state = AsyncData(current.copyWith(message: error));
      return false;
    }
    try {
      await ref.read(employeeServiceProvider).resetPassword(id, request);
      state = AsyncData(
        current.copyWith(message: 'Password karyawan berhasil direset.'),
      );
      return true;
    } catch (caught) {
      state = AsyncData(
        current.copyWith(
          message: networkErrorMessage(
            caught,
            fallback: 'Password karyawan gagal direset.',
          ),
        ),
      );
      return false;
    }
  }

  Future<void> delete(String id) async {
    await ref.read(employeeServiceProvider).delete(id);
    ref.invalidate(employeeDetailProvider(id));
    await refresh();
  }

  Future<void> addDepartment(String name) async {
    final current = state.value;
    if (current == null || name.trim().isEmpty) return;
    final item = await ref
        .read(employeeServiceProvider)
        .saveDepartment(name.trim());
    state = AsyncData(
      current.copyWith(
        departments: [...current.departments, item],
        message: 'Departemen ditambahkan.',
      ),
    );
  }

  Future<void> export(String type, {bool share = false}) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isExporting: true, clearMessage: true));
    try {
      final bytes = await ref.read(employeeServiceProvider).export(type);
      final directory = await getTemporaryDirectory();
      final extension = type == 'pdf' ? 'pdf' : 'csv';
      final file = File(
        '${directory.path}${Platform.pathSeparator}data_karyawan.$extension',
      );
      await file.writeAsBytes(bytes, flush: true);
      if (share) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Data Karyawan JAHRIS'),
        );
      } else {
        await OpenFilex.open(file.path);
      }
      state = AsyncData(
        current.copyWith(
          isExporting: false,
          message: 'File karyawan berhasil dibuat.',
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isExporting: false,
          message: networkErrorMessage(
            error,
            fallback: 'File karyawan gagal dibuat.',
          ),
        ),
      );
    }
  }

  Future<void> importFile(String path) async {
    final current = state.value;
    if (current == null) return;
    try {
      await ref.read(employeeServiceProvider).importFile(path);
      await refresh();
      state = AsyncData(
        state.requireValue.copyWith(message: 'Import karyawan selesai.'),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          message: networkErrorMessage(
            error,
            fallback: 'Import karyawan gagal.',
          ),
        ),
      );
    }
  }

  Future<Employee> _withRelationIds(Employee employee) async {
    final departments = state.value?.departments ?? const <Department>[];
    final branches = await ref.read(branchOptionsProvider.future);
    final roles = await ref.read(employeeRolesProvider.future);
    String findId<T>(
      Iterable<T> values,
      bool Function(T) matches,
      String Function(T) id,
    ) {
      for (final value in values) {
        if (matches(value)) return id(value);
      }
      return '';
    }

    return Employee(
      id: employee.id,
      name: employee.name,
      nik: employee.nik,
      email: employee.email,
      department: employee.department,
      branch: employee.branch,
      position: employee.position,
      status: employee.status,
      role: employee.role,
      departmentId: employee.departmentId.isNotEmpty
          ? employee.departmentId
          : findId(
              departments,
              (item) => item.name == employee.department,
              (item) => item.id,
            ),
      branchId: employee.branchId.isNotEmpty
          ? employee.branchId
          : findId(
              branches,
              (item) => item.name == employee.branch,
              (item) => item.id,
            ),
      roleId: employee.roleId.isNotEmpty
          ? employee.roleId
          : findId(
              roles,
              (item) => item.name == employee.role,
              (item) => item.id,
            ),
      tenantId: employee.tenantId.isNotEmpty
          ? employee.tenantId
          : ref.read(authProvider).user?.tenantId ?? '',
    );
  }

  String _departmentId(String filter) {
    if (filter == 'Semua') return filter;
    for (final item in state.value?.departments ?? const <Department>[]) {
      if (item.name == filter) return item.id;
    }
    return filter;
  }
}
