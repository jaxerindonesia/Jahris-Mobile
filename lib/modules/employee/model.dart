class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.nik,
    required this.email,
    required this.department,
    required this.branch,
    required this.position,
    required this.status,
    this.role = 'Karyawan',
    this.departmentId = '',
    this.branchId = '',
    this.roleId = '',
    this.tenantId = '',
  });
  final String id;
  final String name;
  final String nik;
  final String email;
  final String department;
  final String branch;
  final String position;
  final String status;
  final String role;
  final String departmentId;
  final String branchId;
  final String roleId;
  final String tenantId;

  // Terverifikasi dari GET /users pada 21 Oktober 2026.
  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id']?.toString() ?? '',
    name: _text(json['name'] ?? json['full_name'], fallback: '-'),
    nik: _text(json['nik'] ?? json['employee_number'], fallback: '-'),
    email: _text(json['email']),
    department: _relationName(json['department']),
    branch: _relationName(json['branch']),
    position: _text(json['position'] ?? json['job_title'], fallback: '-'),
    status: _employeeStatus(json['status']),
    role: _relationName(json['role'], fallback: 'Karyawan'),
    departmentId: _text(json['departmentId']),
    branchId: _text(json['branchId']),
    roleId: _text(json['roleId']),
    tenantId: _text(json['tenantId']),
  );
  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'name': name,
    'nik': nik,
    'email': email,
    if (departmentId.isNotEmpty) 'departmentId': departmentId,
    if (branchId.isNotEmpty) 'branchId': branchId,
    if (roleId.isNotEmpty) 'roleId': roleId,
    if (tenantId.isNotEmpty) 'tenantId': tenantId,
    'position': position,
    'status': status.toLowerCase() == 'aktif' ? 'active' : status.toLowerCase(),
  };
}

class EmployeeCreateRequest {
  const EmployeeCreateRequest({
    required this.employee,
    required this.password,
    required this.mustChangePassword,
  });

  final Employee employee;
  final String password;
  final bool mustChangePassword;

  Map<String, dynamic> toJson() => {
    ...employee.toJson(),
    'email': employee.email,
    'password': password,
    'mustChangePassword': mustChangePassword,
  };
}

class EmployeePasswordReset {
  const EmployeePasswordReset({
    required this.password,
    required this.mustChangePassword,
  });

  final String password;
  final bool mustChangePassword;

  Map<String, dynamic> toJson() => {
    'password': password,
    'mustChangePassword': mustChangePassword,
  };
}

enum EmployeePasswordStrength {
  lemah,
  sedang,
  kuat;

  factory EmployeePasswordStrength.evaluate(String password) {
    if (password.length >= 12 &&
        RegExp('[A-Z]').hasMatch(password) &&
        RegExp('[a-z]').hasMatch(password) &&
        RegExp('[0-9]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return EmployeePasswordStrength.kuat;
    }
    if (password.length >= 8 &&
        RegExp('[A-Za-z]').hasMatch(password) &&
        RegExp('[0-9]').hasMatch(password)) {
      return EmployeePasswordStrength.sedang;
    }
    return EmployeePasswordStrength.lemah;
  }

  String get label => switch (this) {
    EmployeePasswordStrength.lemah => 'Lemah',
    EmployeePasswordStrength.sedang => 'Sedang',
    EmployeePasswordStrength.kuat => 'Kuat',
  };

  double get progress => switch (this) {
    EmployeePasswordStrength.lemah => 0.33,
    EmployeePasswordStrength.sedang => 0.66,
    EmployeePasswordStrength.kuat => 1,
  };
}

class Department {
  const Department({
    required this.id,
    required this.name,
    required this.employeeCount,
  });
  final String id;
  final String name;
  final int employeeCount;
  // TODO-API: verifikasi nama field jumlah karyawan dari /departments.
  factory Department.fromJson(Map<String, dynamic> json) => Department(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '-',
    employeeCount: (json['employeeCount'] as num?)?.toInt() ?? 0,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'employeeCount': employeeCount,
  };
}

class RoleOption {
  const RoleOption({required this.id, required this.name});

  final String id;
  final String name;

  // TODO-API: verifikasi field label role dari /roles.
  factory RoleOption.fromJson(Map<String, dynamic> json) => RoleOption(
    id: json['id']?.toString() ?? '',
    name: _text(json['name'] ?? json['label'], fallback: '-'),
  );
}

String _text(dynamic value, {String fallback = ''}) {
  if (value is String && value.isNotEmpty) return value;
  if (value is num) return value.toString();
  return fallback;
}

String _relationName(dynamic value, {String fallback = '-'}) {
  if (value is String && value.isNotEmpty) return value;
  if (value is Map<String, dynamic>) {
    return _text(value['name'] ?? value['label'], fallback: fallback);
  }
  return fallback;
}

String _employeeStatus(dynamic value) =>
    switch (value?.toString().toLowerCase()) {
      'active' => 'Aktif',
      'inactive' => 'Tidak Aktif',
      _ => _text(value, fallback: 'Aktif'),
    };

class EmployeePage {
  const EmployeePage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });
  final List<Employee> items;
  final int page;
  final int total;
  final bool hasMore;
}

class EmployeeState {
  const EmployeeState({
    required this.items,
    required this.departments,
    required this.page,
    required this.total,
    required this.hasMore,
    this.query = '',
    this.departmentFilter = 'Semua',
    this.statusFilter = 'Semua',
    this.message,
    this.isExporting = false,
  });
  final List<Employee> items;
  final List<Department> departments;
  final int page;
  final int total;
  final bool hasMore;
  final String query;
  final String departmentFilter;
  final String statusFilter;
  final String? message;
  final bool isExporting;

  EmployeeState copyWith({
    List<Employee>? items,
    List<Department>? departments,
    int? page,
    int? total,
    bool? hasMore,
    String? query,
    String? departmentFilter,
    String? statusFilter,
    String? message,
    bool clearMessage = false,
    bool? isExporting,
  }) => EmployeeState(
    items: items ?? this.items,
    departments: departments ?? this.departments,
    page: page ?? this.page,
    total: total ?? this.total,
    hasMore: hasMore ?? this.hasMore,
    query: query ?? this.query,
    departmentFilter: departmentFilter ?? this.departmentFilter,
    statusFilter: statusFilter ?? this.statusFilter,
    message: clearMessage ? null : message ?? this.message,
    isExporting: isExporting ?? this.isExporting,
  );
}
