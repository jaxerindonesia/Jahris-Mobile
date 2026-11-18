import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/mock_account_store.dart';
import 'model.dart';

abstract interface class AuthService {
  Future<AuthSession> login({
    required String email,
    required String password,
    bool rememberMe = false,
  });
  Future<AuthUser> me();
  Future<void> forgotPassword(String email);
  Future<void> logout(String? refreshToken);
  Future<void> changeRequiredPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  });
}

class ApiAuthService implements AuthService {
  const ApiAuthService(this._dio, this._storage);

  final Dio _dio;
  final SecureStorage _storage;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authLogin,
        data: {'email': email, 'password': password, 'remember_me': rememberMe},
      );
    } on DioException catch (error) {
      if (error.response?.statusCode != 404 &&
          error.response?.statusCode != 405) {
        rethrow;
      }
      await _loginWithNextAuth(email: email, password: password);
    }
    final user = await me();
    return AuthSession(
      user: user,
      tokens: const AuthTokens(accessToken: '', refreshToken: ''),
    );
  }

  @override
  Future<AuthUser> me() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.authSession,
    );
    final user = _sessionUser(response.data);
    if (user == null) throw StateError('Sesi pengguna kosong.');
    final sessionUser = AuthUser.fromJson(user);
    try {
      final detailResponse = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.user(sessionUser.id),
      );
      return AuthUser.fromJson({...user, ..._data(detailResponse.data)});
    } on DioException {
      return sessionUser;
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _dio.post<void>(
      ApiEndpoints.authForgotPassword,
      data: {'email': email},
    );
  }

  @override
  Future<void> logout(String? refreshToken) async {
    try {
      await _dio.post<void>(ApiEndpoints.authLogout);
    } on DioException catch (error) {
      if (error.response?.statusCode != 404 &&
          error.response?.statusCode != 405) {
        rethrow;
      }
      final csrfToken = await _csrfToken();
      await _dio.post<void>(
        ApiEndpoints.authSignOut,
        data: {
          'csrfToken': csrfToken,
          'callbackUrl': _webUrl('/login'),
          'json': 'true',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
    } finally {
      await _storage.clearSession();
    }
  }

  @override
  Future<void> changeRequiredPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      ApiEndpoints.authChangePassword,
      data: {
        'userId': (await me()).id,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> _loginWithNextAuth({
    required String email,
    required String password,
  }) async {
    final csrfToken = await _csrfToken();
    final response = await _dio.post<dynamic>(
      ApiEndpoints.authCredentials,
      data: {
        'csrfToken': csrfToken,
        'email': email,
        'password': password,
        'callbackUrl': _webUrl('/dashboard'),
        'json': 'true',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    final body = response.data;
    if (body is Map<String, dynamic> && body['error'] != null) {
      throw StateError('Email atau password salah.');
    }
  }

  String _webUrl(String path) {
    final apiUri = Uri.parse(_dio.options.baseUrl);
    return apiUri.replace(path: path, query: null, fragment: null).toString();
  }

  Future<String> _csrfToken() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.authCsrf,
    );
    final token = response.data?['csrfToken'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('csrfToken tidak tersedia.');
    }
    return token;
  }

  Map<String, dynamic>? _sessionUser(Map<String, dynamic>? envelope) {
    if (envelope == null || envelope.isEmpty) return null;
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      final nestedUser = data['user'];
      if (nestedUser is Map<String, dynamic>) return nestedUser;
      return data;
    }
    final user = envelope['user'];
    return user is Map<String, dynamic> ? user : null;
  }

  Map<String, dynamic> _data(Map<String, dynamic>? envelope) {
    final body = envelope ?? const <String, dynamic>{};
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final user = data['user'];
      return user is Map<String, dynamic> ? user : data;
    }
    final user = body['user'];
    return user is Map<String, dynamic> ? user : body;
  }
}

class MockAuthService implements AuthService {
  const MockAuthService();

  static AuthUser? _currentUser;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final registered = MockAccountStore.authenticate(email, password);
    if (registered != null) {
      final user = AuthUser(
        id: registered.id,
        name: registered.name,
        email: registered.email,
        role: registered.role,
        tenantName: 'Jaxer Grup Indonesia',
        branchName: registered.branchName,
        mustChangePassword: registered.mustChangePassword,
      );
      _currentUser = user;
      return AuthSession(
        user: user,
        tokens: const AuthTokens(
          accessToken: 'mock-access-token',
          refreshToken: 'mock-refresh-token',
        ),
      );
    }
    if (MockAccountStore.contains(email)) {
      throw StateError('Email atau password salah.');
    }
    final isEmployee =
        email.toLowerCase().contains('employee') ||
        email.toLowerCase().contains('karyawan');
    final user = AuthUser(
      id: isEmployee ? 'mock-employee-1' : 'mock-admin-1',
      name: isEmployee ? 'Nadia Putri' : 'Admin JGI',
      email: email,
      role: isEmployee ? 'Karyawan' : 'Admin Tenant',
      tenantName: 'Jaxer Grup Indonesia',
    );
    _currentUser = user;
    return AuthSession(
      user: user,
      tokens: const AuthTokens(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
      ),
    );
  }

  @override
  Future<AuthUser> me() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _currentUser ??
        const AuthUser(
          id: 'mock-admin-1',
          name: 'Admin JGI',
          email: 'admin@jahris.id',
          role: 'Admin Tenant',
          tenantName: 'Jaxer Grup Indonesia',
        );
  }

  @override
  Future<void> forgotPassword(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> logout(String? refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _currentUser = null;
  }

  @override
  Future<void> changeRequiredPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (MockAccountStore.authenticate(email, currentPassword) == null) {
      throw StateError('Password saat ini tidak sesuai.');
    }
    MockAccountStore.completePasswordChange(email, newPassword);
    _currentUser = _currentUser?.copyWith(mustChangePassword: false);
  }
}
