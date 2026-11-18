import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jahris_mobile/core/storage/secure_storage.dart';
import 'package:jahris_mobile/modules/auth/provider.dart';
import 'package:jahris_mobile/modules/auth/service.dart';
import 'package:jahris_mobile/modules/face/model.dart';
import 'package:jahris_mobile/modules/face/provider.dart';
import 'package:jahris_mobile/modules/face/service.dart';

class _FaceDetailForbiddenService extends MockFaceService {
  @override
  Future<FaceStatus> status(String employeeId) {
    throw DioException(
      requestOptions: RequestOptions(path: '/users/$employeeId'),
      response: Response<void>(
        requestOptions: RequestOptions(path: '/users/$employeeId'),
        statusCode: 403,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'auth membaca cabang dari envelope data.user pada detail akun',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = SecureStorage(FlutterSecureStorage());
      final dio = Dio(BaseOptions(baseUrl: 'https://dev.jahris.id/api'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final data = options.path == '/auth/session'
                ? const <String, dynamic>{
                    'data': {
                      'user': {
                        'id': 'surya-id',
                        'name': 'Surya',
                        'email': 'surya@jahris.id',
                        'role': 'Karyawan',
                      },
                    },
                  }
                : const <String, dynamic>{
                    'data': {
                      'user': {
                        'id': 'surya-id',
                        'branchId': 'branch-jakpus',
                        'branch': {
                          'id': 'branch-jakpus',
                          'name': 'Jakpus',
                          'latitude': '-6.1754',
                          'longitude': 106.8272,
                          'attendanceRadiusMeters': 100,
                        },
                      },
                    },
                  };
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: data,
              ),
            );
          },
        ),
      );

      final user = await ApiAuthService(dio, storage).me();

      expect(user.name, 'Surya');
      expect(user.branchId, 'branch-jakpus');
      expect(user.branchName, 'Jakpus');
      expect(user.branchLatitude, -6.1754);
      expect(user.branchLongitude, 106.8272);
    },
  );

  test(
    'gagal membaca detail wajah tidak boleh dianggap belum terdaftar',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = SecureStorage(FlutterSecureStorage());
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(const MockAuthService()),
          faceServiceProvider.overrideWithValue(_FaceDetailForbiddenService()),
        ],
      );
      addTearDown(container.dispose);

      container.read(authProvider);
      await Future<void>.delayed(Duration.zero);
      final form = container.read(loginFormProvider.notifier);
      form.setEmail('karyawan.regresi@jahris.id');
      form.setPassword('Password123');
      await container.read(authProvider.notifier).login();

      expect(container.read(authProvider).requiresFaceEnrollment, isFalse);
    },
  );
}
