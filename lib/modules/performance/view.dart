import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/list_states.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/status_chip.dart';
import 'model.dart';
import 'provider.dart';

class PerformanceView extends ConsumerWidget {
  const PerformanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(performanceProvider);
    return ModuleScaffold(
      title: 'Performa',
      subtitle: 'Ringkasan penilaian karyawan.',
      body: value.when(
        loading: () => const ListLoading(),
        error: (error, _) => ListError(
          message: networkErrorMessage(
            error,
            fallback: 'Data performa gagal dimuat.',
          ),
          onRetry: () => ref.invalidate(performanceProvider),
        ),
        data: (data) => _Content(data: data),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.data});
  final PerformanceState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(performanceProvider.notifier);
    if (data.items.isEmpty) {
      return ListEmpty(
        message: 'Belum ada data performa.',
        onRefresh: controller.refresh,
      );
    }
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
        itemCount: data.items.length + (data.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == data.items.length) {
            return TextButton(
              onPressed: controller.loadMore,
              child: const Text('Muat lainnya'),
            );
          }
          return _Card(item: data.items[index]);
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.item});
  final PerformanceRecord item;

  @override
  Widget build(BuildContext context) {
    final score = item.score ?? 0;
    final scoreColor = score >= 80
        ? AppColors.success
        : score >= 60
        ? AppColors.warning
        : AppColors.danger;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: scoreColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.card),
                  bottomLeft: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: scoreColor.withValues(alpha: 0.15),
                      child: Text(
                        _initials(item.employeeName ?? 'Karyawan'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.employeeName ?? 'Karyawan',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Text(
                            item.period ?? 'Periode belum tersedia',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$score',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: scoreColor),
                        ),
                        StatusChip(label: item.status ?? 'Belum diketahui'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final words = name.trim().split(' ');
    return words.take(2).map((w) => w.characters.first).join();
  }
}
