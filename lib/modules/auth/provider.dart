import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/validators.dart';
import '../face/model.dart';
import '../face/provider.dart';
import 'model.dart';
import 'service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  if (Env.useMock) return const MockAuthService();
  return ApiAuthService(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

/// `true` setelah splash selesai; dipakai router agar splash selalu tampil
/// sekali di awal, walau aplikasi dibuka langsung di URL lain (web).
final splashDoneProvider = NotifierProvider<SplashDoneNotifier, bool>(
  SplashDoneNotifier.new,
);

class SplashDoneNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markDone() => state = true;
}

final loginFormProvider = NotifierProvider<LoginFormNotifier, LoginFormState>(
  LoginFormNotifier.new,
);

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class LoginFormNotifier extends Notifier<LoginFormState> {
  @override
  LoginFormState build() => const LoginFormState();

  void setEmail(String value) => state = state.copyWith(email: value);
  void setPassword(String value) => state = state.copyWith(password: value);
  void clearPassword() => state = state.copyWith(password: '');
  void setRememberMe(bool value) => state = state.copyWith(rememberMe: value);
  void togglePassword() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.listen<int>(sessionExpiryProvider, (previous, next) {
      if (previous != null && next > previous) {
        state = const AuthState.unauthenticated(
          errorMessage: 'Sesi telah berakhir. Silakan masuk kembali.',
        );
      }
    });
    Future<void>.microtask(restoreSession);
    return const AuthState.checking();
  }

  Future<void> restoreSession() async {
    final storage = ref.read(secureStorageProvider);
    final rememberMe = await storage.readRememberMe();
    final hasCookieSession = await storage.hasCookieSession();
    if (!rememberMe || !hasCookieSession) {
      await storage.clearSession();
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      final user = await ref.read(authServiceProvider).me();
      state = AuthState.authenticated(
        user,
        requiresFaceEnrollment: await _requiresEnrollment(user),
        requiresPasswordChange: user.mustChangePassword,
      );
    } catch (_) {
      await storage.clearSession();
      state = const AuthState.unauthenticated(
        errorMessage: 'Sesi telah berakhir. Silakan masuk kembali.',
      );
    }
  }

  Future<void> login() async {
    final form = ref.read(loginFormProvider);
    final emailError = Validators.email(form.email);
    final passwordError = Validators.password(form.password);
    if (emailError != null || passwordError != null) {
      state = AuthState.unauthenticated(
        errorMessage: emailError ?? passwordError,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await ref
          .read(authServiceProvider)
          .login(
            email: form.email.trim(),
            password: form.password,
            rememberMe: form.rememberMe,
          );
      await ref
          .read(secureStorageProvider)
          .saveCookieSession(rememberMe: form.rememberMe);
      state = AuthState.authenticated(
        session.user,
        requiresFaceEnrollment: await _requiresEnrollment(session.user),
        requiresPasswordChange: session.user.mustChangePassword,
      );
    } on DioException catch (error) {
      state = AuthState.unauthenticated(errorMessage: _dioMessage(error));
    } catch (_) {
      state = const AuthState.unauthenticated(
        errorMessage: 'Tidak dapat masuk. Periksa koneksi dan coba lagi.',
      );
    } finally {
      ref.read(loginFormProvider.notifier).clearPassword();
    }
  }

  Future<bool> forgotPassword() async {
    final email = ref.read(loginFormProvider).email.trim();
    final error = Validators.email(email);
    if (error != null) {
      state = AuthState.unauthenticated(errorMessage: error);
      return false;
    }
    try {
      await ref.read(authServiceProvider).forgotPassword(email);
      return true;
    } catch (_) {
      state = const AuthState.unauthenticated(
        errorMessage: 'Permintaan reset password gagal dikirim.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    try {
      await ref.read(authServiceProvider).logout(null);
    } finally {
      await storage.clearSession();
      state = const AuthState.unauthenticated();
    }
  }

  void replaceUser(AuthUser user) {
    if (state.status == AuthStatus.authenticated) {
      state = AuthState.authenticated(
        user,
        requiresFaceEnrollment: state.requiresFaceEnrollment,
        requiresPasswordChange: state.requiresPasswordChange,
      );
    }
  }

  void resolveFaceEnrollment() {
    if (state.status == AuthStatus.authenticated) {
      state = state.copyWith(requiresFaceEnrollment: false);
    }
  }

  Future<String?> changeRequiredPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    final user = state.user;
    if (user == null) return 'Sesi pengguna tidak tersedia.';
    final passwordError = Validators.employeePassword(newPassword);
    final confirmationError = Validators.passwordConfirmation(
      confirmation,
      newPassword,
    );
    if (passwordError != null || confirmationError != null) {
      return passwordError ?? confirmationError;
    }
    try {
      await ref
          .read(authServiceProvider)
          .changeRequiredPassword(
            email: user.email,
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      final updatedUser = user.copyWith(mustChangePassword: false);
      state = AuthState.authenticated(
        updatedUser,
        requiresFaceEnrollment: state.requiresFaceEnrollment,
        requiresPasswordChange: false,
      );
      return null;
    } catch (_) {
      return 'Password gagal diubah. Periksa password saat ini.';
    }
  }

  Future<bool> _requiresEnrollment(AuthUser user) async {
    if (user.role.toLowerCase().contains('admin')) return false;
    try {
      final status = await ref.read(faceServiceProvider).status(user.id);
      return status.status != FaceEnrollmentStatus.sudah;
    } catch (_) {
      // Akun karyawan dapat tidak memiliki izin membaca GET /users/:id.
      // Status yang tidak dapat dibaca bukan berarti wajah belum terdaftar;
      // keputusan final tetap diberikan /face-recognition/verify.
      return false;
    }
  }

  String _dioMessage(DioException error) {
    if (error.response?.statusCode == 401) {
      return 'Email atau password salah.';
    }
    return dioErrorMessage(error);
  }
}
