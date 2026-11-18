class TenantOption {
  const TenantOption({
    required this.id,
    required this.name,
    required this.code,
  });
  final String id;
  final String name;
  final String code;
  factory TenantOption.fromJson(Map<String, dynamic> json) => TenantOption(
    id: json['id']?.toString() ?? '',
    name: (json['companyName'] ?? json['name']) as String? ?? '-',
    code: json['code'] as String? ?? '-',
  );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.position,
    required this.tenant,
    required this.tenants,
    this.nik = '-',
    this.department = '-',
    this.branch = '-',
    this.gender = '-',
    this.birthPlace = '-',
    this.salary,
    this.bankName = '',
    this.bankAccountNumber = '',
    this.bankAccountName = '',
  });
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String position;
  final TenantOption tenant;
  final List<TenantOption> tenants;
  final String nik;
  final String department;
  final String branch;
  final String gender;
  final String birthPlace;
  final num? salary;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;

  bool get hasBankAccount =>
      bankName.isNotEmpty && bankAccountNumber.isNotEmpty;

  /// Contoh: "BCA •••• 4821".
  String get maskedBankAccount {
    if (!hasBankAccount) return '';
    final digits = bankAccountNumber.replaceAll(RegExp(r's'), '');
    final tail = digits.length <= 4
        ? digits
        : digits.substring(digits.length - 4);
    return '$bankName •••• $tail';
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.isEmpty
        ? '?'
        : parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final roleValue = json['role'];
    final tenant =
        json['tenant'] as Map<String, dynamic>? ??
        {
          'id': 'tenant-jgi',
          'companyName': json['tenantName'] ?? 'Jaxer Grup Indonesia',
          'code': 'JGI',
        };
    final rawTenants = json['tenants'] as List<dynamic>? ?? [tenant];
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: _firstText(json, const ['name', 'fullName', 'full_name']),
      email: _firstText(json, const ['email'], fallback: ''),
      phone: _firstText(json, const [
        'phone',
        'phoneNumber',
        'phone_number',
        'telephone',
        'mobile',
        'noTelepon',
        'no_telepon',
      ]),
      role: roleValue is Map<String, dynamic>
          ? roleValue['name'] as String? ?? 'Karyawan'
          : roleValue as String? ?? json['roleName'] as String? ?? 'Karyawan',
      position: _firstText(json, const ['position', 'jobTitle', 'job_title']),
      tenant: TenantOption.fromJson(tenant),
      tenants: rawTenants
          .whereType<Map<String, dynamic>>()
          .map(TenantOption.fromJson)
          .toList(),
      nik: _firstText(json, const ['nik', 'employeeNumber', 'employee_number']),
      department: _relationName(json, 'department'),
      branch: _relationName(json, 'branch'),
      gender: _firstText(json, const [
        'gender',
        'jenisKelamin',
        'jenis_kelamin',
      ]),
      birthPlace: _firstText(json, const [
        'birthPlace',
        'birth_place',
        'placeOfBirth',
        'tempatLahir',
        'tempat_lahir',
      ]),
      salary: _firstNumber(json, const [
        'salary',
        'baseSalary',
        'base_salary',
        'monthlySalary',
      ]),
      bankName: _firstText(json, const [
        'bankName',
        'bank_name',
        'bank',
      ], fallback: ''),
      bankAccountNumber: _firstText(json, const [
        'bankAccountNumber',
        'bank_account_number',
        'accountNumber',
        'noRekening',
      ], fallback: ''),
      bankAccountName: _firstText(json, const [
        'bankAccountName',
        'bank_account_name',
        'accountHolder',
      ], fallback: ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'position': position,
    'tenantId': tenant.id,
    if (bankName.isNotEmpty) 'bankName': bankName,
    if (bankAccountNumber.isNotEmpty) 'bankAccountNumber': bankAccountNumber,
    if (bankAccountName.isNotEmpty) 'bankAccountName': bankAccountName,
  };
  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    TenantOption? tenant,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
  }) => UserProfile(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    role: role,
    position: position,
    tenant: tenant ?? this.tenant,
    tenants: tenants,
    nik: nik,
    department: department,
    branch: branch,
    gender: gender,
    birthPlace: birthPlace,
    salary: salary,
    bankName: bankName ?? this.bankName,
    bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
    bankAccountName: bankAccountName ?? this.bankAccountName,
  );
}

List<Map<String, dynamic>> _profileContexts(Map<String, dynamic> json) {
  final contexts = <Map<String, dynamic>>[json];
  for (final key in const ['employee', 'profile', 'user']) {
    final nested = json[key];
    if (nested is Map<String, dynamic>) contexts.add(nested);
  }
  return contexts;
}

String _firstText(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '-',
}) {
  for (final context in _profileContexts(json)) {
    for (final key in keys) {
      final value = context[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return value.toString();
    }
  }
  return fallback;
}

String _relationName(Map<String, dynamic> json, String key) {
  for (final context in _profileContexts(json)) {
    final value = context[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is Map<String, dynamic>) {
      final name = _firstText(value, const ['name', 'label'], fallback: '');
      if (name.isNotEmpty) return name;
    }
  }
  return '-';
}

num? _firstNumber(Map<String, dynamic> json, List<String> keys) {
  for (final context in _profileContexts(json)) {
    for (final key in keys) {
      final value = context[key];
      if (value is num) return value;
      if (value is String) {
        final parsed = num.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), ''));
        if (parsed != null) return parsed;
      }
    }
  }
  return null;
}

class ProfileStatistics {
  const ProfileStatistics({
    required this.remainingLeave,
    required this.workDays,
    required this.overtime,
  });
  final String remainingLeave;
  final String workDays;
  final String overtime;
}

class ProfileState {
  const ProfileState({
    required this.profile,
    this.message,
    this.isSaving = false,
  });
  final UserProfile profile;
  final String? message;
  final bool isSaving;
  ProfileState copyWith({
    UserProfile? profile,
    String? message,
    bool clearMessage = false,
    bool? isSaving,
  }) => ProfileState(
    profile: profile ?? this.profile,
    message: clearMessage ? null : message ?? this.message,
    isSaving: isSaving ?? this.isSaving,
  );
}

enum PasswordStrength {
  empty,
  weak,
  medium,
  strong;

  /// Skor sederhana: panjang + variasi karakter.
  static PasswordStrength of(String value) {
    if (value.isEmpty) return empty;
    var score = 0;
    if (value.length >= 6) score++;
    if (value.length >= 10) score++;
    if (RegExp('[A-Z]').hasMatch(value) && RegExp('[a-z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    if (value.length < 6 || score <= 2) return weak;
    if (score == 3) return medium;
    return strong;
  }
}
