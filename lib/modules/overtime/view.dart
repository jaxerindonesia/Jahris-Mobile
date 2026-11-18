import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/overtime_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/list_states.dart';
import 'model.dart';
import 'provider.dart';

class OvertimeView extends ConsumerWidget {
  const OvertimeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(overtimeProvider);
    final palette = _OvertimePalette.of(context);
    return Scaffold(
      backgroundColor: palette.scaffold,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.background),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    Tooltip(
                      message: 'Kembali',
                      child: Material(
                        color: palette.headerButton,
                        shape: CircleBorder(
                          side: BorderSide(color: palette.headerButtonBorder),
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).maybePop(),
                          child: SizedBox.square(
                            dimension: 36,
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: palette.text,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Lembur',
                        textAlign: TextAlign.center,
                        style: OvertimeTheme.title.copyWith(
                          color: palette.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
              Expanded(
                child: value.when(
                  loading: () => const ListLoading(),
                  error: (error, _) => ListError(
                    message: networkErrorMessage(
                      error,
                      fallback: 'Data lembur gagal dimuat.',
                    ),
                    onRetry: () => ref.invalidate(overtimeProvider),
                  ),
                  data: (data) => _Content(data: data),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: OvertimeTheme.primary,
                      foregroundColor: OvertimeTheme.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pengajuan lembur belum tersedia.'),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      'Ajukan Lembur',
                      style: OvertimeTheme.button,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OvertimePalette {
  const _OvertimePalette({
    required this.scaffold,
    required this.background,
    required this.text,
    required this.muted,
    required this.headerButton,
    required this.headerButtonBorder,
    required this.tile,
    required this.tileBorder,
    required this.segment,
    required this.segmentBorder,
    required this.summaryGradient,
    required this.summaryBorder,
    required this.summaryDivider,
    required this.summaryLabel,
    required this.summaryValue,
    required this.stats,
    required this.pay,
    required this.tileTime,
  });

  factory _OvertimePalette.of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  static const _dark = _OvertimePalette(
    scaffold: AppColors.darkBackground,
    background: OvertimeTheme.background,
    text: OvertimeTheme.white,
    muted: OvertimeTheme.muted,
    headerButton: OvertimeTheme.surface,
    headerButtonBorder: OvertimeTheme.border,
    tile: OvertimeTheme.surface,
    tileBorder: OvertimeTheme.border,
    segment: OvertimeTheme.surface,
    segmentBorder: OvertimeTheme.border,
    summaryGradient: OvertimeTheme.summaryGradient,
    summaryBorder: OvertimeTheme.summaryBorder,
    summaryDivider: OvertimeTheme.summaryDivider,
    summaryLabel: OvertimeTheme.summaryLabelColor,
    summaryValue: OvertimeTheme.white,
    stats: OvertimeTheme.statsText,
    pay: OvertimeTheme.pay,
    tileTime: OvertimeTheme.tileTimeColor,
  );

  static const _light = _OvertimePalette(
    scaffold: AppColors.lightBackground,
    background: OvertimeTheme.lightBackground,
    text: OvertimeTheme.lightText,
    muted: OvertimeTheme.lightMuted,
    headerButton: OvertimeTheme.lightHeaderButton,
    headerButtonBorder: OvertimeTheme.lightHeaderButton,
    tile: OvertimeTheme.lightTile,
    tileBorder: OvertimeTheme.lightTileBorder,
    segment: OvertimeTheme.lightSegment,
    segmentBorder: OvertimeTheme.lightSegmentBorder,
    summaryGradient: OvertimeTheme.lightSummaryGradient,
    summaryBorder: OvertimeTheme.lightSummaryBorder,
    summaryDivider: OvertimeTheme.lightSummaryDivider,
    summaryLabel: OvertimeTheme.lightSummaryLabel,
    summaryValue: OvertimeTheme.lightText,
    stats: OvertimeTheme.lightStats,
    pay: OvertimeTheme.lightPay,
    tileTime: OvertimeTheme.lightTileTime,
  );

  final Color scaffold;
  final Gradient background;
  final Color text;
  final Color muted;
  final Color headerButton;
  final Color headerButtonBorder;
  final Color tile;
  final Color tileBorder;
  final Color segment;
  final Color segmentBorder;
  final Gradient summaryGradient;
  final Color summaryBorder;
  final Color summaryDivider;
  final Color summaryLabel;
  final Color summaryValue;
  final Color stats;
  final Color pay;
  final Color tileTime;
}

class _Content extends ConsumerWidget {
  const _Content({required this.data});
  final OvertimeState data;

  static const _filters = ['Semua', 'Menunggu', 'Disetujui'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(overtimeProvider.notifier);
    final palette = _OvertimePalette.of(context);
    final totalHours = data.items.fold<double>(
      0,
      (sum, item) => sum + (item.hours ?? 0),
    );
    final totalPay = data.items.fold<double>(
      0,
      (sum, item) => sum + (item.estimatedPay ?? 0),
    );
    final approved = data.items
        .where((item) => _statusKind(item.status) == _Status.approved)
        .length;
    final pending = data.items
        .where((item) => _statusKind(item.status) == _Status.pending)
        .length;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          _SummaryCard(
            month: DateFormat('MMMM', 'id_ID').format(DateTime.now()),
            totalHours: _durationLabel(totalHours),
            totalPay: totalPay > 0 ? AppFormatters.rupiah(totalPay) : '-',
            stats:
                '${data.total} pengajuan · '
                '$approved disetujui · $pending menunggu',
          ),
          const SizedBox(height: AppSpacing.md),
          _SegmentedFilter(
            filters: _filters,
            current: data.status.isEmpty ? 'Semua' : data.status,
            onSelected: (label) =>
                controller.filter(label == 'Semua' ? '' : label),
          ),
          const SizedBox(height: AppSpacing.md),
          if (data.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'Belum ada pengajuan lembur.',
                textAlign: TextAlign.center,
                style: OvertimeTheme.tileNote.copyWith(
                  fontSize: 13,
                  color: palette.muted,
                ),
              ),
            )
          else
            for (final item in data.items) ...[
              _HistoryCard(item: item, palette: palette),
              const SizedBox(height: AppSpacing.compact),
            ],
          if (data.hasMore)
            TextButton(
              onPressed: controller.loadMore,
              child: const Text('Muat lainnya'),
            ),
        ],
      ),
    );
  }

  String _durationLabel(double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}j';
    return '${h}j ${m}m';
  }
}

enum _Status { pending, approved, rejected, other }

_Status _statusKind(String? value) {
  final status = (value ?? '').toLowerCase();
  if (status.contains('setuju') || status.contains('approve')) {
    return _Status.approved;
  }
  if (status.contains('tolak') || status.contains('reject')) {
    return _Status.rejected;
  }
  if (status.contains('nunggu') ||
      status.contains('tunggu') ||
      status.contains('pending') ||
      status.contains('submit') ||
      status.contains('ajukan')) {
    return _Status.pending;
  }
  return _Status.other;
}

bool _isLight(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light;

Color _statusColor(BuildContext context, String? value) {
  final light = _isLight(context);
  return switch (_statusKind(value)) {
    _Status.approved =>
      light ? OvertimeTheme.lightApproved : OvertimeTheme.approved,
    _Status.rejected =>
      light ? OvertimeTheme.lightRejected : OvertimeTheme.rejected,
    _Status.pending =>
      light ? OvertimeTheme.lightPending : OvertimeTheme.pending,
    _Status.other => light ? OvertimeTheme.lightMuted : OvertimeTheme.muted,
  };
}

Color _statusFill(BuildContext context, String? value) {
  if (!_isLight(context)) {
    return _statusColor(context, value).withValues(alpha: 0.18);
  }
  return switch (_statusKind(value)) {
    _Status.approved => OvertimeTheme.lightApprovedFill,
    _Status.rejected => OvertimeTheme.lightRejectedFill,
    _Status.pending => OvertimeTheme.lightPendingFill,
    _Status.other => OvertimeTheme.lightOtherFill,
  };
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.month,
    required this.totalHours,
    required this.totalPay,
    required this.stats,
  });

  final String month;
  final String totalHours;
  final String totalPay;
  final String stats;

  @override
  Widget build(BuildContext context) {
    final palette = _OvertimePalette.of(context);
    final label = OvertimeTheme.summaryLabel.copyWith(
      color: palette.summaryLabel,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: palette.summaryGradient,
        borderRadius: OvertimeTheme.cardRadius,
        border: Border.fromBorderSide(BorderSide(color: palette.summaryBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total lembur $month', style: label),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      totalHours,
                      style: OvertimeTheme.summaryValue.copyWith(
                        color: palette.summaryValue,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Estimasi upah', style: label),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    totalPay,
                    style: OvertimeTheme.payValue.copyWith(color: palette.pay),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.compact),
          Divider(height: 1, color: palette.summaryDivider),
          const SizedBox(height: AppSpacing.compact),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: palette.stats),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  stats,
                  style: OvertimeTheme.stats.copyWith(color: palette.stats),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedFilter extends StatelessWidget {
  const _SegmentedFilter({
    required this.filters,
    required this.current,
    required this.onSelected,
  });

  final List<String> filters;
  final String current;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = _OvertimePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.segment,
        borderRadius: OvertimeTheme.pillRadius,
        border: Border.all(color: palette.segmentBorder),
      ),
      child: Row(
        children: [
          for (final label in filters)
            Expanded(
              child: Material(
                color: current == label
                    ? OvertimeTheme.primary
                    : Colors.transparent,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onSelected(label),
                  child: SizedBox(
                    height: 34,
                    child: Center(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OvertimeTheme.tab.copyWith(
                          color: current == label
                              ? OvertimeTheme.white
                              : palette.muted,
                          fontWeight: current == label
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.palette});

  final OvertimeRecord item;
  final _OvertimePalette palette;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, item.status);
    final statusFill = _statusFill(context, item.status);
    final range =
        '${AppFormatters.shortTime(item.startAt)} – '
        '${AppFormatters.shortTime(item.endAt)} · ${_durationLabel(item.hours)}';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: OvertimeTheme.tileRadius,
        border: Border.all(color: palette.tileBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: OvertimeTheme.iconRadius,
              color: statusFill,
            ),
            child: Icon(
              Icons.timer_outlined,
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.compact),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.date == null
                      ? 'Tanggal belum tersedia'
                      : DateFormat(
                          'EEEE, d MMM yyyy',
                          'id_ID',
                        ).format(item.date!),
                  style: OvertimeTheme.tileTitle.copyWith(color: palette.text),
                ),
                const SizedBox(height: 4),
                Text(
                  range,
                  style: OvertimeTheme.tileTime.copyWith(
                    color: palette.tileTime,
                  ),
                ),
                if (item.note case final note?) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: OvertimeTheme.tileNote.copyWith(
                      color: palette.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: statusFill,
              borderRadius: OvertimeTheme.pillRadius,
            ),
            child: Text(
              item.status ?? 'Belum diketahui',
              style: OvertimeTheme.status.copyWith(
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _durationLabel(double? hours) {
    if (hours == null) return '-';
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}j ${m.toString().padLeft(2, '0')}m';
  }
}
