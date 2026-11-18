import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/holiday_theme.dart';
import '../../core/widgets/list_states.dart';
import 'model.dart';
import 'provider.dart';

class HolidayView extends ConsumerWidget {
  const HolidayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(holidayProvider);
    final palette = _HolidayPalette.of(context);
    return Scaffold(
      backgroundColor: palette.scaffold,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.background),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: _HolidayHeader(),
              ),
              Expanded(
                child: value.when(
                  loading: () => const ListLoading(itemCount: 4),
                  error: (_, _) => ListError(
                    message: 'Kalender libur gagal dimuat.',
                    onRetry: () => ref.invalidate(holidayProvider),
                  ),
                  data: (data) => _HolidayContent(data: data),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HolidayPalette {
  const _HolidayPalette({
    required this.scaffold,
    required this.background,
    required this.text,
    required this.muted,
    required this.weekend,
    required this.surface,
    required this.border,
  });

  factory _HolidayPalette.of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const _HolidayPalette(
          scaffold: AppColors.darkBackground,
          background: HolidayTheme.background,
          text: HolidayTheme.white,
          muted: HolidayTheme.muted,
          weekend: HolidayTheme.weekend,
          surface: HolidayTheme.surface,
          border: HolidayTheme.border,
        )
      : const _HolidayPalette(
          scaffold: AppColors.lightBackground,
          background: null,
          text: AppColors.lightText,
          muted: AppColors.lightMuted,
          weekend: AppColors.lightMuted,
          surface: AppColors.lightSurface,
          border: AppColors.lightBorder,
        );

  final Color scaffold;
  final Gradient? background;
  final Color text;
  final Color muted;
  final Color weekend;
  final Color surface;
  final Color border;
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _HolidayPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.surface,
        shape: CircleBorder(side: BorderSide(color: palette.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 32,
            child: Icon(icon, color: palette.text, size: 20),
          ),
        ),
      ),
    );
  }
}

class _HolidayHeader extends StatelessWidget {
  const _HolidayHeader();

  @override
  Widget build(BuildContext context) {
    final palette = _HolidayPalette.of(context);
    return Row(
      children: [
        _RoundButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Kembali',
          onTap: () =>
              context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        Expanded(
          child: Text(
            'Kalender Libur',
            textAlign: TextAlign.center,
            style: HolidayTheme.title.copyWith(color: palette.text),
          ),
        ),
        const SizedBox(width: 32),
      ],
    );
  }
}

class _HolidayContent extends ConsumerWidget {
  const _HolidayContent({required this.data});

  final HolidayState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _HolidayPalette.of(context);
    return RefreshIndicator(
      onRefresh: ref.read(holidayProvider.notifier).refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          _MonthSelector(month: data.displayedMonth),
          const SizedBox(height: AppSpacing.sm),
          _CalendarCard(state: data),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Libur Mendatang',
            style: HolidayTheme.section.copyWith(color: palette.text),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (data.upcomingHolidays.isEmpty)
            const _EmptyHoliday()
          else
            for (final holiday in data.upcomingHolidays) ...[
              _HolidayTile(holiday: holiday),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _HolidayPalette.of(context);
    final controller = ref.read(holidayProvider.notifier);
    return Row(
      children: [
        _RoundButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Bulan sebelumnya',
          onTap: controller.previousMonth,
        ),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy', 'id_ID').format(month),
            textAlign: TextAlign.center,
            style: HolidayTheme.month.copyWith(color: palette.text),
          ),
        ),
        _RoundButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Bulan berikutnya',
          onTap: controller.nextMonth,
        ),
      ],
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.state});

  final HolidayState state;

  @override
  Widget build(BuildContext context) {
    final palette = _HolidayPalette.of(context);
    final month = state.displayedMonth;
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = firstDay.weekday - 1;
    final weeks = (leading + daysInMonth + 6) ~/ 7;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: HolidayTheme.cardRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          const _WeekdayHeader(),
          const SizedBox(height: AppSpacing.sm),
          for (var week = 0; week < weeks; week++)
            Row(
              children: [
                for (var weekday = 0; weekday < 7; weekday++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final day = week * 7 + weekday - leading + 1;
                        if (day < 1 || day > daysInMonth) {
                          return const SizedBox(height: 36);
                        }
                        final date = DateTime(month.year, month.month, day);
                        final holiday = state.displayedHolidays
                            .where(
                              (item) => DateUtils.isSameDay(item.date, date),
                            )
                            .firstOrNull;
                        return _CalendarDay(date: date, holiday: holiday);
                      },
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                _Legend(color: HolidayTheme.national, label: 'Libur nasional'),
                SizedBox(width: AppSpacing.xl),
                _Legend(color: HolidayTheme.collective, label: 'Cuti bersama'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final palette = _HolidayPalette.of(context);
    return Row(
      children: [
        for (final day in const [
          'Sen',
          'Sel',
          'Rab',
          'Kam',
          'Jum',
          'Sab',
          'Min',
        ])
          Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: HolidayTheme.weekday.copyWith(
                color: day == 'Min' ? HolidayTheme.national : palette.muted,
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({required this.date, required this.holiday});

  final DateTime date;
  final Holiday? holiday;

  @override
  Widget build(BuildContext context) {
    final palette = _HolidayPalette.of(context);
    final isCollective = holiday?.type == HolidayType.collectiveLeave;
    final Color foreground;
    final Color fill;
    if (holiday != null) {
      foreground = isCollective
          ? HolidayTheme.collective
          : HolidayTheme.national;
      fill = isCollective
          ? HolidayTheme.collectiveFill
          : HolidayTheme.nationalFill;
    } else {
      foreground = switch (date.weekday) {
        DateTime.sunday => HolidayTheme.national,
        DateTime.saturday => palette.weekend,
        _ => palette.text,
      };
      fill = AppColors.transparent;
    }

    return SizedBox(
      height: 36,
      child: Center(
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
          child: Text(
            '${date.day}',
            style: HolidayTheme.day.copyWith(
              color: foreground.readable(context),
              fontWeight: holiday != null ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _HolidayPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: HolidayTheme.legend.copyWith(color: palette.muted)),
      ],
    );
  }
}

class _HolidayTile extends StatelessWidget {
  const _HolidayTile({required this.holiday});

  final Holiday holiday;

  @override
  Widget build(BuildContext context) {
    final palette = _HolidayPalette.of(context);
    final isCollective = holiday.type == HolidayType.collectiveLeave;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isCollective
        ? HolidayTheme.collective
        : HolidayTheme.national;
    final color = baseColor.readable(context);
    final fill = !dark
        ? baseColor.withValues(alpha: 0.12)
        : isCollective
        ? HolidayTheme.collectiveFill
        : HolidayTheme.nationalFill;
    final badgeFill = !dark
        ? baseColor.withValues(alpha: 0.16)
        : isCollective
        ? HolidayTheme.collectiveBadge
        : HolidayTheme.nationalBadge;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = holiday.date.difference(today).inDays;
    final countdown = days == 0 ? 'Hari ini' : '$days hari lagi';
    final weekday = DateFormat('EEEE', 'id_ID').format(holiday.date);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: HolidayTheme.tileRadius,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 42,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: HolidayTheme.dateRadius,
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${holiday.date.day}',
                  style: HolidayTheme.dateNumber.copyWith(
                    color: color.readable(context),
                  ),
                ),
                Text(
                  DateFormat('MMM', 'id_ID').format(holiday.date),
                  style: HolidayTheme.dateMonth.copyWith(
                    color: color.readable(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HolidayTheme.rowTitle.copyWith(color: palette.text),
                ),
                const SizedBox(height: 2),
                Text(
                  '$weekday · $countdown',
                  style: HolidayTheme.rowCaption.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeFill,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              isCollective ? 'Cuti Bersama' : 'Nasional',
              style: HolidayTheme.badge.copyWith(
                color: color.readable(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHoliday extends StatelessWidget {
  const _EmptyHoliday();

  @override
  Widget build(BuildContext context) {
    final palette = _HolidayPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: HolidayTheme.tileRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, color: palette.muted, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Belum ada libur mendatang.',
            textAlign: TextAlign.center,
            style: HolidayTheme.rowCaption.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}
