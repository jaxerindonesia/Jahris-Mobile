import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/provider.dart';
import '../attendance/provider.dart';
import '../leave/provider.dart';
import '../overtime/provider.dart';
import 'model.dart';
import 'service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  if (Env.useMock) {
    return MockProfileService(ref.watch(authProvider).user);
  }
  return ApiProfileService(ref.watch(dioProvider));
});
final profileProvider = AsyncNotifierProvider<ProfileController, ProfileState>(
  ProfileController.new,
);

final profileStatisticsProvider = Provider<ProfileStatistics>((ref) {
  final leave = ref.watch(leaveProvider).value?.balance;
  final overtime = ref.watch(overtimeProvider).value?.items;
  final attendance = ref.watch(attendanceProvider).value?.records;
  final now = DateTime.now();
  final days = attendance
      ?.where(
        (item) =>
            item.date.year == now.year &&
            item.date.month == now.month &&
            item.checkIn != null,
      )
      .length;
  final hours = overtime?.fold<double>(
    0,
    (sum, item) => sum + (item.hours ?? 0),
  );
  final minutes = hours == null ? null : (hours * 60).round();
  final overtimeLabel = minutes == null
      ? '--'
      : '${minutes ~/ 60}j ${minutes % 60}m';
  return ProfileStatistics(
    remainingLeave: leave == null ? '--' : '${leave.remaining} hari',
    workDays: days?.toString() ?? '--',
    overtime: overtimeLabel,
  );
});

class ProfileController extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() async {
    // Jadikan akun aktif sebagai bagian dari dependensi provider. Dengan ini,
    // cache profil akun lama otomatis dibuang saat logout atau ganti akun.
    final activeUserId = ref.watch(
      authProvider.select((auth) => auth.user?.id),
    );
    if (activeUserId == null || activeUserId.isEmpty) {
      throw StateError('Sesi pengguna tidak tersedia.');
    }
    final profile = await ref.watch(profileServiceProvider).getProfile();
    if (profile.id.isNotEmpty && profile.id != activeUserId) {
      throw StateError('Profil tidak sesuai dengan pengguna aktif.');
    }
    return ProfileState(profile: profile);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  void toggleTheme() => ref.read(themeModeProvider.notifier).toggle();

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final current = state.value;
    if (current == null) return false;
    if (name.trim().isEmpty || !email.contains('@')) {
      state = AsyncData(
        current.copyWith(message: 'Nama dan email valid wajib diisi.'),
      );
      return false;
    }
    state = AsyncData(current.copyWith(isSaving: true, clearMessage: true));
    try {
      final updated = await ref
          .read(profileServiceProvider)
          .updateProfile(
            current.profile.copyWith(
              name: name.trim(),
              email: email.trim(),
              phone: phone.trim(),
            ),
          );
      _syncAuth(updated);
      state = AsyncData(
        ProfileState(profile: updated, message: 'Profil berhasil diperbarui.'),
      );
      return true;
    } catch (_) {
      state = AsyncData(
        current.copyWith(isSaving: false, message: 'Profil gagal diperbarui.'),
      );
      return false;
    }
  }

  Future<bool> updateBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    final current = state.value;
    if (current == null) return false;
    final number = accountNumber.replaceAll(RegExp(r'[\s-]'), '');
    if (bankName.trim().isEmpty ||
        accountName.trim().isEmpty ||
        !RegExp(r'^\d{6,20}$').hasMatch(number)) {
      state = AsyncData(
        current.copyWith(
          message:
              'Lengkapi nama bank, nama pemilik, dan nomor rekening '
              '(6–20 digit angka).',
        ),
      );
      return false;
    }
    state = AsyncData(current.copyWith(isSaving: true, clearMessage: true));
    try {
      final updated = await ref
          .read(profileServiceProvider)
          .updateProfile(
            current.profile.copyWith(
              bankName: bankName.trim(),
              bankAccountNumber: number,
              bankAccountName: accountName.trim(),
            ),
          );
      state = AsyncData(
        ProfileState(
          profile: updated,
          message: 'Rekening bank berhasil diperbarui.',
        ),
      );
      return true;
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isSaving: false,
          message: 'Rekening bank gagal diperbarui.',
        ),
      );
      return false;
    }
  }

  Future<void> switchTenant(String tenantId) async {
    final current = state.value;
    if (current == null || current.profile.tenant.id == tenantId) return;
    try {
      final updated = await ref
          .read(profileServiceProvider)
          .switchTenant(tenantId);
      _syncAuth(updated);
      state = AsyncData(
        ProfileState(
          profile: updated,
          message: 'Tenant aktif diganti ke ${updated.tenant.name}.',
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(message: 'Tenant gagal diganti.'));
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    final current = state.value;
    if (current == null) return false;
    if (newPassword.length < 6 || newPassword != confirmation) {
      state = AsyncData(
        current.copyWith(
          message:
              'Password baru minimal 6 karakter dan konfirmasi harus sama.',
        ),
      );
      return false;
    }
    try {
      await ref
          .read(profileServiceProvider)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      state = AsyncData(current.copyWith(message: 'Password berhasil diubah.'));
      return true;
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          message: 'Password gagal diubah. Periksa password lama.',
        ),
      );
      return false;
    }
  }

  void _syncAuth(UserProfile profile) {
    final current = ref.read(authProvider).user;
    final updated = current?.copyWith(
      name: profile.name,
      email: profile.email,
      role: profile.role,
      tenantName: profile.tenant.name,
    );
    if (updated != null) {
      ref.read(authProvider.notifier).replaceUser(updated);
    }
  }
}
