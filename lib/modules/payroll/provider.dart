import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/env.dart';
import '../../core/network/dio_client.dart';
import 'model.dart';
import 'service.dart';

final payrollServiceProvider = Provider<PayrollService>((ref) {
  if (Env.useMock) return MockPayrollService();
  return ApiPayrollService(ref.watch(dioProvider));
});

final payrollProvider = AsyncNotifierProvider<PayrollController, PayrollState>(
  PayrollController.new,
);
final payrollSlipProvider = FutureProvider.family<PayrollSlip, String>(
  (ref, id) => ref.watch(payrollServiceProvider).slipDetail(id),
);

class PayrollController extends AsyncNotifier<PayrollState> {
  static const _limit = 10;
  @override
  Future<PayrollState> build() async {
    final results = await Future.wait([
      ref.read(payrollServiceProvider).summary(),
      ref.read(payrollServiceProvider).slips(limit: _limit),
      ref.read(payrollServiceProvider).components(),
    ]);
    final page = results[1] as PayrollPage;
    return PayrollState(
      summary: results[0] as PayrollSummary,
      slips: page.items,
      components: results[2] as List<PayrollComponent>,
      page: page.page,
      total: page.total,
      hasMore: page.hasMore,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final page = await ref
        .read(payrollServiceProvider)
        .slips(page: current.page + 1, limit: _limit);
    state = AsyncData(
      current.copyWith(
        slips: [...current.slips, ...page.items],
        page: page.page,
        total: page.total,
        hasMore: page.hasMore,
      ),
    );
  }

  Future<void> saveComponent(PayrollComponent component) async {
    final current = state.value;
    if (current == null) return;
    try {
      final saved = await ref
          .read(payrollServiceProvider)
          .saveComponent(component);
      final exists = current.components.any((item) => item.id == saved.id);
      state = AsyncData(
        current.copyWith(
          components: exists
              ? [
                  for (final item in current.components)
                    if (item.id == saved.id) saved else item,
                ]
              : [...current.components, saved],
          message: 'Komponen payroll disimpan.',
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(message: 'Komponen payroll gagal disimpan.'),
      );
    }
  }

  Future<void> deleteComponent(String id) async {
    final current = state.value;
    if (current == null) return;
    await ref.read(payrollServiceProvider).deleteComponent(id);
    state = AsyncData(
      current.copyWith(
        components: current.components.where((item) => item.id != id).toList(),
        message: 'Komponen payroll dihapus.',
      ),
    );
  }

  Future<void> download(String id, {bool share = false}) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(isDownloading: true, clearMessage: true),
    );
    try {
      final bytes = await ref.read(payrollServiceProvider).downloadSlip(id);
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}${Platform.pathSeparator}slip_gaji_$id.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      if (share) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Slip Gaji JAHRIS'),
        );
      } else {
        await OpenFilex.open(file.path);
      }
      state = AsyncData(
        current.copyWith(
          isDownloading: false,
          message: 'Slip gaji berhasil diunduh.',
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isDownloading: false,
          message: 'Slip gaji gagal diunduh.',
        ),
      );
    }
  }
}
