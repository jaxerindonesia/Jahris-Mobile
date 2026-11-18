enum AuthStatus { checking, authenticated, unauthenticated }

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.tenantName,
    this.tenantId = '',
    this.departmentId = '',
    this.branchId = '',
    this.avatarUrl,
    this.branchName = '',
    this.branchLatitude,
    this.branchLongitude,
    this.attendanceRadiusMeters,
    this.mustChangePassword = false,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String tenantName;
  final String tenantId;
  final String departmentId;
  final String branchId;
  final String? avatarUrl;
  final String branchName;
  final double? branchLatitude;
  final double? branchLongitude;
  final double? attendanceRadiusMeters;
  final bool mustChangePassword;

  // Terverifikasi dari GET /auth/session pada 21 Oktober 2026.
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: _firstString(json, const ['id', 'userId', 'user_id', 'employeeId']),
    name: _firstString(json, const [
      'name',
      'fullName',
      'full_name',
      'displayName',
    ], fallback: 'Pengguna JAHRIS'),
    email: _firstString(json, const ['email']),
    role: _readRole(json),
    tenantName: _readTenantName(json),
    tenantId: _readTenantId(json),
    departmentId: _firstString(json, const ['departmentId']),
    branchId: _readBranchId(json),
    avatarUrl: _firstNullableString(json, const [
      'avatarUrl',
      'faceImageUrl',
      'photoUrl',
      'profilePicture',
      'image',
    ]),
    branchName: _readBranchName(json),
    branchLatitude: _readBranchNumber(json, const ['latitude', 'lat']),
    branchLongitude: _readBranchNumber(json, const ['longitude', 'lng']),
    attendanceRadiusMeters: _readBranchNumber(json, const [
      'attendanceRadiusMeters',
      'radiusMeters',
    ]),
    mustChangePassword: _firstBool(json, const [
      'mustChangePassword',
      'must_change_password',
    ]),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'tenantName': tenantName,
    'tenantId': tenantId,
    'departmentId': departmentId,
    'branchId': branchId,
    'avatarUrl': avatarUrl,
    'branchName': branchName,
    'branchLatitude': branchLatitude,
    'branchLongitude': branchLongitude,
    'attendanceRadiusMeters': attendanceRadiusMeters,
    'mustChangePassword': mustChangePassword,
  };

  AuthUser copyWith({
    String? name,
    String? email,
    String? role,
    String? tenantName,
    String? tenantId,
    String? departmentId,
    bool? mustChangePassword,
    String? branchName,
    String? branchId,
    String? avatarUrl,
    double? branchLatitude,
    double? branchLongitude,
    double? attendanceRadiusMeters,
  }) => AuthUser(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    tenantName: tenantName ?? this.tenantName,
    tenantId: tenantId ?? this.tenantId,
    departmentId: departmentId ?? this.departmentId,
    branchId: branchId ?? this.branchId,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    branchName: branchName ?? this.branchName,
    branchLatitude: branchLatitude ?? this.branchLatitude,
    branchLongitude: branchLongitude ?? this.branchLongitude,
    attendanceRadiusMeters:
        attendanceRadiusMeters ?? this.attendanceRadiusMeters,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
  );
}

String? _nullableString(dynamic value) =>
    value is String && value.isNotEmpty ? value : null;

String? _firstNullableString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _nullableString(json[key]);
    if (value != null) return value;
  }
  return null;
}

String _readBranchName(Map<String, dynamic> json) {
  for (final source in _identityContexts(json)) {
    final direct = source['branchName'];
    if (direct is String && direct.isNotEmpty) return direct;
    final branch = source['branch'];
    if (branch is String && branch.isNotEmpty) return branch;
    if (branch is Map<String, dynamic>) {
      final name = branch['name'];
      if (name is String && name.isNotEmpty) return name;
    }
  }
  return '';
}

String _readBranchId(Map<String, dynamic> json) {
  for (final source in _identityContexts(json)) {
    final direct = _firstString(source, const ['branchId', 'branch_id']);
    if (direct.isNotEmpty) return direct;
    final branch = source['branch'];
    if (branch is Map<String, dynamic>) {
      final id = _firstString(branch, const ['id']);
      if (id.isNotEmpty) return id;
    }
  }
  return '';
}

String _readTenantId(Map<String, dynamic> json) {
  for (final source in _identityContexts(json)) {
    final direct = _firstString(source, const ['tenantId', 'tenant_id']);
    if (direct.isNotEmpty) return direct;
    final tenant = source['tenant'];
    if (tenant is Map<String, dynamic>) {
      final id = _firstString(tenant, const ['id']);
      if (id.isNotEmpty) return id;
    }
  }
  return '';
}

double? _readBranchNumber(Map<String, dynamic> json, List<String> keys) {
  for (final source in _identityContexts(json)) {
    final branch = source['branch'];
    if (branch is Map<String, dynamic>) {
      for (final key in keys) {
        final parsed = _nullableDouble(branch[key]);
        if (parsed != null) return parsed;
      }
    }
    for (final key in keys) {
      final parsed = _nullableDouble(source['branch${_capitalize(key)}']);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

List<Map<String, dynamic>> _identityContexts(Map<String, dynamic> json) {
  final contexts = <Map<String, dynamic>>[json];
  for (final key in const ['employee', 'profile', 'user']) {
    final value = json[key];
    if (value is Map<String, dynamic>) contexts.add(value);
  }
  return contexts;
}

double? _nullableDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return value is String ? double.tryParse(value) : null;
}

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

String _readRole(Map<String, dynamic> json) {
  final direct = json['role'];
  if (direct is String && direct.isNotEmpty) return direct;
  if (direct is Map<String, dynamic>) {
    return _firstString(direct, const ['name', 'label'], fallback: 'Karyawan');
  }
  return _firstString(json, const [
    'roleName',
    'role_name',
  ], fallback: 'Karyawan');
}

String _readTenantName(Map<String, dynamic> json) {
  final direct = _firstString(json, const ['tenantName', 'tenant_name']);
  if (direct.isNotEmpty) return direct;
  final tenant = json['tenant'];
  if (tenant is Map<String, dynamic>) {
    return _firstString(tenant, const [
      'name',
    ], fallback: 'Jaxer Grup Indonesia');
  }
  return 'Jaxer Grup Indonesia';
}

String _firstString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    if (value is num) return value.toString();
  }
  return fallback;
}

bool _firstBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
  }
  return false;
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String? ?? '',
    refreshToken: json['refreshToken'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}

class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  final AuthUser user;
  final AuthTokens tokens;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? const {},
      ),
      tokens: AuthTokens.fromJson(json),
    );
  }
}

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.requiresFaceEnrollment = false,
    this.requiresPasswordChange = false,
  });

  const AuthState.checking() : this(status: AuthStatus.checking);
  const AuthState.unauthenticated({String? errorMessage})
    : this(status: AuthStatus.unauthenticated, errorMessage: errorMessage);
  AuthState.authenticated(
    AuthUser user, {
    bool requiresFaceEnrollment = false,
    bool? requiresPasswordChange,
  }) : this(
         status: AuthStatus.authenticated,
         user: user,
         requiresFaceEnrollment: requiresFaceEnrollment,
         requiresPasswordChange:
             requiresPasswordChange ?? user.mustChangePassword,
       );

  final AuthStatus status;
  final AuthUser? user;
  final bool isLoading;
  final String? errorMessage;
  final bool requiresFaceEnrollment;
  final bool requiresPasswordChange;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? requiresFaceEnrollment,
    bool? requiresPasswordChange,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      requiresFaceEnrollment:
          requiresFaceEnrollment ?? this.requiresFaceEnrollment,
      requiresPasswordChange:
          requiresPasswordChange ?? this.requiresPasswordChange,
    );
  }
}

class LoginFormState {
  const LoginFormState({
    this.email = '',
    this.password = '',
    this.rememberMe = true,
    this.obscurePassword = true,
  });

  final String email;
  final String password;
  final bool rememberMe;
  final bool obscurePassword;

  LoginFormState copyWith({
    String? email,
    String? password,
    bool? rememberMe,
    bool? obscurePassword,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      rememberMe: rememberMe ?? this.rememberMe,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}
