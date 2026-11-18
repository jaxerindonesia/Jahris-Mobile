import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image/image.dart' as image_lib;

import '../../core/network/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import 'model.dart';

abstract interface class FaceService {
  Future<FaceStatus> enroll({
    required String employeeId,
    required List<String> photoPaths,
  });
  Future<FaceVerifyResult> verify({
    required String employeeId,
    required List<String> photoPaths,
    required double latitude,
    required double longitude,
    String mode = 'attendance',
  });
  Future<FaceStatus> status(String employeeId);
  Future<void> delete(String employeeId);
  Future<void> saveConsent({
    required String employeeId,
    required bool accepted,
  });
}

class ApiFaceService implements FaceService {
  const ApiFaceService(this._dio, this._storage);

  final Dio _dio;
  final SecureStorage _storage;

  @override
  Future<FaceStatus> enroll({
    required String employeeId,
    required List<String> photoPaths,
  }) async {
    _ensureHttps();
    throw UnsupportedError(
      'Server JAHRIS belum menyediakan endpoint pendaftaran wajah yang aman. '
      'Endpoint web saat ini menyimpan faceDescriptor melalui /users/:id, '
      'sedangkan aplikasi tidak boleh membuat atau membandingkan descriptor '
      'wajah di perangkat.',
    );
  }

  @override
  Future<FaceVerifyResult> verify({
    required String employeeId,
    required List<String> photoPaths,
    required double latitude,
    required double longitude,
    String mode = 'attendance',
  }) async {
    _ensureHttps();
    if (photoPaths.length < 4) {
      throw ArgumentError.value(
        photoPaths.length,
        'photoPaths',
        'Verifikasi wajah memerlukan empat frame berbeda.',
      );
    }
    final frames = <String>[];
    for (final entry in photoPaths.take(4).indexed) {
      final index = entry.$1;
      final path = entry.$2;
      final bytes = await File(path).readAsBytes();
      final prepared = _prepareWebCompatibleFrame(
        bytes,
        maxWidth: index < 2 ? 480 : 256,
        quality: index < 2 ? 75 : 60,
      );
      frames.add('data:image/jpeg;base64,${base64Encode(prepared)}');
    }
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.faceVerify,
      data: {'frames': frames, 'mode': mode},
    );
    final parsed = FaceVerifyResult.fromJson(_userData(response.data));
    return FaceVerifyResult(
      matched: parsed.matched,
      score: parsed.score,
      reason: parsed.reason,
      message: parsed.message,
      verificationToken: parsed.verificationToken,
      faceCaptureBase64: frames.first,
    );
  }

  @override
  Future<FaceStatus> status(String employeeId) async {
    _ensureHttps();
    Map<String, dynamic>? sessionUser;
    try {
      final session = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.authSession,
      );
      final candidate = _userData(session.data);
      if (candidate['id']?.toString() == employeeId) {
        sessionUser = candidate;
        if (_hasFaceReference(candidate)) {
          return await _faceStatus(employeeId, candidate);
        }
      }
    } on DioException {
      // Detail user tetap dicoba untuk admin atau bentuk sesi yang minimal.
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.user(employeeId),
      );
      return await _faceStatus(employeeId, _userData(response.data));
    } on DioException {
      if (sessionUser != null) {
        return _faceStatus(employeeId, sessionUser);
      }
      rethrow;
    }
  }

  Future<FaceStatus> _faceStatus(
    String employeeId,
    Map<String, dynamic> data,
  ) async {
    final descriptor = data['faceDescriptor'];
    final hasDescriptor = descriptor is List && descriptor.isNotEmpty;
    final hasReference = hasDescriptor || _hasFaceReference(data);
    final storedConsent = await _storage.readFaceConsent(employeeId);
    return FaceStatus(
      employeeId: employeeId,
      status: hasReference
          ? FaceEnrollmentStatus.sudah
          : FaceEnrollmentStatus.belum,
      consentGranted: storedConsent ?? hasReference,
    );
  }

  bool _hasFaceReference(Map<String, dynamic> data) {
    final descriptor = data['faceDescriptor'];
    if (descriptor is List && descriptor.isNotEmpty) return true;
    for (final key in const [
      'avatarUrl',
      'faceImageUrl',
      'facePhotoUrl',
      'photoUrl',
      'profilePicture',
      'image',
    ]) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return true;
    }
    for (final key in const [
      'faceEnrolled',
      'hasFace',
      'isFaceRegistered',
      'faceVerified',
    ]) {
      if (data[key] == true) return true;
    }
    final status = (data['faceStatus'] ?? data['faceEnrollmentStatus'])
        ?.toString()
        .toLowerCase();
    return status == 'enrolled' ||
        status == 'registered' ||
        status == 'verified' ||
        status == 'sudah';
  }

  @override
  Future<void> delete(String employeeId) async {
    _ensureHttps();
    await _dio.put<void>(
      ApiEndpoints.user(employeeId),
      data: {'faceDescriptor': null, 'avatarUrl': null},
    );
  }

  @override
  Future<void> saveConsent({
    required String employeeId,
    required bool accepted,
  }) async {
    _ensureHttps();
    // TODO-BACKEND: pindahkan consent ke API setelah endpoint tersedia.
    // Fallback lokal hanya menyimpan keputusan, bukan foto/descriptor wajah.
    await _storage.writeFaceConsent(employeeId, accepted);
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

  void _ensureHttps() {
    final uri = Uri.tryParse(_dio.options.baseUrl);
    if (uri == null || uri.scheme.toLowerCase() != 'https') {
      throw StateError('Face API hanya boleh diakses melalui HTTPS.');
    }
  }
}

Uint8List _prepareWebCompatibleFrame(
  Uint8List bytes, {
  required int maxWidth,
  required int quality,
}) {
  final decoded = image_lib.decodeImage(bytes);
  if (decoded == null) return bytes;
  final oriented = image_lib.bakeOrientation(decoded);
  final resized = oriented.width > maxWidth
      ? image_lib.copyResize(
          oriented,
          width: maxWidth,
          interpolation: image_lib.Interpolation.linear,
        )
      : oriented;
  return Uint8List.fromList(image_lib.encodeJpg(resized, quality: quality));
}

class MockFaceService implements FaceService {
  MockFaceService({this.verifyMode = MockFaceVerifyMode.sukses});

  MockFaceVerifyMode verifyMode;

  static final Map<String, FaceStatus> _statuses = {
    'mock-admin-1': const FaceStatus(
      employeeId: 'mock-admin-1',
      status: FaceEnrollmentStatus.sudah,
      consentGranted: true,
    ),
    'mock-employee-1': const FaceStatus(
      employeeId: 'mock-employee-1',
      status: FaceEnrollmentStatus.sudah,
      consentGranted: true,
    ),
  };

  @override
  Future<FaceStatus> enroll({
    required String employeeId,
    required List<String> photoPaths,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final result = FaceStatus(
      employeeId: employeeId,
      status: FaceEnrollmentStatus.sudah,
      consentGranted: _statuses[employeeId]?.consentGranted ?? true,
      enrolledAt: DateTime.now(),
    );
    _statuses[employeeId] = result;
    return result;
  }

  @override
  Future<FaceVerifyResult> verify({
    required String employeeId,
    required List<String> photoPaths,
    required double latitude,
    required double longitude,
    String mode = 'attendance',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    final current = await status(employeeId);
    if (current.status != FaceEnrollmentStatus.sudah) {
      return const FaceVerifyResult(
        matched: false,
        message: 'Wajah belum terdaftar.',
      );
    }
    if (verifyMode == MockFaceVerifyMode.gagal) {
      return const FaceVerifyResult(
        matched: false,
        score: 0.31,
        message: 'Wajah tidak cocok. Silakan coba lagi.',
      );
    }
    return FaceVerifyResult(
      matched: true,
      score: 0.97,
      message: 'Wajah berhasil diverifikasi.',
      verificationToken: 'mock-face-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<FaceStatus> status(String employeeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _statuses[employeeId] ??
        FaceStatus(employeeId: employeeId, status: FaceEnrollmentStatus.belum);
  }

  @override
  Future<void> delete(String employeeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final current = await status(employeeId);
    _statuses[employeeId] = FaceStatus(
      employeeId: employeeId,
      status: FaceEnrollmentStatus.belum,
      consentGranted: current.consentGranted,
    );
  }

  @override
  Future<void> saveConsent({
    required String employeeId,
    required bool accepted,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final current = await status(employeeId);
    _statuses[employeeId] = FaceStatus(
      employeeId: employeeId,
      status: current.status,
      consentGranted: accepted,
      enrolledAt: current.enrolledAt,
    );
  }
}
