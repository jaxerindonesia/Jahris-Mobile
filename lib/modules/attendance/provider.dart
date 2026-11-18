import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/env.dart';
import '../../core/network/dio_client.dart';
import '../auth/provider.dart';
import '../branch/provider.dart';
import '../face/model.dart';
import 'model.dart';
import 'service.dart';

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  if (Env.useMock) {
    return MockAttendanceService(
      userName: ref.watch(authProvider).user?.name ?? 'Pengguna JAHRIS',
    );
  }
  return ApiAttendanceService(ref.watch(dioProvider));
});

final attendanceProvider =
    AsyncNotifierProvider<AttendanceController, AttendanceState>(
      AttendanceController.new,
    );

class AttendanceController extends AsyncNotifier<AttendanceState> {
  static const _limit = 50;
  Timer? _clock;

  @override
  Future<AttendanceState> build() async {
    _clock?.cancel();
    ref.onDispose(() => _clock?.cancel());
    final service = ref.watch(attendanceServiceProvider);
    final results = await Future.wait<dynamic>([
      _loadConfig(service),
      _loadInitialPage(service),
    ]);
    var config = results[0] as AttendanceConfig;
    final initialPage = results[1] as _InitialAttendancePage;
    final user = ref.watch(authProvider).user;

    // Ambil info cabang untuk semua user (admin maupun karyawan).
    // Karyawan tidak bisa akses /branches (403), jadi fallback ke nama dari profil user.
    if (user != null) {
      final branchLatitude = user.branchLatitude;
      final branchLongitude = user.branchLongitude;
      if (branchLatitude != null && branchLongitude != null) {
        config = config.withBranch(
          name: user.branchName.isNotEmpty
              ? user.branchName
              : config.branchName,
          latitude: branchLatitude,
          longitude: branchLongitude,
          radiusMeters: user.attendanceRadiusMeters ?? config.radiusMeters,
        );
      } else {
        if (user.branchId.isNotEmpty) {
          try {
            final branch = await ref
                .read(branchServiceProvider)
                .detail(user.branchId)
                .timeout(const Duration(seconds: 8));
            if (branch.latitude != 0 || branch.longitude != 0) {
              config = config.withBranch(
                name: branch.name,
                latitude: branch.latitude,
                longitude: branch.longitude,
                radiusMeters: branch.radiusMeters,
              );
            }
          } catch (_) {
            // Beberapa role hanya boleh membaca cabang melalui endpoint daftar.
          }
        }
        try {
          final branches = await ref
              .read(branchOptionsProvider.future)
              .timeout(const Duration(seconds: 8));
          // Cocokkan berdasarkan branchId user (paling akurat)
          final targetId = user.branchId;
          final targetName = user.branchName;
          for (final branch in branches) {
            final matchById = targetId.isNotEmpty && branch.id == targetId;
            final matchByName =
                targetName.isNotEmpty &&
                branch.name.toLowerCase() == targetName.toLowerCase();
            if (matchById || matchByName) {
              config = config.withBranch(
                name: branch.name,
                latitude: branch.latitude,
                longitude: branch.longitude,
                radiusMeters: branch.radiusMeters,
              );
              break;
            }
          }
        } catch (_) {
          // /branches 403 untuk karyawan — gunakan nama cabang dari profil user jika ada.
          final fallbackName = user.branchName.isNotEmpty
              ? user.branchName
              : config.branchName;
          if (fallbackName.isNotEmpty && config.branchName.isEmpty) {
            config = config.withBranch(
              name: fallbackName,
              latitude: config.latitude,
              longitude: config.longitude,
              radiusMeters: config.radiusMeters,
            );
          }
        }
        if (user.branchName.isNotEmpty && config.branchName.isEmpty) {
          config = config.withBranch(
            name: user.branchName,
            latitude: config.latitude,
            longitude: config.longitude,
            radiusMeters: config.radiusMeters,
          );
        }
      }
    }

    final page = initialPage.page;
    final todayRecord = _recordForToday(page.items);
    final permission = await _permissionStatus();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.value;
      if (current != null) {
        state = AsyncData(current.copyWith(now: DateTime.now()));
      }
    });
    return AttendanceState(
      records: page.items,
      config: config,
      now: DateTime.now(),
      locationStatus: permission,
      page: page.page,
      total: page.total,
      hasMore: page.hasMore,
      checkIn: todayRecord?.checkIn,
      checkOut: todayRecord?.checkOut,
      message: initialPage.message,
    );
  }

  Future<AttendanceConfig> _loadConfig(AttendanceService service) async {
    try {
      return await service.getConfig().timeout(const Duration(seconds: 12));
    } catch (_) {
      return const AttendanceConfig(
        startHour: '08:00',
        endHour: '17:00',
        toleranceMinutes: 15,
        branchName: '',
        latitude: 0,
        longitude: 0,
        radiusMeters: 100,
      );
    }
  }

  Future<_InitialAttendancePage> _loadInitialPage(
    AttendanceService service,
  ) async {
    try {
      final page = await service
          .list(limit: _limit, userId: _attendanceUserId())
          .timeout(const Duration(seconds: 12));
      return _InitialAttendancePage(page);
    } on DioException catch (error) {
      return _InitialAttendancePage.empty(_dioMessage(error));
    } on TimeoutException {
      return _InitialAttendancePage.empty(
        'Riwayat kehadiran belum dapat dimuat. Silakan tarik untuk mencoba lagi.',
      );
    } catch (_) {
      return _InitialAttendancePage.empty(
        'Riwayat kehadiran belum dapat dimuat.',
      );
    }
  }

  Future<void> refresh() async {
    final current = state.value;
    final page = await ref
        .read(attendanceServiceProvider)
        .list(
          limit: _limit,
          from: current?.from,
          to: current?.to,
          userId: _attendanceUserId(),
        );
    if (current != null) {
      final todayRecord = _recordForToday(page.items);
      state = AsyncData(
        current.copyWith(
          records: page.items,
          page: 1,
          total: page.total,
          hasMore: page.hasMore,
          checkIn: todayRecord?.checkIn,
          checkOut: todayRecord?.checkOut,
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final page = await ref
        .read(attendanceServiceProvider)
        .list(
          page: current.page + 1,
          limit: _limit,
          from: current.from,
          to: current.to,
          userId: _attendanceUserId(),
        );
    state = AsyncData(
      current.copyWith(
        records: [...current.records, ...page.items],
        page: page.page,
        total: page.total,
        hasMore: page.hasMore,
      ),
    );
  }

  Future<void> filter(DateTime? from, DateTime? to) async {
    final current = state.value;
    if (current == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await ref
          .read(attendanceServiceProvider)
          .list(limit: _limit, from: from, to: to, userId: _attendanceUserId());
      return current.copyWith(
        records: page.items,
        from: from,
        to: to,
        page: 1,
        total: page.total,
        hasMore: page.hasMore,
      );
    });
  }

  Future<AttendanceCheckRequest?> prepareCheck(bool isIn) async {
    final current = state.value;
    final user = ref.read(authProvider).user;
    if (current == null || user == null) return null;
    state = AsyncData(current.copyWith(isChecking: true, clearMessage: true));
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        state = AsyncData(
          current.copyWith(
            locationStatus: LocationAccessStatus.layananNonaktif,
            message: 'Layanan lokasi belum aktif.',
            isChecking: false,
          ),
        );
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = AsyncData(
          current.copyWith(
            locationStatus: LocationAccessStatus.ditolak,
            message: 'Izin lokasi ditolak. Buka pengaturan untuk mengizinkan.',
            isChecking: false,
          ),
        );
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final hasBranchCoordinates =
          current.config.latitude != 0 || current.config.longitude != 0;
      final distance = hasBranchCoordinates
          ? Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              current.config.latitude,
              current.config.longitude,
            )
          : null;
      if (distance != null && distance > current.config.radiusMeters) {
        state = AsyncData(
          current.copyWith(
            locationStatus: LocationAccessStatus.diizinkan,
            distanceMeters: distance,
            message:
                'Anda berjarak ${distance.round()} meter dari titik ${current.config.branchName}. Radius yang diizinkan ${current.config.radiusMeters.round()} meter (akurasi GPS ±${position.accuracy.round()} meter).',
            isChecking: false,
          ),
        );
        return null;
      }
      state = AsyncData(
        current.copyWith(
          locationStatus: LocationAccessStatus.diizinkan,
          distanceMeters: distance,
          isChecking: false,
          clearMessage: true,
        ),
      );
      return AttendanceCheckRequest(
        isIn: isIn,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        employeeId: user.id,
      );
    } on DioException catch (error) {
      state = AsyncData(
        current.copyWith(message: _dioMessage(error), isChecking: false),
      );
      return null;
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          message: 'Lokasi gagal diperoleh. Silakan coba lagi.',
          isChecking: false,
        ),
      );
      return null;
    }
  }

  Future<void> submitVerifiedCheck(
    AttendanceCheckRequest request,
    FaceVerifyResult? verification,
  ) async {
    final current = state.value;
    if (current == null || verification?.matched != true) return;
    final token = verification?.verificationToken;
    if (token == null || token.isEmpty) {
      state = AsyncData(
        current.copyWith(
          message: 'Token verifikasi wajah tidak tersedia. Silakan coba lagi.',
          isChecking: false,
        ),
      );
      return;
    }
    state = AsyncData(current.copyWith(isChecking: true, clearMessage: true));
    try {
      final record = await ref
          .read(attendanceServiceProvider)
          .check(
            isIn: request.isIn,
            latitude: request.latitude,
            longitude: request.longitude,
            accuracy: request.accuracy,
            faceVerificationToken: token,
            employeeId: request.employeeId,
            faceCaptureBase64: verification!.faceCaptureBase64 ?? '',
          );
      final updated = current.copyWith(
        locationStatus: LocationAccessStatus.diizinkan,
        checkIn: request.isIn
            ? record.checkIn ?? DateTime.now()
            : current.checkIn ?? record.checkIn,
        checkOut: request.isIn
            ? current.checkOut
            : record.checkOut ?? DateTime.now(),
        records: [
          record,
          ...current.records.where((item) => item.id != record.id),
        ],
        message: request.isIn
            ? 'Check In berhasil dan terverifikasi wajah.'
            : 'Check Out berhasil dan terverifikasi wajah.',
        isChecking: false,
      );
      state = AsyncData(updated);
    } on DioException catch (error) {
      state = AsyncData(
        current.copyWith(message: _dioMessage(error), isChecking: false),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          message: 'Absensi gagal dikirim. Silakan coba lagi.',
          isChecking: false,
        ),
      );
    }
  }

  AttendanceRecord? _recordForToday(List<AttendanceRecord> records) {
    final today = DateTime.now();
    for (final record in records) {
      final timestamp = record.checkIn ?? record.checkOut ?? record.date;
      final local = timestamp.isUtc ? timestamp.toLocal() : timestamp;
      if (local.year == today.year &&
          local.month == today.month &&
          local.day == today.day) {
        return record;
      }
    }
    return null;
  }

  String? _attendanceUserId() {
    final user = ref.read(authProvider).user;
    if (user == null || user.role.toLowerCase().contains('admin')) return null;
    return user.id;
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
    return 'Layanan absensi tidak tersedia. Silakan coba lagi.';
  }

  Future<void> openLocationSettings() async {
    final status = state.value?.locationStatus;
    if (status == LocationAccessStatus.layananNonaktif) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> export({bool share = false}) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isExporting: true, clearMessage: true));
    try {
      final bytes = await ref
          .read(attendanceServiceProvider)
          .export(from: current.from, to: current.to);
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}${Platform.pathSeparator}riwayat_kehadiran.csv',
      );
      await file.writeAsBytes(bytes, flush: true);
      if (share) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Riwayat Kehadiran JAHRIS',
          ),
        );
      } else {
        await OpenFilex.open(file.path);
      }
      state = AsyncData(
        current.copyWith(
          message: 'File ekspor berhasil dibuat.',
          isExporting: false,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          message: 'File ekspor gagal dibuat.',
          isExporting: false,
        ),
      );
    }
  }

  Future<void> saveConfig(AttendanceConfig config) async {
    final current = state.value;
    if (current == null) return;
    var resolved = config;
    if (Env.useMock) {
      final branches = await ref.read(branchOptionsProvider.future);
      final matches = branches.where(
        (branch) =>
            branch.name.toLowerCase() == config.branchName.toLowerCase(),
      );
      if (matches.isEmpty) {
        state = AsyncData(
          current.copyWith(
            message: 'Cabang ${config.branchName} tidak ditemukan.',
          ),
        );
        return;
      }
      final branch = matches.first;
      resolved = AttendanceConfig(
        startHour: config.startHour,
        endHour: config.endHour,
        toleranceMinutes: config.toleranceMinutes,
        branchName: branch.name,
        latitude: branch.latitude,
        longitude: branch.longitude,
        radiusMeters: branch.radiusMeters,
      );
    }
    final saved = await ref
        .read(attendanceServiceProvider)
        .saveConfig(resolved);
    state = AsyncData(
      current.copyWith(
        config: saved,
        message: 'Konfigurasi kehadiran disimpan.',
      ),
    );
  }

  Future<LocationAccessStatus> _permissionStatus() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccessStatus.layananNonaktif;
    }
    final permission = await Geolocator.checkPermission();
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationAccessStatus.diizinkan,
      LocationPermission.denied ||
      LocationPermission.deniedForever => LocationAccessStatus.ditolak,
      _ => LocationAccessStatus.belum,
    };
  }
}

class _InitialAttendancePage {
  const _InitialAttendancePage(this.page) : message = null;

  const _InitialAttendancePage.empty(this.message)
    : page = const AttendancePage(items: [], page: 1, total: 0, hasMore: false);

  final AttendancePage page;
  final String? message;
}

final attendanceHistoryProvider =
    AsyncNotifierProvider<AttendanceHistoryController, AttendanceHistoryState>(
      AttendanceHistoryController.new,
    );

class AttendanceHistoryController
    extends AsyncNotifier<AttendanceHistoryState> {
  @override
  Future<AttendanceHistoryState> build() {
    final now = DateTime.now();
    return _load(DateTime(now.year, now.month));
  }

  Future<AttendanceHistoryState> _load(
    DateTime month, {
    String statusFilter = 'Semua',
  }) async {
    final user = ref.read(authProvider).user;
    final userId = user == null || user.role.toLowerCase().contains('admin')
        ? null
        : user.id;
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1, 0);
    final page = await ref
        .read(attendanceServiceProvider)
        .list(limit: 62, from: from, to: to, userId: userId);
    final records = page.items
        .where((r) => r.date.year == month.year && r.date.month == month.month)
        .toList();
    return AttendanceHistoryState(
      month: from,
      records: records,
      statusFilter: statusFilter,
    );
  }

  Future<void> changeMonth(int offset) async {
    final current = state.value;
    final base = current?.month ?? DateTime.now();
    final target = DateTime(base.year, base.month + offset);
    final filter = current?.statusFilter ?? 'Semua';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(target, statusFilter: filter));
  }

  Future<void> reload() async {
    final current = state.value;
    final month = current?.month ?? DateTime.now();
    final filter = current?.statusFilter ?? 'Semua';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(month, statusFilter: filter));
  }

  void setStatusFilter(String filter) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(statusFilter: filter));
  }
}
