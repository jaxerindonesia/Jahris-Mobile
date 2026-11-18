import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../auth/model.dart';
import 'model.dart';

abstract interface class ProfileService {
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile(UserProfile profile);
  Future<UserProfile> switchTenant(String tenantId);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class ApiProfileService implements ProfileService {
  const ApiProfileService(this._dio);
  final Dio _dio;

  @override
  Future<UserProfile> getProfile() async {
    final session = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.authSession,
    );
    final sessionData = _userData(session.data);
    final id = sessionData['id']?.toString() ?? '';
    if (id.isEmpty) return UserProfile.fromJson(sessionData);

    var detailData = const <String, dynamic>{};
    try {
      final detail = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.user(id),
      );
      detailData = _userData(detail.data);
      final detailId = detailData['id']?.toString() ?? '';

      // Identitas dari sesi adalah sumber kebenaran. Jangan pernah menampilkan
      // detail milik akun lain bila endpoint detail mengembalikan data stale.
      if (detailId.isNotEmpty && detailId != id) {
        detailData = const <String, dynamic>{};
      }
    } on DioException {
      // Beberapa deployment web tidak menyediakan GET /users/:id atau hanya
      // mengembalikan profil ringkas. Daftar /users tetap menjadi fallback.
    }

    final listData = await _activeUserFromList(sessionData);
    final employeeData = <String, dynamic>{...detailData, ...?listData};
    return UserProfile.fromJson(_mergeProfileData(employeeData, sessionData));
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    await _dio.put<Map<String, dynamic>>(
      ApiEndpoints.user(profile.id),
      data: profile.toJson(),
    );
    // Respons PUT pada beberapa versi API hanya berisi field yang berubah.
    // Muat ulang detail agar profil lokal selalu lengkap dan konsisten.
    return getProfile();
  }

  @override
  Future<UserProfile> switchTenant(String tenantId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authSwitchTenant,
      data: {'tenantId': tenantId},
    );
    return UserProfile.fromJson(_userData(response.data));
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final session = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.authSession,
    );
    final userId = _userData(session.data)['id']?.toString() ?? '';
    await _dio.post<void>(
      ApiEndpoints.authChangePassword,
      data: {
        'userId': userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Map<String, dynamic> _userData(Map<String, dynamic>? envelope) {
    final body = envelope ?? const <String, dynamic>{};
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final user = data['user'];
      return user is Map<String, dynamic> ? user : data;
    }
    final user = body['user'];
    return user is Map<String, dynamic> ? user : body;
  }

  Map<String, dynamic> _mergeProfileData(
    Map<String, dynamic> detail,
    Map<String, dynamic> session,
  ) {
    final merged = Map<String, dynamic>.from(detail);
    // Sesi menjadi sumber kebenaran hanya untuk identitas dan tenant. Field
    // karyawan seperti phone/NIK/cabang tetap berasal dari /users/:id karena
    // endpoint sesi sering mengembalikan nilai null atau profil ringkas.
    for (final key in const [
      'id',
      'name',
      'email',
      'role',
      'roleName',
      'tenant',
      'tenantName',
      'tenants',
    ]) {
      final value = session[key];
      if (value == null || (value is String && value.trim().isEmpty)) continue;
      merged[key] = value;
    }
    return merged;
  }

  Future<Map<String, dynamic>?> _activeUserFromList(
    Map<String, dynamic> session,
  ) async {
    final id = session['id']?.toString() ?? '';
    final email = session['email']?.toString().trim().toLowerCase() ?? '';
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.users,
        queryParameters: {
          'page': 1,
          'limit': 100,
          if (email.isNotEmpty) 'search': email,
        },
      );
      final users = apiList(response.data, collectionKeys: const ['users']);
      for (final user in users) {
        final userId = user['id']?.toString() ?? '';
        final userEmail = user['email']?.toString().trim().toLowerCase() ?? '';
        if ((id.isNotEmpty && userId == id) ||
            (email.isNotEmpty && userEmail == email)) {
          return user;
        }
      }
    } on DioException {
      return null;
    }
    return null;
  }
}

class MockProfileService implements ProfileService {
  MockProfileService(AuthUser? user) : _userId = user?.id ?? 'mock-admin-1' {
    _profiles.putIfAbsent(
      _userId,
      () => UserProfile(
        id: _userId,
        name: user?.name ?? 'Admin JGI',
        email: user?.email ?? 'admin@jahris.id',
        phone: '-',
        role: user?.role ?? 'Admin Tenant',
        position: user?.role == 'Karyawan' ? 'Karyawan' : 'HR Administrator',
        tenant: TenantOption(
          id: 'tenant-jgi',
          name: user?.tenantName ?? 'Jaxer Grup Indonesia',
          code: 'JGI',
        ),
        tenants: [
          TenantOption(
            id: 'tenant-jgi',
            name: user?.tenantName ?? 'Jaxer Grup Indonesia',
            code: 'JGI',
          ),
          const TenantOption(
            id: 'tenant-demo',
            name: 'JAHRIS Demo',
            code: 'DEMO',
          ),
        ],
        bankName: 'BCA',
        bankAccountNumber: '1234564821',
        bankAccountName: user?.name ?? 'Admin JGI',
      ),
    );
  }

  static final Map<String, UserProfile> _profiles = {};
  final String _userId;
  UserProfile get _profile => _profiles[_userId]!;
  set _profile(UserProfile value) => _profiles[_userId] = value;

  @override
  Future<UserProfile> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _profile;
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _profile = profile;
    return _profile;
  }

  @override
  Future<UserProfile> switchTenant(String tenantId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final tenant = _profile.tenants.firstWhere((item) => item.id == tenantId);
    _profile = _profile.copyWith(tenant: tenant);
    return _profile;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (currentPassword.length < 6) throw StateError('Password lama salah.');
  }
}
