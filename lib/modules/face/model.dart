enum FaceEnrollmentStatus {
  belum,
  sudah,
  perluUlang;

  // TODO-API: verifikasi nilai status dari endpoint status wajah web.
  factory FaceEnrollmentStatus.fromJson(Object? value) {
    return switch (value?.toString().toLowerCase()) {
      'enrolled' || 'registered' || 'sudah' => FaceEnrollmentStatus.sudah,
      're_enroll' ||
      'needs_reenrollment' ||
      'perlu_ulang' => FaceEnrollmentStatus.perluUlang,
      _ => FaceEnrollmentStatus.belum,
    };
  }

  String get apiValue => switch (this) {
    FaceEnrollmentStatus.belum => 'not_enrolled',
    FaceEnrollmentStatus.sudah => 'enrolled',
    FaceEnrollmentStatus.perluUlang => 'needs_reenrollment',
  };

  String get label => switch (this) {
    FaceEnrollmentStatus.belum => 'Wajah belum terdaftar',
    FaceEnrollmentStatus.sudah => 'Wajah terdaftar',
    FaceEnrollmentStatus.perluUlang => 'Perlu daftar ulang wajah',
  };
}

class FaceStatus {
  const FaceStatus({
    required this.employeeId,
    required this.status,
    this.consentGranted = false,
    this.enrolledAt,
  });

  final String employeeId;
  final FaceEnrollmentStatus status;
  final bool consentGranted;
  final DateTime? enrolledAt;

  // TODO-API: verifikasi field persetujuan dan waktu pendaftaran wajah.
  factory FaceStatus.fromJson(Map<String, dynamic> json) => FaceStatus(
    employeeId: json['employeeId']?.toString() ?? '',
    status: FaceEnrollmentStatus.fromJson(json['status']),
    consentGranted:
        json['consentGranted'] as bool? ?? json['consent'] as bool? ?? false,
    enrolledAt: DateTime.tryParse(json['enrolledAt'] as String? ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'status': status.apiValue,
    'consentGranted': consentGranted,
    'enrolledAt': enrolledAt?.toIso8601String(),
  };
}

class FaceVerifyResult {
  const FaceVerifyResult({
    required this.matched,
    required this.message,
    this.score,
    this.reason,
    this.verificationToken,
    this.faceCaptureBase64,
  });

  final bool matched;
  final double? score;
  final String message;
  final String? reason;
  final String? verificationToken;
  final String? faceCaptureBase64;

  // Terverifikasi dari kontrak frontend /face-recognition/verify.
  factory FaceVerifyResult.fromJson(Map<String, dynamic> json) {
    return FaceVerifyResult(
      matched: json['ok'] as bool? ?? json['matched'] as bool? ?? false,
      score: (json['score'] as num?)?.toDouble(),
      reason: json['reason'] as String?,
      message:
          json['message'] as String? ??
          ((json['matched'] as bool? ?? false)
              ? 'Wajah berhasil diverifikasi.'
              : 'Wajah tidak cocok.'),
      verificationToken:
          json['verificationToken'] as String? ?? json['token'] as String?,
      faceCaptureBase64: json['faceCaptureBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'matched': matched,
    'score': score,
    'reason': reason,
    'message': message,
    'verificationToken': verificationToken,
    'faceCaptureBase64': faceCaptureBase64,
  };
}

enum FaceFlowMode { enroll, verify }

enum FaceLivenessStep { hadapkanWajah, kedipkanMata, tengokKiri, siap }

enum FaceAutoCapturePose {
  tengahPertama,
  tengahKedua,
  tengokKanan,
  tengokKiri,
  mengirim;

  bool matchesYaw(double yaw, {double centerYaw = 0, double? firstTurnSign}) =>
      switch (this) {
        FaceAutoCapturePose.tengahPertama ||
        FaceAutoCapturePose.tengahKedua => (yaw - centerYaw).abs() <= 8,
        FaceAutoCapturePose.tengokKanan => (yaw - centerYaw).abs() >= 7,
        FaceAutoCapturePose.tengokKiri =>
          (yaw - centerYaw).abs() >= 7 &&
              firstTurnSign != null &&
              (yaw - centerYaw).sign != firstTurnSign.sign,
        FaceAutoCapturePose.mengirim => false,
      };

  FaceAutoCapturePose get next => switch (this) {
    FaceAutoCapturePose.tengahPertama => FaceAutoCapturePose.tengahKedua,
    FaceAutoCapturePose.tengahKedua => FaceAutoCapturePose.tengokKanan,
    FaceAutoCapturePose.tengokKanan => FaceAutoCapturePose.tengokKiri,
    FaceAutoCapturePose.tengokKiri ||
    FaceAutoCapturePose.mengirim => FaceAutoCapturePose.mengirim,
  };
}

enum MockFaceVerifyMode { sukses, gagal }

class FaceFlowArgs {
  const FaceFlowArgs({
    required this.employeeId,
    required this.mode,
    this.latitude,
    this.longitude,
    this.selfEnrollment = false,
    this.verifyMode = 'attendance',
  });

  final String employeeId;
  final FaceFlowMode mode;
  final double? latitude;
  final double? longitude;
  final bool selfEnrollment;
  final String verifyMode;
}

class FaceFlowState {
  const FaceFlowState({
    this.args,
    this.step = FaceLivenessStep.hadapkanWajah,
    this.isCameraReady = false,
    this.isProcessing = false,
    this.faceDetected = false,
    this.singleFace = false,
    this.lightingEnough = false,
    this.sharpEnough = false,
    this.capturedCount = 0,
    this.requiredCaptures = 3,
    this.verifyAttempts = 0,
    this.mockVerifyMode = MockFaceVerifyMode.sukses,
    this.autoCapturePose = FaceAutoCapturePose.tengahPertama,
    this.result,
    this.errorMessage,
  });

  final FaceFlowArgs? args;
  final FaceLivenessStep step;
  final bool isCameraReady;
  final bool isProcessing;
  final bool faceDetected;
  final bool singleFace;
  final bool lightingEnough;
  final bool sharpEnough;
  final int capturedCount;
  final int requiredCaptures;
  final int verifyAttempts;
  final MockFaceVerifyMode mockVerifyMode;
  final FaceAutoCapturePose autoCapturePose;
  final FaceVerifyResult? result;
  final String? errorMessage;

  bool get isReadyToCapture =>
      isCameraReady &&
      !isProcessing &&
      singleFace &&
      lightingEnough &&
      step == FaceLivenessStep.siap;

  bool get attemptsExhausted => verifyAttempts >= 3 && result?.matched == false;

  String get instruction => args?.mode == FaceFlowMode.verify
      ? switch (autoCapturePose) {
          FaceAutoCapturePose.tengahPertama => 'Hadapkan wajah lurus ke kamera',
          FaceAutoCapturePose.tengahKedua => 'Tetap hadap lurus',
          FaceAutoCapturePose.tengokKanan => 'Tengok perlahan ke kanan',
          FaceAutoCapturePose.tengokKiri => 'Tengok perlahan ke kiri',
          FaceAutoCapturePose.mengirim => 'Memverifikasi wajah...',
        }
      : switch (step) {
          FaceLivenessStep.hadapkanWajah => 'Hadapkan wajah ke kamera',
          FaceLivenessStep.kedipkanMata => 'Kedipkan mata secara perlahan',
          FaceLivenessStep.tengokKiri =>
            'Tengok ke kiri atau kanan secara perlahan',
          FaceLivenessStep.siap =>
            'Ambil foto ${capturedCount + 1} dari $requiredCaptures',
        };

  FaceFlowState copyWith({
    FaceFlowArgs? args,
    FaceLivenessStep? step,
    bool? isCameraReady,
    bool? isProcessing,
    bool? faceDetected,
    bool? singleFace,
    bool? lightingEnough,
    bool? sharpEnough,
    int? capturedCount,
    int? requiredCaptures,
    int? verifyAttempts,
    MockFaceVerifyMode? mockVerifyMode,
    FaceAutoCapturePose? autoCapturePose,
    FaceVerifyResult? result,
    bool clearResult = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FaceFlowState(
      args: args ?? this.args,
      step: step ?? this.step,
      isCameraReady: isCameraReady ?? this.isCameraReady,
      isProcessing: isProcessing ?? this.isProcessing,
      faceDetected: faceDetected ?? this.faceDetected,
      singleFace: singleFace ?? this.singleFace,
      lightingEnough: lightingEnough ?? this.lightingEnough,
      sharpEnough: sharpEnough ?? this.sharpEnough,
      capturedCount: capturedCount ?? this.capturedCount,
      requiredCaptures: requiredCaptures ?? this.requiredCaptures,
      verifyAttempts: verifyAttempts ?? this.verifyAttempts,
      mockVerifyMode: mockVerifyMode ?? this.mockVerifyMode,
      autoCapturePose: autoCapturePose ?? this.autoCapturePose,
      result: clearResult ? null : result ?? this.result,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
