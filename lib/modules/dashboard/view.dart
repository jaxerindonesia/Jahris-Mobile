import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/dashboard_theme.dart';
import '../../core/widgets/face_scan_icon.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/module_scaffold.dart';
import 'model.dart';
import 'provider.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardProvider);
    return ModuleScaffold(
      title: context.l10n.navHome,
      currentIndex: 0,
      profileHeader: true,
      showPageHeading: false,
      body: RefreshIndicator(
        onRefresh: ref.read(dashboardProvider.notifier).refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
          children: [
            summary.when(
              loading: () => const _DashboardLoading(),
              error: (_, _) => _DashboardError(
                onRetry: ref.read(dashboardProvider.notifier).refresh,
              ),
              data: (data) => _DashboardContent(
                data: data,
                onOpen: context.push,
                onSubmissionTap: (item) => _openSubmission(context, item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSubmission(BuildContext context, RecentSubmission item) {
    final type = item.type.toLowerCase();
    if (type.contains('reimburse')) {
      context.push('/reimburse/detail/${item.id}');
    } else if (type.contains('check-in')) {
      context.push('/attendance');
    } else {
      context.push('/leave/detail/${item.id}');
    }
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.onOpen,
    required this.onSubmissionTap,
  });

  final DashboardSummary data;
  final ValueChanged<String> onOpen;
  final ValueChanged<RecentSubmission> onSubmissionTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _AttendanceHero(onCheckIn: () => onOpen('/attendance')),
      SizedBox(height: AppSpacing.lg),
      _QuickServices(onOpen: onOpen, onShowAll: () => _showServices(context)),
      SizedBox(height: AppSpacing.sm),
      _HolidayBanner(),
      SizedBox(height: AppSpacing.md),
      _SubmissionHeader(count: data.recentSubmissions.length),
      SizedBox(height: AppSpacing.sm),
      if (data.recentSubmissions.isEmpty)
        const _EmptySubmissions()
      else
        for (final item in data.recentSubmissions) ...[
          _SubmissionTile(item: item, onTap: () => onSubmissionTap(item)),
          const SizedBox(height: AppSpacing.sm),
        ],
    ],
  );

  void _showServices(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      clipBehavior: Clip.antiAlias,
      backgroundColor: isDark ? AppColors.transparent : AppColors.lightSurface,
      barrierColor: AppColors.darkBackground.withValues(alpha: 0.78),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final sheet = _ServicesSheet(
          onOpen: (route) {
            Navigator.of(sheetContext).pop();
            onOpen(route);
          },
        );
        if (!isDark) return sheet;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: DashboardTheme.servicesSheet,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: DashboardTheme.servicesBorder),
            ),
          ),
          child: sheet,
        );
      },
    );
  }
}

class _AttendanceHero extends StatefulWidget {
  const _AttendanceHero({required this.onCheckIn});

  final VoidCallback onCheckIn;

  @override
  State<_AttendanceHero> createState() => _AttendanceHeroState();
}

class _AttendanceHeroState extends State<_AttendanceHero> {
  late final Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.maxWidth,
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 358,
            child: Column(
              children: [
                Text(
                  DateFormat('HH:mm', 'id_ID').format(_now),
                  key: const ValueKey('dashboard-clock'),
                  style: DashboardTheme.clock.copyWith(
                    color: dark ? DashboardTheme.white : DashboardTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_now),
                  style: DashboardTheme.date,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 176,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DashboardTheme.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: dark
                        ? null
                        : Border.all(color: AppColors.lightBorder),
                  ),
                  child: Text(
                    context.l10n.dashboardShift,
                    style: DashboardTheme.shift,
                  ),
                ),
                const SizedBox(height: 32),
                Semantics(
                  button: true,
                  label: context.l10n.dashboardCheckIn,
                  child: SizedBox(
                    width: 152,
                    height: 152,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: -130,
                          top: -130,
                          child: IgnorePointer(
                            child: Container(
                              width: 412,
                              height: 412,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    dark
                                        ? DashboardTheme.glow
                                        : DashboardTheme.glow.withValues(
                                            alpha: 0.12,
                                          ),
                                    AppColors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Material(
                          color: dark
                              ? DashboardTheme.halo
                              : DashboardTheme.green.withValues(alpha: 0.18),
                          borderRadius: DashboardTheme.frameRadius,
                          child: InkWell(
                            onTap: widget.onCheckIn,
                            borderRadius: DashboardTheme.frameRadius,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Ink(
                                width: 132,
                                height: 132,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      DashboardTheme.greenLight,
                                      DashboardTheme.green,
                                    ],
                                  ),
                                  borderRadius: DashboardTheme.buttonRadius,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FaceScanIcon(),
                                    SizedBox(height: 10),
                                    Text(
                                      context.l10n.dashboardCheckIn,
                                      style: DashboardTheme.checkIn,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.dashboardScanHint,
                  style: DashboardTheme.hint,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: DashboardTheme.location.readable(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.dashboardLocation,
                      style: DashboardTheme.locationLabel.copyWith(
                        color: DashboardTheme.location.readable(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const _AttendanceSummary(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceSummary extends StatelessWidget {
  const _AttendanceSummary();

  @override
  Widget build(BuildContext context) {
    final divider = VerticalDivider(
      width: 1,
      color: Theme.of(context).brightness == Brightness.dark
          ? DashboardTheme.divider
          : AppColors.lightBorder,
    );
    return Row(
      children: [
        Expanded(
          child: _AttendanceMetric(
            value: '--:--',
            label: context.l10n.dashboardIn,
          ),
        ),
        SizedBox(height: 34, child: divider),
        Expanded(
          child: _AttendanceMetric(
            value: '--:--',
            label: context.l10n.dashboardOut,
          ),
        ),
        SizedBox(height: 34, child: divider),
        Expanded(
          child: _AttendanceMetric(
            value: '0j 0m',
            label: context.l10n.dashboardTotal,
          ),
        ),
      ],
    );
  }
}

class _AttendanceMetric extends StatelessWidget {
  const _AttendanceMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: DashboardTheme.value.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? DashboardTheme.white
              : DashboardTheme.ink,
        ),
      ),
      const SizedBox(height: 5),
      Text(label, style: DashboardTheme.metricLabel),
    ],
  );
}

class _QuickServices extends StatelessWidget {
  const _QuickServices({required this.onOpen, required this.onShowAll});

  final ValueChanged<String> onOpen;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) => GlassCard(
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? AppColors.servicesSurface
        : null,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.lg,
    ),
    child: Row(
      children: [
        _QuickService(
          iconAsset: 'assets/icons/cuti.svg',
          label: context.l10n.dashboardLeave,
          onTap: () => onOpen('/leave'),
        ),
        _QuickService(
          iconAsset: 'assets/icons/reimbursement.svg',
          label: context.l10n.dashboardReimburse,
          hasBuiltInBackground: true,
          onTap: () => onOpen('/reimburse'),
        ),
        _QuickService(
          iconAsset: 'assets/icons/petty-cash.svg',
          label: context.l10n.dashboardPettyCash,
          hasBuiltInBackground: true,
          onTap: () => onOpen('/pettycash'),
        ),
        _QuickService(
          iconAsset: 'assets/icons/lainnya.svg',
          label: context.l10n.dashboardMore,
          onTap: onShowAll,
        ),
      ],
    ),
  );
}

class _QuickService extends StatelessWidget {
  const _QuickService({
    required this.iconAsset,
    required this.label,
    required this.onTap,
    this.hasBuiltInBackground = false,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;
  final bool hasBuiltInBackground;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: _ServiceIcon(
                asset: iconAsset,
                hasBuiltInBackground: hasBuiltInBackground,
                diameter: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkText
                    : AppColors.lightText,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({
    required this.asset,
    required this.hasBuiltInBackground,
    required this.diameter,
    this.rounded = false,
  });

  final String asset;
  final bool hasBuiltInBackground;
  final double diameter;
  final bool rounded;

  @override
  Widget build(BuildContext context) => Container(
    width: diameter,
    height: diameter,
    alignment: Alignment.center,
    decoration: hasBuiltInBackground
        ? null
        : BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.onPrimary.withValues(alpha: 0.10)
                : AppColors.lightMuted.withValues(alpha: 0.10),
            shape: rounded ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: rounded
                ? BorderRadius.circular(AppRadius.medium)
                : null,
          ),
    child: SvgPicture.asset(
      asset,
      width: hasBuiltInBackground ? diameter : diameter * 26 / 42,
      height: hasBuiltInBackground ? diameter : diameter * 26 / 42,
      colorFilter: ColorFilter.mode(
        Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.lightText,
        BlendMode.srcIn,
      ),
    ),
  );
}

class _SubmissionIconData {
  const _SubmissionIconData(this.asset, {this.hasBuiltInBackground = false});

  final String asset;
  final bool hasBuiltInBackground;
}

_SubmissionIconData _submissionIconFor(String type) {
  final normalized = type.toLowerCase();
  if (normalized.contains('cuti') || normalized.contains('izin')) {
    return const _SubmissionIconData('assets/icons/cuti.svg');
  }
  if (normalized.contains('reimburse')) {
    return const _SubmissionIconData(
      'assets/icons/reimbursement.svg',
      hasBuiltInBackground: true,
    );
  }
  if (normalized.contains('petty') || normalized.contains('cash')) {
    return const _SubmissionIconData(
      'assets/icons/petty-cash.svg',
      hasBuiltInBackground: true,
    );
  }
  if (normalized.contains('check-in') ||
      normalized.contains('check in') ||
      normalized.contains('absen') ||
      normalized.contains('kehadiran')) {
    return const _SubmissionIconData('assets/icons/kehadiran.svg');
  }
  return const _SubmissionIconData('assets/icons/lainnya.svg');
}

class _HolidayBanner extends StatelessWidget {
  const _HolidayBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.highlightSurface
            : AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.card - 4),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.72 : 0.40),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_calendar_outlined,
              color: AppColors.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.compact),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.dashboardNextHoliday('Hari Natal'),
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jumat, 25 Desember 2026 · 53 hari lagi',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
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

class _SubmissionHeader extends StatelessWidget {
  const _SubmissionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        context.l10n.dashboardMyRequests,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      if (count > 0) ...[
        SizedBox(width: AppSpacing.sm),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ],
  );
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({required this.item, required this.onTap});

  final RecentSubmission item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _submissionIconFor(item.type);
    final approved = item.status.toLowerCase().contains('setuju');
    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          _ServiceIcon(
            asset: icon.asset,
            hasBuiltInBackground: icon.hasBuiltInBackground,
            diameter: AppSizes.avatar,
            rounded: true,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (item.detail case final detail?)
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkMuted
                          : AppColors.lightMuted,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.compact,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: (approved ? AppColors.success : AppColors.warning)
                  .softFill(context),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              item.status,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: (approved ? AppColors.success : AppColors.warning)
                    .readable(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySubmissions extends StatelessWidget {
  const _EmptySubmissions();

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        Icon(Icons.inbox_outlined, color: AppColors.info),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            context.l10n.dashboardNoRequests,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}

class _ServiceItem {
  _ServiceItem(this.icon, this.label, this.route, this.color);

  final IconData icon;
  final String label;
  final String route;
  // Dipertahankan untuk kompatibilitas hot reload sesi lama.
  // Tampilan popup sengaja menggunakan warna monokrom.
  final Color color;
}

List<_ServiceItem> _services(BuildContext context) => <_ServiceItem>[
  _ServiceItem(
    Icons.history_outlined,
    context.l10n.serviceAttendanceHistory,
    '/attendance/history',
    AppColors.info,
  ),
  _ServiceItem(
    Icons.calendar_month_outlined,
    context.l10n.serviceShift,
    '/shift-schedule',
    AppColors.primary,
  ),
  _ServiceItem(
    Icons.timer_outlined,
    context.l10n.serviceOvertime,
    '/overtimes',
    AppColors.warning,
  ),
  _ServiceItem(
    Icons.edit_calendar_outlined,
    context.l10n.dashboardLeave,
    '/leave',
    AppColors.info,
  ),
  _ServiceItem(
    Icons.monetization_on_outlined,
    context.l10n.dashboardReimburse,
    '/reimburse',
    AppColors.purple,
  ),
  _ServiceItem(
    Icons.account_balance_wallet_outlined,
    context.l10n.dashboardPettyCash,
    '/pettycash',
    AppColors.success,
  ),
  _ServiceItem(
    Icons.description_outlined,
    context.l10n.servicePayslip,
    '/payroll',
    AppColors.primary,
  ),
  _ServiceItem(
    Icons.event_available_outlined,
    context.l10n.serviceHoliday,
    '/holiday',
    AppColors.info,
  ),
  _ServiceItem(
    Icons.help_outline_rounded,
    context.l10n.serviceHelp,
    '/bantuan',
    AppColors.purple,
  ),
];

class _ServicesSheet extends StatefulWidget {
  const _ServicesSheet({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  State<_ServicesSheet> createState() => _ServicesSheetState();
}

class _ServicesSheetState extends State<_ServicesSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _services(context)
        .where(
          (item) => item.label.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList(growable: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final borderColor = isDark
        ? DashboardTheme.servicesBorder
        : AppColors.lightBorder;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.compact),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? DashboardTheme.servicesHandle
                  : AppColors.lightBorder,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.servicesTitle,
            style: textTheme.bodyMedium!
                .merge(DashboardTheme.servicesTitle)
                .copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            style: textTheme.bodyMedium!.copyWith(
              fontSize: 14,
              color: textColor,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: context.l10n.servicesSearch,
              hintStyle: textTheme.bodyMedium!.copyWith(
                fontSize: 14,
                color: mutedColor,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: AppSizes.iconSmall,
                color: mutedColor,
              ),
              filled: true,
              fillColor: isDark
                  ? DashboardTheme.servicesSearchFill
                  : AppColors.lightSurface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.compact,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: DashboardTheme.servicesRadius,
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: DashboardTheme.servicesRadius,
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                context.l10n.servicesEmpty,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.compact,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? DashboardTheme.servicesGridFill
                    : AppColors.lightSurface,
                borderRadius: DashboardTheme.servicesRadius,
                border: Border.all(color: borderColor),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisExtent: 76,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.compact,
                ),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  assert(item.color != AppColors.transparent);
                  return InkWell(
                    onTap: () => widget.onOpen(item.route),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? DashboardTheme.servicesIconFill
                                : AppColors.lightMuted.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, color: textColor, size: 20),
                        ),
                        const SizedBox(height: AppSpacing.sm - 2),
                        Text(
                          item.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall!
                              .merge(DashboardTheme.servicesLabel)
                              .copyWith(color: textColor),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 480,
    child: Center(child: CircularProgressIndicator()),
  );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 420,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: AppSizes.iconLarge,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.dashboardSummaryError,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    ),
  );
}
