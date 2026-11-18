import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as image_lib;

import '../../core/config/env.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import 'model.dart';
import 'service.dart';

final faceServiceProvider = Provider<FaceService>((ref) {
  if (Env.useMock) {
    return MockFaceService(
      verifyMode: Env.mockFaceVerifyResult.toLowerCase() == 'failure'
          ? MockFaceVerifyMode.gagal
          : MockFaceVerifyMode.sukses,
    );
  }
  return ApiFaceService(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

final faceStatusProvider = FutureProvider.family<FaceStatus, String>(
  (ref, employeeId) => ref.watch(faceServiceProvider).status(employeeId),
);

final faceProvider = NotifierProvider<FaceController, FaceFlowState>(
  FaceController.new,
);

class FaceController extends Notifier<FaceFlowState> {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.12,
    ),
  );

  CameraController? _cameraController;
  CameraDescription? _camera;
  bool _processingFrame = false;
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _blinkStepStartedAt;
  DateTime? _poseStableSince;
  bool _eyesWereOpen = false;
  bool _autoCapturePending = false;
  double? _centerYaw;
  double? _firstTurnSign;
  final List<String> _facePhotos = [];

  CameraController? get cameraController => _cameraController;

  @override
  FaceFlowState build() {
    ref.onDispose(() {
      unawaited(_disposeResources());
    });
    return const FaceFlowState();
  }

  Future<void> initialize(FaceFlowArgs args) async {
    if (state.args?.employeeId == args.employeeId &&
        state.args?.mode == args.mode &&
        state.isCameraReady) {
      return;
    }
    await disposeCamera();
    _resetLivenessTracking();
    state = FaceFlowState(
      args: args,
      isProcessing: true,
      requiredCaptures: args.mode == FaceFlowMode.enroll ? 3 : 4,
      mockVerifyMode: Env.mockFaceVerifyResult.toLowerCase() == 'failure'
          ? MockFaceVerifyMode.gagal
          : MockFaceVerifyMode.sukses,
    );
    try {
      final cameras = await availableCameras();
      _camera = cameras.cast<CameraDescription?>().firstWhere(
        (item) => item?.lensDirection == CameraLensDirection.front,
        orElse: () => null,
      );
      if (_camera == null) {
        state = state.copyWith(
          isProcessing: false,
          errorMessage: 'Kamera depan tidak tersedia pada perangkat ini.',
        );
        return;
      }
      final controller = CameraController(
        _camera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      _cameraController = controller;
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      state = state.copyWith(
        isCameraReady: true,
        isProcessing: false,
        clearError: true,
      );
      await _startImageStream();
    } on CameraException catch (error) {
      final denied =
          error.code.toLowerCase().contains('access') ||
          error.code.toLowerCase().contains('permission');
      state = state.copyWith(
        isProcessing: false,
        errorMessage: denied
            ? 'Izin kamera ditolak. Izinkan kamera melalui pengaturan.'
            : 'Kamera tidak dapat dibuka. Silakan coba lagi.',
      );
    } catch (_) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Kamera tidak dapat dibuka. Silakan coba lagi.',
      );
    }
  }

  Future<void> captureAndSubmit() async {
    final args = state.args;
    final controller = _cameraController;
    if (args == null ||
        args.mode != FaceFlowMode.enroll ||
        controller == null ||
        !state.isReadyToCapture) {
      return;
    }
    state = state.copyWith(isProcessing: true, clearError: true);
    String? capturedPath;
    var shouldClearEnrollmentPhotos = false;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final file = await controller.takePicture();
      capturedPath = file.path;
      final quality = await compute(_inspectCapturedImage, file.path);
      if (!quality.lightingEnough || !quality.sharpEnough) {
        await _deleteFile(file.path);
        state = state.copyWith(
          isProcessing: false,
          lightingEnough: quality.lightingEnough,
          sharpEnough: quality.sharpEnough,
          errorMessage: !quality.lightingEnough
              ? 'Pencahayaan belum cukup. Pindah ke tempat yang lebih terang.'
              : 'Foto terlihat buram. Tahan ponsel dengan stabil.',
        );
        await _startImageStream();
        return;
      }

      _facePhotos.add(file.path);
      capturedPath = null;
      final count = _facePhotos.length;
      if (count < state.requiredCaptures) {
        state = state.copyWith(
          capturedCount: count,
          step: FaceLivenessStep.siap,
          isProcessing: false,
          faceDetected: false,
          singleFace: false,
          clearError: true,
        );
        await _startImageStream();
        return;
      }
      shouldClearEnrollmentPhotos = true;
      final status = await ref
          .read(faceServiceProvider)
          .enroll(employeeId: args.employeeId, photoPaths: _facePhotos);
      ref.invalidate(faceStatusProvider(args.employeeId));
      state = state.copyWith(
        capturedCount: count,
        isProcessing: false,
        result: FaceVerifyResult(
          matched: status.status == FaceEnrollmentStatus.sudah,
          message: status.status == FaceEnrollmentStatus.sudah
              ? 'Pendaftaran wajah berhasil.'
              : 'Pendaftaran wajah perlu diulang.',
        ),
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: _dioMessage(error),
      );
      if (state.result == null) await _restartAfterFailure();
    } on UnsupportedError catch (error) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: error.message?.toString() ?? 'Fitur belum tersedia.',
      );
      if (state.result == null) await _restartAfterFailure();
    } catch (_) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Proses wajah gagal. Silakan coba lagi.',
      );
      if (state.result == null) await _restartAfterFailure();
    } finally {
      if (capturedPath != null) await _deleteFile(capturedPath);
      if (state.result != null || shouldClearEnrollmentPhotos) {
        await _deleteEnrollmentPhotos();
      }
    }
  }

  Future<void> retryVerification() async {
    if (state.attemptsExhausted) return;
    _resetLivenessTracking();
    state = state.copyWith(
      step: FaceLivenessStep.hadapkanWajah,
      faceDetected: false,
      singleFace: false,
      lightingEnough: false,
      sharpEnough: false,
      capturedCount: 0,
      autoCapturePose: FaceAutoCapturePose.tengahPertama,
      clearResult: true,
      clearError: true,
    );
    await _startImageStream();
  }

  Future<bool> saveConsent(String employeeId, bool accepted) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      await ref
          .read(faceServiceProvider)
          .saveConsent(employeeId: employeeId, accepted: accepted);
      ref.invalidate(faceStatusProvider(employeeId));
      state = state.copyWith(isProcessing: false, clearError: true);
      return true;
    } catch (_) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage:
            'Persetujuan biometrik gagal disimpan. Silakan coba lagi.',
      );
      return false;
    }
  }

  Future<void> deleteEnrollment(String employeeId) async {
    await ref.read(faceServiceProvider).delete(employeeId);
    ref.invalidate(faceStatusProvider(employeeId));
  }

  void setMockVerifyMode(MockFaceVerifyMode mode) {
    final service = ref.read(faceServiceProvider);
    if (service is MockFaceService) service.verifyMode = mode;
    state = state.copyWith(mockVerifyMode: mode);
  }

  Future<void> disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    _camera = null;
    _processingFrame = false;
    _resetLivenessTracking();
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
    }
    await _deleteEnrollmentPhotos();
  }

  Future<void> _startImageStream() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages ||
        state.result?.matched == true) {
      return;
    }
    await controller.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final now = DateTime.now();
    if (_processingFrame ||
        now.difference(_lastFrameAt) < const Duration(milliseconds: 320)) {
      return;
    }
    _processingFrame = true;
    _lastFrameAt = now;
    try {
      final input = _inputImage(image);
      if (input == null) return;
      final quality = _inspectPreview(image);
      final faces = await _detector.processImage(input);
      final singleFace = faces.length == 1;
      var nextStep = state.step;
      String? errorMessage;
      if (faces.length > 1) {
        errorMessage = 'Pastikan hanya satu wajah berada di dalam bingkai.';
      } else if (faces.isEmpty) {
        nextStep = FaceLivenessStep.hadapkanWajah;
        _poseStableSince = null;
      } else {
        final face = faces.single;
        if (state.args?.mode == FaceFlowMode.verify) {
          nextStep = FaceLivenessStep.siap;
          final yaw = face.headEulerAngleY ?? 0;
          _centerYaw ??= yaw;
          final qualityReady = quality.lightingEnough;
          _considerAutomaticCapture(
            poseMatches:
                qualityReady &&
                state.autoCapturePose.matchesYaw(
                  yaw,
                  centerYaw: _centerYaw!,
                  firstTurnSign: _firstTurnSign,
                ),
            yaw: yaw,
            now: now,
          );
        } else if (nextStep == FaceLivenessStep.hadapkanWajah) {
          nextStep = FaceLivenessStep.kedipkanMata;
          _blinkStepStartedAt = now;
          _observeOpenEyes(face);
        } else if (nextStep == FaceLivenessStep.kedipkanMata) {
          final yaw = (face.headEulerAngleY ?? 0).abs();
          if (_isBlinking(face) || yaw >= 14) {
            nextStep = yaw >= 14
                ? FaceLivenessStep.siap
                : FaceLivenessStep.tengokKiri;
          } else if (_blinkStepStartedAt != null &&
              now.difference(_blinkStepStartedAt!) >=
                  const Duration(seconds: 5)) {
            // Sebagian perangkat tidak menyediakan probabilitas mata dengan
            // stabil. Tantangan tengok tetap menjadi pemeriksaan liveness.
            nextStep = FaceLivenessStep.tengokKiri;
          }
        } else if (nextStep == FaceLivenessStep.tengokKiri &&
            (face.headEulerAngleY ?? 0).abs() >= 12) {
          nextStep = FaceLivenessStep.siap;
        }
        if (!quality.lightingEnough) {
          errorMessage = 'Pencahayaan belum cukup.';
        } else if (!quality.sharpEnough) {
          errorMessage = 'Gambar kurang tajam. Tahan ponsel dengan stabil.';
        }
      }
      state = state.copyWith(
        step: nextStep,
        faceDetected: faces.isNotEmpty,
        singleFace: singleFace,
        lightingEnough: quality.lightingEnough,
        sharpEnough: quality.sharpEnough,
        errorMessage: errorMessage,
        clearError: errorMessage == null,
      );
    } catch (_) {
      // Frame yang gagal diproses dilewati tanpa mencatat data biometrik.
    } finally {
      _processingFrame = false;
    }
  }

  void _considerAutomaticCapture({
    required bool poseMatches,
    required double yaw,
    required DateTime now,
  }) {
    if (!poseMatches || state.isProcessing || _autoCapturePending) {
      if (!poseMatches) _poseStableSince = null;
      return;
    }
    _poseStableSince ??= now;
    if (now.difference(_poseStableSince!) < const Duration(milliseconds: 180)) {
      return;
    }
    _autoCapturePending = true;
    _poseStableSince = null;
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 120),
        () => _captureVerificationFrame(yaw),
      ),
    );
  }

  Future<void> _captureVerificationFrame(double yaw) async {
    final args = state.args;
    final controller = _cameraController;
    if (args == null ||
        args.mode != FaceFlowMode.verify ||
        controller == null ||
        !controller.value.isInitialized ||
        state.result != null) {
      _autoCapturePending = false;
      return;
    }

    final capturedPose = state.autoCapturePose;
    String? capturedPath;
    var clearPhotos = false;
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final file = await controller.takePicture();
      capturedPath = file.path;
      final quality = await compute(_inspectCapturedImage, file.path);
      if (!quality.lightingEnough || !quality.sharpEnough) {
        await _deleteFile(file.path);
        capturedPath = null;
        state = state.copyWith(
          isProcessing: false,
          lightingEnough: quality.lightingEnough,
          sharpEnough: quality.sharpEnough,
          errorMessage: !quality.lightingEnough
              ? 'Pencahayaan belum cukup. Pindah ke tempat yang lebih terang.'
              : 'Gambar buram. Tahan ponsel sebentar lalu ikuti arah lagi.',
        );
        return;
      }

      _facePhotos.add(file.path);
      capturedPath = null;
      if (capturedPose == FaceAutoCapturePose.tengahPertama ||
          capturedPose == FaceAutoCapturePose.tengahKedua) {
        _centerYaw = yaw;
      }
      if (capturedPose == FaceAutoCapturePose.tengokKanan) {
        _firstTurnSign = (yaw - (_centerYaw ?? 0)).sign;
      }
      final count = _facePhotos.length;
      if (count < state.requiredCaptures) {
        state = state.copyWith(
          capturedCount: count,
          autoCapturePose: capturedPose.next,
          isProcessing: false,
          clearError: true,
        );
        return;
      }

      clearPhotos = true;
      state = state.copyWith(
        capturedCount: count,
        autoCapturePose: FaceAutoCapturePose.mengirim,
      );
      final result = await ref
          .read(faceServiceProvider)
          .verify(
            employeeId: args.employeeId,
            photoPaths: _facePhotos,
            latitude: args.latitude ?? 0,
            longitude: args.longitude ?? 0,
            mode: args.verifyMode,
          );
      final attempts = state.verifyAttempts + 1;
      state = state.copyWith(
        verifyAttempts: attempts,
        isProcessing: false,
        result: result,
        errorMessage: result.matched ? null : result.message,
        clearError: result.matched,
      );
    } on DioException catch (error) {
      clearPhotos = true;
      state = state.copyWith(
        isProcessing: false,
        errorMessage: _dioMessage(error),
      );
    } on UnsupportedError catch (error) {
      clearPhotos = true;
      state = state.copyWith(
        isProcessing: false,
        errorMessage: error.message?.toString() ?? 'Fitur belum tersedia.',
      );
    } catch (_) {
      clearPhotos = true;
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Proses wajah gagal. Silakan coba lagi.',
      );
    } finally {
      if (capturedPath != null) await _deleteFile(capturedPath);
      if (clearPhotos || state.result != null) {
        await _deleteEnrollmentPhotos();
      }
      _autoCapturePending = false;
      _poseStableSince = null;
      if (state.result == null && _cameraController != null) {
        if (clearPhotos) {
          state = state.copyWith(
            capturedCount: 0,
            autoCapturePose: FaceAutoCapturePose.tengahPertama,
          );
          _firstTurnSign = null;
          _centerYaw = null;
        }
        await _startImageStream();
      }
    }
  }

  InputImage? _inputImage(CameraImage image) {
    final camera = _camera;
    final controller = _cameraController;
    if (camera == null || controller == null || image.planes.length != 1) {
      return null;
    }
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    } else {
      const orientations = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      };
      var compensation = orientations[controller.value.deviceOrientation];
      if (compensation == null) return null;
      compensation = camera.lensDirection == CameraLensDirection.front
          ? (camera.sensorOrientation + compensation) % 360
          : (camera.sensorOrientation - compensation + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (rotation == null ||
        format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  bool _isBlinking(Face face) {
    final probabilities = [
      face.leftEyeOpenProbability,
      face.rightEyeOpenProbability,
    ].whereType<double>().toList();
    if (probabilities.isEmpty) return false;
    final average =
        probabilities.reduce((left, right) => left + right) /
        probabilities.length;
    if (average >= 0.58) {
      _eyesWereOpen = true;
      return false;
    }
    return _eyesWereOpen && average <= 0.45;
  }

  void _observeOpenEyes(Face face) {
    final probabilities = [
      face.leftEyeOpenProbability,
      face.rightEyeOpenProbability,
    ].whereType<double>().toList();
    if (probabilities.any((value) => value >= 0.58)) {
      _eyesWereOpen = true;
    }
  }

  void _resetLivenessTracking() {
    _blinkStepStartedAt = null;
    _eyesWereOpen = false;
    _poseStableSince = null;
    _autoCapturePending = false;
    _centerYaw = null;
    _firstTurnSign = null;
  }

  _ImageQuality _inspectPreview(CameraImage image) {
    final bytes = image.planes.first.bytes;
    if (bytes.isEmpty) return const _ImageQuality(false, false);
    var sum = 0.0;
    var contrast = 0.0;
    var count = 0;
    var previous = bytes.first;
    final step = (bytes.length ~/ 1800).clamp(1, 1024);
    for (var index = 0; index < bytes.length; index += step) {
      final value = bytes[index];
      sum += value;
      contrast += (value - previous).abs();
      previous = value;
      count++;
    }
    final brightness = sum / count;
    final edgeContrast = contrast / count;
    return _ImageQuality(
      brightness >= 42 && brightness <= 235,
      edgeContrast >= 4,
    );
  }

  Future<void> _restartAfterFailure() async {
    _resetLivenessTracking();
    state = state.copyWith(
      step: FaceLivenessStep.hadapkanWajah,
      faceDetected: false,
      singleFace: false,
    );
    await _startImageStream();
  }

  String _dioMessage(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Tidak ada koneksi. Periksa internet lalu coba lagi.';
    }
    final body = error.response?.data;
    if (body is Map<String, dynamic>) {
      final apiError = body['error'];
      if (apiError is String && apiError.isNotEmpty) return apiError;
      if (apiError is Map<String, dynamic>) {
        final message = apiError['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    }
    return 'Layanan verifikasi wajah tidak tersedia.';
  }

  Future<void> _deleteEnrollmentPhotos() async {
    final paths = List<String>.of(_facePhotos);
    _facePhotos.clear();
    for (final path in paths) {
      await _deleteFile(path);
    }
  }

  Future<void> _deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // File cache bersifat sementara; kegagalan hapus tidak boleh membuka log.
    }
  }

  Future<void> _disposeResources() async {
    await disposeCamera();
    await _detector.close();
  }
}

class _ImageQuality {
  const _ImageQuality(this.lightingEnough, this.sharpEnough);

  final bool lightingEnough;
  final bool sharpEnough;
}

Future<_ImageQuality> _inspectCapturedImage(String path) async {
  final bytes = await File(path).readAsBytes();
  final decoded = image_lib.decodeImage(bytes);
  if (decoded == null || decoded.width < 160 || decoded.height < 160) {
    return const _ImageQuality(false, false);
  }
  final stepX = (decoded.width ~/ 80).clamp(1, 32);
  final stepY = (decoded.height ~/ 80).clamp(1, 32);
  var brightness = 0.0;
  var edgeContrast = 0.0;
  var count = 0;
  for (var y = stepY; y < decoded.height; y += stepY) {
    for (var x = stepX; x < decoded.width; x += stepX) {
      final value = decoded.getPixel(x, y).luminance.toDouble();
      final previous = decoded.getPixel(x - stepX, y).luminance.toDouble();
      brightness += value;
      edgeContrast += (value - previous).abs();
      count++;
    }
  }
  if (count == 0) return const _ImageQuality(false, false);
  return _ImageQuality(
    brightness / count >= 42 && brightness / count <= 235,
    edgeContrast / count >= 3,
  );
}
