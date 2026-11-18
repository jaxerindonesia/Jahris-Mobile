import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/config/env.dart';
import '../../core/network/dio_client.dart';
import '../auth/provider.dart';
import 'model.dart';
import 'service.dart';

final branchServiceProvider = Provider<BranchService>((ref) {
  if (Env.useMock) return MockBranchService();
  return ApiBranchService(ref.watch(dioProvider));
});
final branchProvider = AsyncNotifierProvider<BranchController, BranchState>(
  BranchController.new,
);
final shiftScheduleProvider =
    AsyncNotifierProvider<ShiftScheduleController, ShiftScheduleState>(
      ShiftScheduleController.new,
    );
final branchOptionsProvider = FutureProvider<List<Branch>>((ref) async {
  final tenantId = ref.watch(
    authProvider.select((state) => state.user?.tenantId ?? ''),
  );
  final page = await ref
      .watch(branchServiceProvider)
      .list(limit: 100, tenantId: tenantId);
  return page.items.where((item) => item.active).toList();
});

class BranchController extends AsyncNotifier<BranchState> {
  static const _limit = 10;
  @override
  Future<BranchState> build() async {
    final page = await ref.read(branchServiceProvider).list(limit: _limit);
    return BranchState(
      items: page.items,
      page: page.page,
      total: page.total,
      hasMore: page.hasMore,
    );
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    final page = await ref
        .read(branchServiceProvider)
        .list(limit: _limit, query: current.query);
    state = AsyncData(
      current.copyWith(
        items: page.items,
        page: 1,
        total: page.total,
        hasMore: page.hasMore,
        clearMessage: true,
      ),
    );
  }

  Future<void> search(String query) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(query: query));
    await refresh();
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final page = await ref
        .read(branchServiceProvider)
        .list(page: current.page + 1, limit: _limit, query: current.query);
    state = AsyncData(
      current.copyWith(
        items: [...current.items, ...page.items],
        page: page.page,
        total: page.total,
        hasMore: page.hasMore,
      ),
    );
  }

  Future<bool> save(Branch branch) async {
    final current = state.value;
    if (current == null) return false;
    if (branch.name.trim().isEmpty ||
        branch.code.trim().isEmpty ||
        branch.radiusMeters <= 0 ||
        branch.latitude < -90 ||
        branch.latitude > 90 ||
        branch.longitude < -180 ||
        branch.longitude > 180) {
      state = AsyncData(
        current.copyWith(
          message: 'Nama, kode, alamat, koordinat, dan radius wajib diisi dengan benar.',
        ),
      );
      return false;
    }
    final user = ref.read(authProvider).user;
    final payload = branch.tenantId.isNotEmpty || user == null
        ? branch
        : Branch(
            id: branch.id,
            tenantId: user.tenantId,
            name: branch.name,
            code: branch.code,
            address: branch.address,
            latitude: branch.latitude,
            longitude: branch.longitude,
            radiusMeters: branch.radiusMeters,
            active: branch.active,
            locationLockEnabled: branch.locationLockEnabled,
            customWorkingHoursEnabled: branch.customWorkingHoursEnabled,
            scheduleType: branch.scheduleType,
            officeStartTime: branch.officeStartTime,
            officeEndTime: branch.officeEndTime,
            workingSchedules: branch.workingSchedules,
            raw: branch.raw,
          );
    await ref.read(branchServiceProvider).save(payload);
    await refresh();
    ref.invalidate(branchOptionsProvider);
    state = AsyncData(
      state.requireValue.copyWith(message: 'Cabang berhasil disimpan.'),
    );
    return true;
  }

  Future<void> delete(String id) async {
    await ref.read(branchServiceProvider).delete(id);
    await refresh();
    ref.invalidate(branchOptionsProvider);
  }

  Future<(double, double)?> useCurrentLocation() async {
    final current = state.value;
    if (current == null || current.isLocating) return null;
    state = AsyncData(current.copyWith(isLocating: true, clearMessage: true));
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        state = AsyncData(
          state.requireValue.copyWith(
            isLocating: false,
            message: 'Aktifkan layanan lokasi/GPS terlebih dahulu.',
          ),
        );
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        state = AsyncData(
          state.requireValue.copyWith(
            isLocating: false,
            message: 'Izin lokasi ditolak permanen. Aktifkan dari Pengaturan aplikasi.',
          ),
        );
        return null;
      }
      if (permission == LocationPermission.denied) {
        state = AsyncData(
          state.requireValue.copyWith(
            isLocating: false,
            message: 'Izin lokasi diperlukan untuk mengambil koordinat cabang.',
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
      state = AsyncData(
        state.requireValue.copyWith(
          pickedLatitude: position.latitude,
          pickedLongitude: position.longitude,
          isLocating: false,
          message: 'Koordinat lokasi berhasil diambil.',
        ),
      );
      return (position.latitude, position.longitude);
    } catch (_) {
      state = AsyncData(
        state.requireValue.copyWith(
          isLocating: false,
          message: 'Lokasi belum berhasil diambil. Periksa GPS lalu coba lagi.',
        ),
      );
      return null;
    }
  }
}

class ShiftScheduleController extends AsyncNotifier<ShiftScheduleState> {
  @override
  Future<ShiftScheduleState> build() async {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      throw StateError('Sesi pengguna tidak ditemukan.');
    }

    final service = ref.read(branchServiceProvider);
    Branch? branch;
    if (user.branchId.isNotEmpty) {
      try {
        branch = await service.detail(user.branchId);
      } catch (_) {
        // Beberapa role hanya mendapat akses melalui endpoint daftar cabang.
      }
    }
    if (branch == null) {
      final page = await service.list(
        limit: 100,
        tenantId: user.tenantId.isEmpty ? null : user.tenantId,
      );
      for (final item in page.items) {
        final sameId = user.branchId.isNotEmpty && item.id == user.branchId;
        final sameName =
            user.branchName.isNotEmpty &&
            item.name.toLowerCase() == user.branchName.toLowerCase();
        if (sameId || sameName) {
          branch = item;
          break;
        }
      }
      if (branch == null &&
          user.branchId.isEmpty &&
          user.branchName.isEmpty &&
          page.items.isNotEmpty) {
        branch = page.items.first;
      }
    }
    if (branch == null) {
      throw StateError('Jadwal cabang pengguna belum tersedia.');
    }

    final today = _dateOnly(DateTime.now());
    return ShiftScheduleState(
      branch: branch,
      weekStart: today.subtract(Duration(days: today.weekday - 1)),
      selectedDate: today,
    );
  }

  void selectDate(DateTime date) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedDate: _dateOnly(date)));
  }

  void previousWeek() => _moveWeek(-7);

  void nextWeek() => _moveWeek(7);

  void _moveWeek(int days) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        weekStart: current.weekStart.add(Duration(days: days)),
        selectedDate: current.selectedDate.add(Duration(days: days)),
      ),
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
