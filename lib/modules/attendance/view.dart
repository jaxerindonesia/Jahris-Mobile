import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/attendance_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/list_states.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../branch/provider.dart';
import 'model.dart';
import 'provider.dart';

class AttendanceView extends ConsumerWidget {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(attendanceProvider);
    final selected =
        attendance.value?.selectedMonth ??
        DateTime(DateTime.now().year, DateTime.now().month);
    return ModuleScaffold(
      title: context.l10n.attTitle,
      currentIndex: 1,
      showAppHeader: false,
      showPageHeading: false,
      backgroundGradient: AttendanceTheme.background,
      contentPadding: AttendanceTheme.pagePadding,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AttendanceDesignFrame(
            child: _AttendanceHeader(
              selected: selected,
              onSelected: (month) => ref
                  .read(attendanceProvider.notifier)
                  .filter(month, DateTime(month.year, month.month + 1, 0)),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: attendance.when(
              loading: () => const ListLoading(),
              error: (error, _) => ListError(
                message: networkErrorMessage(
                  error,
                  fallback: context.l10n.attLoadError,
                ),
                onRetry: () => ref.invalidate(attendanceProvider),
              ),
              data: (data) => _AttendanceContent(data: data),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceDesignFrame extends StatelessWidget {
  const _AttendanceDesignFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      width: constraints.maxWidth,
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: SizedBox(width: AttendanceTheme.designWidth, child: child),
      ),
    ),
  );
}

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader({required this.selected, required this.onSelected});
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final months = <DateTime>{
      for (var index = 0; index < 24; index++)
        DateTime(now.year, now.month - index),
      selected,
    }.toList()..sort((a, b) => b.compareTo(a));
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.attTitle,
                style: AttendanceTheme.heading.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(context.l10n.attSubtitle, style: AttendanceTheme.subtitle),
            ],
          ),
        ),
        PopupMenuButton<DateTime>(
          tooltip: context.l10n.attPickMonth,
          onSelected: onSelected,
          itemBuilder: (_) => [
            for (final month in months)
              PopupMenuItem(
                value: month,
                child: Text(
                  DateFormat('MMMM yyyy', context.dateLocale).format(month),
                ),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: dark ? AttendanceTheme.surface : AppColors.lightSurface,
              borderRadius: AttendanceTheme.pillRadius,
              border: Border.all(
                color: dark ? AttendanceTheme.border : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AttendanceTheme.purple,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM yyyy', context.dateLocale).format(selected),
                  style: AttendanceTheme.month,
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 14,
                  color: AttendanceTheme.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AttendanceContent extends ConsumerWidget {
  const _AttendanceContent({required this.data});
  final AttendanceState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(attendanceProvider.notifier);
    final records = data.monthRecords;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
        children: [
          _AttendanceDesignFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ClockCard(data: data),
                const SizedBox(height: 16),
                Text(
                  context.l10n.attSummary(
                    DateFormat(
                      'MMMM',
                      context.dateLocale,
                    ).format(data.selectedMonth),
                  ),
                  style: AttendanceTheme.section,
                ),
                const SizedBox(height: 10),
                _MonthlySummaryCard(summary: data.monthlySummary),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.attRecent,
                        style: AttendanceTheme.section,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showHistory(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AttendanceTheme.purple,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        context.l10n.attSeeAll,
                        style: AttendanceTheme.subtitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (data.message case final message?) ...[
                  Text(message, style: AttendanceTheme.subtitle),
                  const SizedBox(height: 8),
                ],
                if (records.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      context.l10n.attEmptyMonth,
                      textAlign: TextAlign.center,
                      style: AttendanceTheme.subtitle,
                    ),
                  )
                else
                  for (final item in records.take(5)) ...[
                    _AttendanceCard(item: item),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: dark ? AttendanceTheme.surface : AppColors.lightSurface,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Consumer(
          builder: (context, ref, _) => Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  context.l10n.attHistoryTitle,
                  style: AttendanceTheme.section,
                ),
              ),
              Expanded(
                child: ref
                    .watch(attendanceProvider)
                    .when(
                      loading: () => const ListLoading(),
                      error: (_, _) => ListError(
                        message: context.l10n.attHistoryError,
                        onRetry: () => ref.invalidate(attendanceProvider),
                      ),
                      data: (data) => data.monthRecords.isEmpty
                          ? Center(child: Text(context.l10n.attHistoryEmpty))
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                              children: [
                                for (final item in data.monthRecords) ...[
                                  _AttendanceCard(item: item),
                                  const SizedBox(height: 8),
                                ],
                                if (data.hasMore)
                                  TextButton(
                                    onPressed: ref
                                        .read(attendanceProvider.notifier)
                                        .loadMore,
                                    child: Text(context.l10n.attLoadMore),
                                  ),
                              ],
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

String _attendanceTime(DateTime? value) => value == null
    ? '--:--'
    : DateFormat('HH:mm', 'id_ID').format(value.toLocal());

String _attendanceDuration(BuildContext context, Duration value) =>
    context.l10n.attHoursMinutes(
      '${value.inHours}',
      (value.inMinutes % 60).toString().padLeft(2, '0'),
    );

/// Menerjemahkan status kehadiran (kunci internal berbahasa Indonesia).
String _statusText(BuildContext context, String status) {
  final l10n = context.l10n;
  return switch (status) {
    'Semua' => l10n.attStatusAll,
    'Tepat Waktu' => l10n.attStatusOnTime,
    'Terlambat' => l10n.attStatusLate,
    'Izin' => l10n.attStatusPermit,
    'Alpha' => l10n.attStatusAbsent,
    'Sedang Bekerja' => l10n.attStatusWorking,
    'Selesai' => l10n.attStatusDone,
    'Belum Masuk' => l10n.attStatusNotIn,
    _ => status,
  };
}

class _ClockCard extends StatelessWidget {
  const _ClockCard({required this.data});
  final AttendanceState data;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? AttendanceTheme.white : AppColors.lightText;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: dark ? AttendanceTheme.today : null,
        color: dark ? null : AppColors.lightSurface,
        borderRadius: AttendanceTheme.cardRadius,
        border: Border.all(
          color: dark ? AttendanceTheme.todayBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.attToday, style: AttendanceTheme.caption),
                    Text(
                      DateFormat(
                        'EEEE, d MMMM yyyy',
                        context.dateLocale,
                      ).format(data.now),
                      style: AttendanceTheme.date.copyWith(color: foreground),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _AttendancePill(
                label: _statusText(context, data.todayStatus),
                color: data.checkIn == null
                    ? AttendanceTheme.yellow
                    : AttendanceTheme.green,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TimeDisplay(
                  label: context.l10n.attIn,
                  value: _attendanceTime(data.checkIn),
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _TimeDisplay(
                  label: context.l10n.attOut,
                  value: _attendanceTime(data.checkOut),
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _TimeDisplay(
                  label: context.l10n.attDuration,
                  value: data.checkIn == null
                      ? '--'
                      : _attendanceDuration(context, data.workingDuration),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 12,
                color: AttendanceTheme.purple,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  context.l10n.attShift(
                    data.config.startHour,
                    data.config.endHour,
                  ),
                  style: AttendanceTheme.detail.copyWith(
                    color: AttendanceTheme.purple,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 26, color: AttendanceTheme.border);
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({required this.summary});
  final AttendanceMonthlySummary summary;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              value: '${summary.onTime}',
              label: context.l10n.attPresent,
              color: AttendanceTheme.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryMetric(
              value: '${summary.late}',
              label: context.l10n.attLate,
              color: AttendanceTheme.yellow,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryMetric(
              value: '${summary.leave}',
              label: context.l10n.attLeave,
              color: AttendanceTheme.purple,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryMetric(
              value: '${summary.absent}',
              label: context.l10n.attAbsent,
              color: AttendanceTheme.red,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _AttendanceSurface(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.attRate,
                      style: AttendanceTheme.subtitle,
                    ),
                  ),
                  Text(
                    '${(summary.rate * 100).round()}%',
                    style: AttendanceTheme.date.copyWith(
                      color: AttendanceTheme.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: AttendanceTheme.pillRadius,
                child: LinearProgressIndicator(
                  key: const ValueKey('attendance-rate'),
                  value: summary.rate,
                  minHeight: 5,
                  color: AttendanceTheme.green,
                  backgroundColor: AttendanceTheme.track,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _AttendanceSurface extends StatelessWidget {
  const _AttendanceSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? AttendanceTheme.surface : AppColors.lightSurface,
        borderRadius: AttendanceTheme.rowRadius,
        border: Border.all(
          color: dark ? AttendanceTheme.border : AppColors.lightBorder,
        ),
      ),
      child: child,
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => _AttendanceSurface(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Column(
        children: [
          Text(
            value,
            style: AttendanceTheme.count.copyWith(
              color: color.readable(context),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AttendanceTheme.caption,
          ),
        ],
      ),
    ),
  );
}

class _TimeDisplay extends StatelessWidget {
  const _TimeDisplay({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: AttendanceTheme.time),
      const SizedBox(height: 2),
      Text(label, style: AttendanceTheme.caption),
    ],
  );
}

class _AttendancePill extends StatelessWidget {
  const _AttendancePill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.17),
      borderRadius: AttendanceTheme.pillRadius,
    ),
    child: Text(
      label,
      style: AttendanceTheme.status.copyWith(color: color.readable(context)),
    ),
  );
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.item});
  final AttendanceRecord item;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = item.isLate
        ? AttendanceTheme.yellow
        : item.isLeave
        ? AttendanceTheme.purple
        : item.isAbsent
        ? AttendanceTheme.red
        : AttendanceTheme.green;
    final subtitle = item.isLeave || item.isAbsent
        ? item.branchName
        : '${item.checkOut == null ? context.l10n.attNotOut : _attendanceDuration(context, item.duration)} · ${item.branchName}';
    return _AttendanceSurface(
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 40,
              decoration: BoxDecoration(
                color: dark ? AttendanceTheme.badge : AppColors.lightBackground,
                borderRadius: AttendanceTheme.badgeRadius,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.date.day.toString().padLeft(2, '0'),
                    style: AttendanceTheme.day,
                  ),
                  Text(
                    DateFormat('E', context.dateLocale).format(item.date),
                    style: AttendanceTheme.detail,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.isLeave || item.isAbsent
                        ? item.status
                        : '${_attendanceTime(item.checkIn)} – ${_attendanceTime(item.checkOut)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AttendanceTheme.history,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AttendanceTheme.detail,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _AttendancePill(
              label: _statusText(context, item.statusLabel),
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceConfigView extends ConsumerWidget {
  const AttendanceConfigView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(attendanceProvider);
    return ModuleScaffold(
      title: 'Konfigurasi Kehadiran',
      subtitle: 'Atur jam kerja dan radius validasi cabang.',
      body: value.when(
        loading: () => const ListLoading(itemCount: 2),
        error: (error, _) => ListError(
          message: networkErrorMessage(
            error,
            fallback: 'Konfigurasi gagal dimuat.',
          ),
          onRetry: () => ref.invalidate(attendanceProvider),
        ),
        data: (data) => _ConfigForm(config: data.config),
      ),
    );
  }
}

class _ConfigForm extends ConsumerWidget {
  const _ConfigForm({required this.config});

  final AttendanceConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var start = config.startHour;
    var end = config.endHour;
    var tolerance = config.toleranceMinutes.toString();
    var branch = config.branchName;
    var radius = config.radiusMeters.toStringAsFixed(0);
    final branchNames =
        ref
            .watch(branchOptionsProvider)
            .value
            ?.map((item) => item.name)
            .toList() ??
        <String>[];
    return Form(
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          GlassCard(
            child: Column(
              children: [
                TextFormField(
                  initialValue: start,
                  decoration: const InputDecoration(labelText: 'Jam masuk'),
                  onChanged: (value) => start = value,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  initialValue: end,
                  decoration: const InputDecoration(labelText: 'Jam keluar'),
                  onChanged: (value) => end = value,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  initialValue: tolerance,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Toleransi (menit)',
                  ),
                  onChanged: (value) => tolerance = value,
                ),
                const SizedBox(height: AppSpacing.md),
                if (branchNames.isEmpty)
                  TextFormField(
                    initialValue: branch,
                    decoration: const InputDecoration(labelText: 'Cabang'),
                    onChanged: (value) => branch = value,
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: branchNames.contains(branch) ? branch : null,
                    decoration: const InputDecoration(labelText: 'Cabang'),
                    items: branchNames
                        .map(
                          (name) =>
                              DropdownMenuItem(value: name, child: Text(name)),
                        )
                        .toList(),
                    onChanged: (value) => branch = value ?? branch,
                  ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  initialValue: radius,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Radius (meter)',
                  ),
                  onChanged: (value) => radius = value,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Simpan Konfigurasi',
                  icon: Icons.save_rounded,
                  onPressed: () => ref
                      .read(attendanceProvider.notifier)
                      .saveConfig(
                        AttendanceConfig(
                          startHour: start.trim().isEmpty
                              ? config.startHour
                              : start.trim(),
                          endHour: end.trim().isEmpty
                              ? config.endHour
                              : end.trim(),
                          toleranceMinutes:
                              int.tryParse(tolerance) ??
                              config.toleranceMinutes,
                          branchName: branch.trim().isEmpty
                              ? config.branchName
                              : branch.trim(),
                          latitude: config.latitude,
                          longitude: config.longitude,
                          radiusMeters:
                              double.tryParse(radius) ?? config.radiusMeters,
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Halaman Riwayat Absen: kalender bulanan, ringkasan, dan detail harian.
class AttendanceHistoryView extends ConsumerWidget {
  const AttendanceHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(attendanceHistoryProvider);
    final controller = ref.read(attendanceHistoryProvider.notifier);
    final palette = _HistoryPalette.of(context);
    final data = value.value;
    final month =
        data?.month ?? DateTime(DateTime.now().year, DateTime.now().month);
    return Scaffold(
      backgroundColor: palette.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.gradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.compact,
              AppSpacing.sm,
              AppSpacing.compact,
              AppSpacing.xl,
            ),
            children: [
              Row(
                children: [
                  _HistoryIconButton(
                    tooltip: context.l10n.attBack,
                    icon: Icons.chevron_left_rounded,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/dashboard'),
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.attHistoryAbsen,
                      textAlign: TextAlign.center,
                      style: AttendanceTheme.historyTitle.copyWith(
                        color: palette.text,
                      ),
                    ),
                  ),
                  _HistoryIconButton(
                    tooltip: context.l10n.attFilterStatus,
                    icon: Icons.filter_alt_outlined,
                    highlighted: (data?.statusFilter ?? 'Semua') != 'Semua',
                    onPressed: data == null
                        ? null
                        : () => _showFilter(
                            context,
                            data.statusFilter,
                            controller.setStatusFilter,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _HistoryIconButton(
                    tooltip: context.l10n.attPrevMonth,
                    icon: Icons.chevron_left_rounded,
                    small: true,
                    onPressed: value.isLoading
                        ? null
                        : () => controller.changeMonth(-1),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy', context.dateLocale).format(month),
                      textAlign: TextAlign.center,
                      style: AttendanceTheme.historyMonth.copyWith(
                        color: palette.text,
                      ),
                    ),
                  ),
                  _HistoryIconButton(
                    tooltip: context.l10n.attNextMonth,
                    icon: Icons.chevron_right_rounded,
                    small: true,
                    onPressed: value.isLoading
                        ? null
                        : () => controller.changeMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.compact),
              ...value.when(
                loading: () => const [
                  SizedBox(
                    height: 280,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (error, _) => [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        Text(
                          context.l10n.attAbsenError,
                          textAlign: TextAlign.center,
                          style: AttendanceTheme.rowTitle.copyWith(
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: controller.reload,
                          child: Text(context.l10n.commonRetry),
                        ),
                      ],
                    ),
                  ),
                ],
                data: (data) => _historyContent(context, data, palette),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _historyContent(
    BuildContext context,
    AttendanceHistoryState data,
    _HistoryPalette palette,
  ) {
    final average = data.averageCheckIn;
    final total = data.totalWorked;
    final daily = data.dailyRecords;
    return [
      _HistoryCalendar(data: data, palette: palette),
      const SizedBox(height: AppSpacing.compact),
      Row(
        children: [
          Expanded(
            child: _HistoryStat(
              value: average == null
                  ? '--:--'
                  : '${average.inHours.toString().padLeft(2, '0')}:'
                        '${(average.inMinutes % 60).toString().padLeft(2, '0')}',
              label: context.l10n.attAvgIn,
              palette: palette,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _HistoryStat(
              value: context.l10n.attHoursShort('${total.inHours}'),
              label: context.l10n.attTotalHours,
              palette: palette,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _HistoryStat(
              value: '${data.lateCount}x',
              label: context.l10n.attLate,
              valueColor: AttendanceTheme.yellow,
              palette: palette,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        data.statusFilter == 'Semua'
            ? context.l10n.attDaily
            : context.l10n.attDailyFiltered(
                _statusText(context, data.statusFilter),
              ),
        style: AttendanceTheme.sectionTitle.copyWith(color: palette.text),
      ),
      const SizedBox(height: AppSpacing.sm),
      if (daily.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Text(
            data.records.isEmpty
                ? context.l10n.attAbsenEmpty
                : context.l10n.attNoStatusData(
                    _statusText(context, data.statusFilter),
                  ),
            textAlign: TextAlign.center,
            style: AttendanceTheme.rowCaption.copyWith(fontSize: 12),
          ),
        )
      else
        for (final record in daily) ...[
          _HistoryDayRow(record: record, palette: palette),
          const SizedBox(height: AppSpacing.sm),
        ],
    ];
  }

  void _showFilter(
    BuildContext context,
    String current,
    ValueChanged<String> onSelected,
  ) {
    final palette = _HistoryPalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: palette.panelSolid,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.attFilterTitle,
              style: AttendanceTheme.historyTitle.copyWith(color: palette.text),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final status in AttendanceHistoryState.statusFilters)
              ListTile(
                title: Text(
                  _statusText(context, status),
                  style: AttendanceTheme.rowTitle.copyWith(color: palette.text),
                ),
                trailing: status == current
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  onSelected(status);
                  Navigator.of(sheetContext).pop();
                },
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _HistoryPalette {
  const _HistoryPalette({
    required this.background,
    required this.gradient,
    required this.text,
    required this.panel,
    required this.panelSolid,
    required this.border,
  });

  factory _HistoryPalette.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const _HistoryPalette(
            background: AppColors.darkBackground,
            gradient: AttendanceTheme.background,
            text: AttendanceTheme.white,
            panel: AttendanceTheme.panelFill,
            panelSolid: AttendanceTheme.surface,
            border: AttendanceTheme.border,
          )
        : const _HistoryPalette(
            background: AppColors.lightBackground,
            gradient: null,
            text: AppColors.lightText,
            panel: AppColors.lightSurface,
            panelSolid: AppColors.lightSurface,
            border: AppColors.lightBorder,
          );
  }

  final Color background;
  final Gradient? gradient;
  final Color text;
  final Color panel;
  final Color panelSolid;
  final Color border;
}

class _HistoryIconButton extends StatelessWidget {
  const _HistoryIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.small = false,
    this.highlighted = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool small;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final palette = _HistoryPalette.of(context);
    final size = small ? 30.0 : 36.0;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: highlighted ? AppColors.primary : palette.panelSolid,
        shape: CircleBorder(side: BorderSide(color: palette.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: small ? 18 : 20,
              color: highlighted ? AttendanceTheme.white : palette.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCalendar extends StatelessWidget {
  const _HistoryCalendar({required this.data, required this.palette});

  final AttendanceHistoryState data;
  final _HistoryPalette palette;

  @override
  Widget build(BuildContext context) {
    final month = data.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = month.weekday - 1;
    final rows = ((leading + daysInMonth) / 7).ceil();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.compact,
      ),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: AttendanceTheme.panelRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final (index, name)
                  in context.l10n.weekdaysShort.split(',').indexed)
                Expanded(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: AttendanceTheme.calendarWeekday.copyWith(
                      color: index == 6 ? AttendanceTheme.red : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var row = 0; row < rows; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: Center(
                        child: _calendarCell(
                          row * 7 + col - leading + 1,
                          daysInMonth,
                          isSunday: col == 6,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _LegendDot(
                color: AttendanceTheme.green,
                label: context.l10n.attLegendOnTime,
              ),
              SizedBox(width: AppSpacing.compact),
              _LegendDot(
                color: AttendanceTheme.yellow,
                label: context.l10n.attStatusLate,
              ),
              SizedBox(width: AppSpacing.compact),
              _LegendDot(
                color: AttendanceTheme.purple,
                label: context.l10n.attStatusPermit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calendarCell(int day, int daysInMonth, {required bool isSunday}) {
    const size = AttendanceTheme.calendarCellSize;
    if (day < 1 || day > daysInMonth) {
      return const SizedBox.square(dimension: size);
    }
    final record = data.recordOn(
      DateTime(data.month.year, data.month.month, day),
    );
    final color = switch (record) {
      null => null,
      final r when r.isLeave => AttendanceTheme.purple,
      final r when r.isLate => AttendanceTheme.yellow,
      final r when r.isAbsent => AttendanceTheme.red,
      _ => AttendanceTheme.green,
    };
    final textColor =
        color ?? (isSunday ? AttendanceTheme.red : AttendanceTheme.muted);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: color == null
          ? null
          : BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
      child: Builder(
        builder: (context) => Text(
          '$day',
          style: AttendanceTheme.calendarDay.copyWith(
            color: textColor.readable(context),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: AttendanceTheme.legend),
    ],
  );
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({
    required this.value,
    required this.label,
    required this.palette,
    this.valueColor,
  });

  final String value;
  final String label;
  final _HistoryPalette palette;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.compact),
    decoration: BoxDecoration(
      color: palette.panel,
      borderRadius: AttendanceTheme.rowRadius12,
      border: Border.all(color: palette.border),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: AttendanceTheme.statValue.copyWith(
            color: valueColor?.readable(context) ?? palette.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AttendanceTheme.statLabel),
      ],
    ),
  );
}

class _HistoryDayRow extends StatelessWidget {
  const _HistoryDayRow({required this.record, required this.palette});

  final AttendanceRecord record;
  final _HistoryPalette palette;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = record.isLeave
        ? (AttendanceTheme.purple, context.l10n.attStatusPermit)
        : record.isLate
        ? (AttendanceTheme.yellow, context.l10n.attStatusLate)
        : record.isAbsent
        ? (AttendanceTheme.red, context.l10n.attStatusAbsent)
        : (AttendanceTheme.green, context.l10n.attStatusOnTime);
    final time = DateFormat('HH:mm', 'id_ID');
    final duration = record.duration;
    final checkIn = record.checkIn;
    final checkOut = record.checkOut;
    final showTimes = !record.isLeave && checkIn != null;
    final title = showTimes
        ? '${time.format(checkIn)} – '
              '${checkOut == null ? '--:--' : time.format(checkOut)}'
        : _statusText(context, record.status);
    final caption = showTimes
        ? '${_attendanceDuration(context, duration)} · ${record.branchName}'
        : record.branchName;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: AttendanceTheme.rowRadius12,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.panelSolid,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${record.date.day}',
                  style: AttendanceTheme.dayBadgeNumber.copyWith(
                    color: palette.text,
                  ),
                ),
                Text(
                  DateFormat(
                    'E',
                    context.dateLocale,
                  ).format(record.date).substring(0, 3),
                  style: AttendanceTheme.dayBadgeName,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.compact),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AttendanceTheme.rowTitle.copyWith(color: palette.text),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: AttendanceTheme.rowCaption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.16),
              borderRadius: AttendanceTheme.pillRadius,
            ),
            child: Text(
              statusLabel,
              style: AttendanceTheme.status.copyWith(
                color: statusColor.readable(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
