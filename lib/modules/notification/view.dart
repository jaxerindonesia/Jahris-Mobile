import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/list_states.dart';
import '../../core/widgets/module_scaffold.dart';
import 'model.dart';
import 'provider.dart';

// TODO-DESIGN: Stitch belum memiliki screen Notifikasi; UI mengikuti Dashboard.
class NotificationView extends ConsumerWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(notificationProvider);
    return ModuleScaffold(
      title: 'Notifikasi',
      subtitle: 'Pembaruan aktivitas dan pengingat Anda.',
      currentIndex: null,
      notificationCount: value.value?.unreadCount ?? 0,
      body: value.when(
        loading: () => const ListLoading(),
        error: (_, _) => ListError(
          message: 'Notifikasi gagal dimuat.',
          onRetry: () => ref.invalidate(notificationProvider),
        ),
        data: (data) => _NotificationContent(data: data),
      ),
    );
  }
}

class _NotificationContent extends ConsumerWidget {
  const _NotificationContent({required this.data});
  final NotificationState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(notificationProvider.notifier);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${data.unreadCount} belum dibaca',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: data.unreadCount == 0
                    ? null
                    : controller.markAllRead,
                child: const Text('Tandai semua dibaca'),
              ),
            ],
          ),
          if (!data.deviceRegistered)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: GlassCard(
                child: Text(
                  'Push notification belum aktif. Konfigurasi Firebase diperlukan.',
                ),
              ),
            ),
          if (data.message case final message?) ...[
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (data.items.isEmpty)
            const GlassCard(child: Center(child: Text('Belum ada notifikasi.')))
          else ...[
            for (final item in data.items) ...[
              _NotificationCard(item: item),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              'Menampilkan ${data.items.length} dari ${data.total} notifikasi',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (data.hasMore)
              TextButton(
                onPressed: controller.loadMore,
                child: const Text('Muat lainnya'),
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.item});
  final AppNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = switch (item.type) {
      'approval' => AppColors.warning,
      'attendance' => AppColors.success,
      'reimburse' => AppColors.purple,
      'task' => AppColors.primary,
      _ => AppColors.info,
    };
    return GlassCard(
      onTap: () async {
        await ref.read(notificationProvider.notifier).markRead(item.id);
        if (item.route case final route?) {
          if (context.mounted) context.push(route);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(_icon(item.type), color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (!item.isRead)
                      const Icon(
                        Icons.circle,
                        size: 9,
                        color: AppColors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(item.body),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppFormatters.date(item.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(String type) => switch (type) {
    'approval' => Icons.approval_rounded,
    'attendance' => Icons.fingerprint_rounded,
    'reimburse' => Icons.receipt_long_rounded,
    'task' => Icons.task_alt_rounded,
    _ => Icons.info_outline_rounded,
  };
}
