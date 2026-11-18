import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jahris_mobile/core/storage/secure_storage.dart';
import 'package:jahris_mobile/modules/face/model.dart';
import 'package:jahris_mobile/modules/face/service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('consent API tersimpan aman tanpa endpoint backend', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = SecureStorage(FlutterSecureStorage());
    final service = ApiFaceService(
      Dio(BaseOptions(baseUrl: 'https://dev.jahris.id/api')),
      storage,
    );

    await service.saveConsent(
      employeeId: 'employee-consent-test',
      accepted: true,
    );

    expect(await storage.readFaceConsent('employee-consent-test'), isTrue);
  });

  test('verify mengirim empat frame berbeda ke API web', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = SecureStorage(FlutterSecureStorage());
    final dio = Dio(BaseOptions(baseUrl: 'https://dev.jahris.id/api'));
    Map<String, dynamic>? sentPayload;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sentPayload = Map<String, dynamic>.from(options.data as Map);
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: const {
                'ok': true,
                'message': 'Wajah cocok.',
                'verificationToken': 'test-token',
              },
            ),
          );
        },
      ),
    );
    final service = ApiFaceService(dio, storage);
    final directory = await Directory.systemTemp.createTemp(
      'jahris-face-test-',
    );
    final files = <File>[];
    try {
      for (var index = 0; index < 4; index++) {
        final file = File(
          '${directory.path}${Platform.pathSeparator}$index.jpg',
        );
        await file.writeAsBytes([index + 1, index + 2, index + 3]);
        files.add(file);
      }

      final result = await service.verify(
        employeeId: 'employee-verify-test',
        photoPaths: files.map((file) => file.path).toList(),
        latitude: 1.0,
        longitude: 104.0,
        mode: 'check-in',
      );

      final frames = sentPayload?['frames'] as List<dynamic>;
      expect(frames, hasLength(4));
      expect(frames.toSet(), hasLength(4));
      expect(sentPayload?['mode'], 'check-in');
      expect(result.matched, isTrue);
      expect(result.verificationToken, 'test-token');
    } finally {
      for (final file in files) {
        if (await file.exists()) await file.delete();
      }
      if (await directory.exists()) await directory.delete();
    }
  });

  test(
    'foto wajah backend juga dianggap sudah terdaftar seperti web',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = SecureStorage(FlutterSecureStorage());
      final dio = Dio(BaseOptions(baseUrl: 'https://dev.jahris.id/api'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: const {
                'id': 'employee-avatar-test',
                'avatarUrl': 'https://s3.jahris.id/face.jpg',
                'faceDescriptor': null,
              },
            ),
          ),
        ),
      );
      final service = ApiFaceService(dio, storage);

      final status = await service.status('employee-avatar-test');

      expect(status.status, FaceEnrollmentStatus.sudah);
    },
  );

  test(
    'status wajah akun sendiri memakai sesi ketika detail user ditolak',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = SecureStorage(FlutterSecureStorage());
      final dio = Dio(BaseOptions(baseUrl: 'https://dev.jahris.id/api'));
      var detailRequested = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/auth/session') {
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  data: const {
                    'data': {
                      'user': {
                        'id': 'surya-id',
                        'faceImageUrl': 'https://s3.jahris.id/surya.jpg',
                      },
                    },
                  },
                ),
              );
              return;
            }
            detailRequested = true;
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<void>(
                  requestOptions: options,
                  statusCode: 403,
                ),
              ),
            );
          },
        ),
      );

      final status = await ApiFaceService(dio, storage).status('surya-id');

      expect(status.status, FaceEnrollmentStatus.sudah);
      expect(status.consentGranted, isTrue);
      expect(detailRequested, isFalse);
    },
  );

  test(
    'foto dapat diambil setelah liveness meski indikator tajam berfluktuasi',
    () {
      const state = FaceFlowState(
        args: FaceFlowArgs(
          employeeId: 'employee-quality-test',
          mode: FaceFlowMode.enroll,
        ),
        step: FaceLivenessStep.siap,
        isCameraReady: true,
        singleFace: true,
        lightingEnough: true,
        sharpEnough: false,
      );

      expect(state.isReadyToCapture, isTrue);
    },
  );

  test(
    'pose verifikasi otomatis mengikuti tengah lalu dua arah berlawanan',
    () {
      expect(
        FaceAutoCapturePose.tengahPertama.matchesYaw(9, centerYaw: 8),
        isTrue,
      );
      expect(
        FaceAutoCapturePose.tengahKedua.matchesYaw(7, centerYaw: 8),
        isTrue,
      );
      expect(
        FaceAutoCapturePose.tengokKanan.matchesYaw(16, centerYaw: 8),
        isTrue,
      );
      expect(
        FaceAutoCapturePose.tengokKiri.matchesYaw(
          17,
          centerYaw: 8,
          firstTurnSign: 1,
        ),
        isFalse,
      );
      expect(
        FaceAutoCapturePose.tengokKiri.matchesYaw(
          0,
          centerYaw: 8,
          firstTurnSign: 1,
        ),
        isTrue,
      );
      expect(
        FaceAutoCapturePose.tengahPertama.next,
        FaceAutoCapturePose.tengahKedua,
      );
      expect(FaceAutoCapturePose.tengokKiri.next, FaceAutoCapturePose.mengirim);
    },
  );

  test('instruksi verifikasi berasal dari tahap pengambilan otomatis', () {
    const state = FaceFlowState(
      args: FaceFlowArgs(
        employeeId: 'employee-auto-test',
        mode: FaceFlowMode.verify,
      ),
      autoCapturePose: FaceAutoCapturePose.tengokKanan,
    );

    expect(state.instruction, 'Tengok perlahan ke kanan');
  });

  group('MockFaceService', () {
    test('akun karyawan demo langsung siap membuka mockup', () async {
      final status = await MockFaceService().status('mock-employee-1');

      expect(status.status, FaceEnrollmentStatus.sudah);
      expect(status.consentGranted, isTrue);
    });

    test('mendukung consent, enroll, verify, dan reset wajah', () async {
      final service = MockFaceService();
      const employeeId = 'face-test-employee';

      expect(
        (await service.status(employeeId)).status,
        FaceEnrollmentStatus.belum,
      );

      await service.saveConsent(employeeId: employeeId, accepted: true);
      expect((await service.status(employeeId)).consentGranted, isTrue);

      await service.enroll(
        employeeId: employeeId,
        photoPaths: const ['photo-1.jpg', 'photo-2.jpg', 'photo-3.jpg'],
      );
      expect(
        (await service.status(employeeId)).status,
        FaceEnrollmentStatus.sudah,
      );

      final verified = await service.verify(
        employeeId: employeeId,
        photoPaths: const ['1.jpg', '2.jpg', '3.jpg', '4.jpg'],
        latitude: 1.1301,
        longitude: 104.0529,
      );
      expect(verified.matched, isTrue);
      expect(verified.verificationToken, isNotEmpty);

      service.verifyMode = MockFaceVerifyMode.gagal;
      final rejected = await service.verify(
        employeeId: employeeId,
        photoPaths: const ['1.jpg', '2.jpg', '3.jpg', '4.jpg'],
        latitude: 1.1301,
        longitude: 104.0529,
      );
      expect(rejected.matched, isFalse);

      await service.delete(employeeId);
      expect(
        (await service.status(employeeId)).status,
        FaceEnrollmentStatus.belum,
      );
    });
  });
}
