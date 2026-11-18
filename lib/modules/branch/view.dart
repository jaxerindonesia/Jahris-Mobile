import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/shift_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/list_states.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import 'model.dart';
import 'provider.dart';

class ShiftScheduleView extends ConsumerWidget {
  const ShiftScheduleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(shiftScheduleProvider);
    return ModuleScaffold(
      title: 'Jadwal Shift',
      showAppHeader: false,
      showPageHeading: false,
      body: schedule.when(
        loading: () => const ListLoading(itemCount: 5),
        error: (error, _) => ListError(
          message: networkErrorMessage(
            error,
            fallback: 'Jadwal shift gagal dimuat.',
          ),
          onRetry: () => ref.invalidate(shiftScheduleProvider),
        ),
        data: (data) => data.branch.workingSchedules.isEmpty
            ? ListEmpty(
                message: 'Jadwal kerja cabang belum diatur.',
                onRefresh: ref.read(shiftScheduleProvider.notifier).refresh,
              )
            : _ShiftScheduleContent(data: data),
      ),
    );
  }
}

class _ShiftScheduleContent extends ConsumerWidget {
  const _ShiftScheduleContent({required this.data});

  final ShiftScheduleState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(shiftScheduleProvider.notifier);
    final palette = _ShiftPalette.of(context);
    final otherDates = data.weekDates
        .where((date) => !_sameDate(date, data.selectedDate))
        .toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.background),
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.xl,
          ),
          children: [
            _ShiftHeader(
              onPreviousWeek: controller.previousWeek,
              onNextWeek: controller.nextWeek,
            ),
            const SizedBox(height: AppSpacing.md),
            _WeekPicker(
              dates: data.weekDates,
              selectedDate: data.selectedDate,
              hasShift: (date) => data.scheduleFor(date)?.isWorkDay == true,
              onSelected: controller.selectDate,
            ),
            const SizedBox(height: AppSpacing.md),
            _SelectedShiftCard(
              date: data.selectedDate,
              branch: data.branch,
              schedule: data.scheduleFor(data.selectedDate),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Minggu ini',
              style: ShiftTheme.section.copyWith(color: palette.text),
            ),
            const SizedBox(height: AppSpacing.compact),
            for (final date in otherDates) ...[
              _ShiftDayTile(
                date: date,
                schedule: data.scheduleFor(date),
                onTap: () => controller.selectDate(date),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.compact),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.text,
                  side: BorderSide(color: palette.buttonBorder),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Pengajuan tukar shift belum tersedia pada API.',
                    ),
                  ),
                ),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: Text(
                  'Ajukan Tukar Shift',
                  style: ShiftTheme.button.copyWith(color: palette.text),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftPalette {
  const _ShiftPalette({
    required this.background,
    required this.text,
    required this.muted,
    required this.surface,
    required this.border,
    required this.headerButton,
    required this.headerButtonBorder,
    required this.tile,
    required this.tileBorder,
    required this.buttonBorder,
    required this.heroGradient,
    required this.heroBorder,
    required this.heroBadge,
    required this.heroBadgeText,
    required this.heroTitle,
    required this.heroTime,
    required this.heroMeta,
    required this.heroIconFill,
    required this.sun,
    required this.location,
  });

  factory _ShiftPalette.of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  static const _dark = _ShiftPalette(
    background: ShiftTheme.background,
    text: ShiftTheme.white,
    muted: ShiftTheme.muted,
    surface: ShiftTheme.surface,
    border: ShiftTheme.border,
    headerButton: ShiftTheme.surface,
    headerButtonBorder: ShiftTheme.border,
    tile: ShiftTheme.surface,
    tileBorder: ShiftTheme.border,
    buttonBorder: ShiftTheme.border,
    heroGradient: ShiftTheme.heroGradient,
    heroBorder: ShiftTheme.heroBorder,
    heroBadge: ShiftTheme.heroBadge,
    heroBadgeText: ShiftTheme.heroBadgeText,
    heroTitle: ShiftTheme.white,
    heroTime: ShiftTheme.heroTimeColor,
    heroMeta: ShiftTheme.heroBadgeText,
    heroIconFill: ShiftTheme.heroIconFill,
    sun: ShiftTheme.sun,
    location: ShiftTheme.location,
  );

  static const _light = _ShiftPalette(
    background: ShiftTheme.lightBackground,
    text: ShiftTheme.lightText,
    muted: ShiftTheme.lightMuted,
    surface: ShiftTheme.lightChip,
    border: ShiftTheme.lightChipBorder,
    headerButton: ShiftTheme.lightHeaderButton,
    headerButtonBorder: ShiftTheme.lightHeaderButton,
    tile: ShiftTheme.lightTile,
    tileBorder: ShiftTheme.lightTileBorder,
    buttonBorder: ShiftTheme.lightButtonBorder,
    heroGradient: ShiftTheme.lightHeroGradient,
    heroBorder: ShiftTheme.lightHeroBorder,
    heroBadge: ShiftTheme.lightHeroBadge,
    heroBadgeText: ShiftTheme.lightHeroBadgeText,
    heroTitle: ShiftTheme.lightText,
    heroTime: ShiftTheme.lightText,
    heroMeta: ShiftTheme.lightHeroMeta,
    heroIconFill: ShiftTheme.lightHeroIconFill,
    sun: ShiftTheme.lightSun,
    location: ShiftTheme.lightLocation,
  );

  final Gradient background;
  final Color text;
  final Color muted;
  final Color surface;
  final Color border;
  final Color headerButton;
  final Color headerButtonBorder;
  final Color tile;
  final Color tileBorder;
  final Color buttonBorder;
  final Gradient heroGradient;
  final Color heroBorder;
  final Color heroBadge;
  final Color heroBadgeText;
  final Color heroTitle;
  final Color heroTime;
  final Color heroMeta;
  final Color heroIconFill;
  final Color sun;
  final Color location;
}

class _ShiftHeader extends StatelessWidget {
  const _ShiftHeader({required this.onPreviousWeek, required this.onNextWeek});

  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) {
    final palette = _ShiftPalette.of(context);
    return Row(
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
                dimension: ShiftTheme.headerButton,
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
            'Jadwal Shift',
            textAlign: TextAlign.center,
            style: ShiftTheme.title.copyWith(color: palette.text),
          ),
        ),
        Material(
          color: palette.headerButton,
          shape: RoundedRectangleBorder(
            borderRadius: ShiftTheme.squareButtonRadius,
            side: BorderSide(color: palette.headerButtonBorder),
          ),
          child: PopupMenuButton<String>(
            tooltip: 'Pilih minggu',
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: palette.text,
            ),
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              minimumSize: const Size.square(ShiftTheme.headerButton),
              fixedSize: const Size.square(ShiftTheme.headerButton),
            ),
            onSelected: (value) =>
                value == 'previous' ? onPreviousWeek() : onNextWeek(),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'previous',
                child: Text('Minggu sebelumnya'),
              ),
              PopupMenuItem(value: 'next', child: Text('Minggu berikutnya')),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekPicker extends StatelessWidget {
  const _WeekPicker({
    required this.dates,
    required this.selectedDate,
    required this.hasShift,
    required this.onSelected,
  });

  final List<DateTime> dates;
  final DateTime selectedDate;
  final bool Function(DateTime date) hasShift;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < dates.length; index++) ...[
        if (index > 0) const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _DateChip(
            date: dates[index],
            selected: _sameDate(dates[index], selectedDate),
            hasShift: hasShift(dates[index]),
            onTap: () => onSelected(dates[index]),
          ),
        ),
      ],
    ],
  );
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.hasShift,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool hasShift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _ShiftPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: DateFormat('EEEE, d MMMM', 'id_ID').format(date),
      child: InkWell(
        onTap: onTap,
        borderRadius: ShiftTheme.chipRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: ShiftTheme.chipHeight,
          decoration: BoxDecoration(
            color: selected ? ShiftTheme.primary : palette.surface,
            borderRadius: ShiftTheme.chipRadius,
            border: Border.all(
              color: selected ? ShiftTheme.primary : palette.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('E', 'id_ID').format(date).substring(0, 3),
                style: ShiftTheme.weekday.copyWith(
                  color: selected ? ShiftTheme.white : palette.muted,
                ),
              ),
              Text(
                '${date.day}',
                style: ShiftTheme.day.copyWith(
                  color: selected ? ShiftTheme.white : palette.text,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: !hasShift
                      ? Colors.transparent
                      : selected
                      ? ShiftTheme.white
                      : ShiftTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedShiftCard extends StatelessWidget {
  const _SelectedShiftCard({
    required this.date,
    required this.branch,
    required this.schedule,
  });

  final DateTime date;
  final Branch branch;
  final WorkingSchedule? schedule;

  @override
  Widget build(BuildContext context) {
    final works = schedule?.isWorkDay == true;
    final breakStart = schedule?.breakStart;
    final breakEnd = schedule?.breakEnd;
    final palette = _ShiftPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: ShiftTheme.cardRadius,
        border: Border.fromBorderSide(BorderSide(color: palette.heroBorder)),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.compact,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: palette.heroBadge,
                        borderRadius: ShiftTheme.pillRadius,
                      ),
                      child: Text(
                        _sameDate(date, DateTime.now())
                            ? 'Hari ini'
                            : DateFormat('EEEE, d MMM', 'id_ID').format(date),
                        style: ShiftTheme.badge.copyWith(
                          color: palette.heroBadgeText,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.compact),
                    Text(
                      works ? _shiftName(schedule) : 'Libur',
                      style: ShiftTheme.heroTitle.copyWith(
                        color: palette.heroTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      works ? _timeRange(schedule) : 'Tidak ada jadwal kerja',
                      style: ShiftTheme.heroTime.copyWith(
                        color: palette.heroTime,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.heroIconFill,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  works ? _shiftIcon(schedule) : Icons.weekend_outlined,
                  color: works ? palette.sun : palette.muted,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              _HeroMeta(icon: Icons.location_on_outlined, label: branch.name),
              if (works && breakStart != null && breakEnd != null)
                _HeroMeta(
                  icon: Icons.coffee_outlined,
                  label: 'Istirahat $breakStart–$breakEnd',
                )
              else
                _HeroMeta(
                  icon: Icons.schedule_rounded,
                  label: branch.scheduleType == 'SHIFT'
                      ? 'Shifting'
                      : 'Reguler',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _ShiftPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: palette.location),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: ShiftTheme.heroMeta.copyWith(color: palette.heroMeta),
        ),
      ],
    );
  }
}

class _ShiftDayTile extends StatelessWidget {
  const _ShiftDayTile({
    required this.date,
    required this.schedule,
    required this.onTap,
  });

  final DateTime date;
  final WorkingSchedule? schedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _ShiftPalette.of(context);
    final works = schedule?.isWorkDay == true;
    final accent = works ? _shiftColor(schedule) : ShiftTheme.off;
    return Opacity(
      opacity: works ? 1 : 0.6,
      child: Material(
        color: palette.tile,
        shape: RoundedRectangleBorder(
          borderRadius: ShiftTheme.tileRadius,
          side: BorderSide(color: palette.tileBorder),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const RoundedRectangleBorder(
            borderRadius: ShiftTheme.tileRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.compact,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: ShiftTheme.pillRadius,
                  ),
                ),
                const SizedBox(width: AppSpacing.compact),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        works ? _shiftName(schedule) : 'Libur',
                        style: ShiftTheme.tileTitle.copyWith(
                          color: works ? palette.text : palette.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('E, d MMM', 'id_ID').format(date),
                        style: ShiftTheme.tileDate.copyWith(
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  works ? _timeRange(schedule) : '—',
                  style: ShiftTheme.tileTime.copyWith(
                    color: works ? palette.text : palette.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _sameDate(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _timeRange(WorkingSchedule? schedule) =>
    '${schedule?.startTime ?? '--:--'} – ${schedule?.endTime ?? '--:--'}';

int _startHour(WorkingSchedule? schedule) =>
    int.tryParse(schedule?.startTime?.split(':').first ?? '') ?? 0;

String _shiftName(WorkingSchedule? schedule) {
  final hour = _startHour(schedule);
  if (hour < 12) return 'Shift Pagi';
  if (hour < 18) return 'Shift Siang';
  return 'Shift Malam';
}

IconData _shiftIcon(WorkingSchedule? schedule) {
  final hour = _startHour(schedule);
  if (hour < 18) return Icons.wb_sunny_outlined;
  return Icons.nightlight_outlined;
}

Color _shiftColor(WorkingSchedule? schedule) {
  final hour = _startHour(schedule);
  if (hour < 12) return ShiftTheme.morning;
  if (hour < 18) return ShiftTheme.afternoon;
  return ShiftTheme.night;
}

// TODO-DESIGN: Stitch belum memiliki screen Cabang; UI mengikuti Dashboard.
class BranchView extends ConsumerWidget {
  const BranchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(branchProvider);
    return ModuleScaffold(
      title: 'Cabang',
      subtitle: 'Kelola lokasi dan radius kehadiran.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: value.when(
        loading: () => const ListLoading(),
        error: (error, _) => ListError(
          message: networkErrorMessage(
            error,
            fallback: 'Data cabang gagal dimuat.',
          ),
          onRetry: () => ref.invalidate(branchProvider),
        ),
        data: (data) => _BranchContent(data: data),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, [Branch? current]) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _BranchForm(current: current),
      );
}

class _BranchContent extends ConsumerWidget {
  const _BranchContent({required this.data});
  final BranchState data;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(branchProvider.notifier);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
        children: [
          TextField(
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              labelText: 'Cari nama atau kode cabang',
            ),
            onSubmitted: controller.search,
          ),
          const SizedBox(height: AppSpacing.md),
          if (data.message case final message?) ...[
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (data.items.isEmpty)
            const GlassCard(
              child: Center(child: Text('Cabang tidak ditemukan.')),
            )
          else ...[
            for (final item in data.items) ...[
              _BranchCard(item: item),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              'Menampilkan ${data.items.length} dari ${data.total} data • Halaman ${data.page}',
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

class _BranchCard extends ConsumerWidget {
  const _BranchCard({required this.item});
  final Branch item;
  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            StatusChip(label: item.code, color: AppColors.primary),
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'edit') {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    showDragHandle: true,
                    builder: (_) => _BranchForm(current: item),
                  );
                }
                if (action == 'delete') {
                  _delete(context, ref);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Ubah')),
                PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(item.address),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.primary),
                Text(
                  '${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(Icons.radar_rounded, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Text('Radius ${item.radiusMeters.round()} meter'),
          ],
        ),
      ],
    ),
  );

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus cabang?'),
        content: Text('Cabang ${item.name} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(branchProvider.notifier).delete(item.id);
  }
}

class _BranchForm extends ConsumerStatefulWidget {
  const _BranchForm({this.current});
  final Branch? current;

  @override
  ConsumerState<_BranchForm> createState() => _BranchFormState();
}

class _BranchFormState extends ConsumerState<_BranchForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late double _radius;

  Branch? get current => widget.current;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: current?.name ?? '');
    _codeController = TextEditingController(text: current?.code ?? '');
    _addressController = TextEditingController(text: current?.address ?? '');
    _latitudeController = TextEditingController(
      text: current == null ? '' : current!.latitude.toStringAsFixed(6),
    );
    _longitudeController = TextEditingController(
      text: current == null ? '' : current!.longitude.toStringAsFixed(6),
    );
    _radius = current?.radiusMeters ?? 100;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  double? _coordinate(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String? _validateCoordinate(
    String? value, {
    required double min,
    required double max,
    required String label,
  }) {
    final number = _coordinate(value ?? '');
    if (number == null) return '$label wajib berupa angka.';
    if (number < min || number > max) {
      return '$label harus antara $min dan $max.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final branchState = ref.watch(branchProvider).value;
    final isLocating = branchState?.isLocating ?? false;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              current == null ? 'Tambah Cabang' : 'Ubah Cabang',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama cabang'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama cabang wajib diisi.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Kode'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Kode cabang wajib diisi.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _addressController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Alamat'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Alamat cabang wajib diisi.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    validator: (value) => _validateCoordinate(
                      value,
                      min: -90,
                      max: 90,
                      label: 'Latitude',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    validator: (value) => _validateCoordinate(
                      value,
                      min: -180,
                      max: 180,
                      label: 'Longitude',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: isLocating ? null : _useCurrentLocation,
              icon: isLocating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                isLocating ? 'Mengambil lokasi...' : 'Gunakan Lokasi Saat Ini',
              ),
            ),
            if (branchState?.message case final message?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text('Radius: ${_radius.round()} meter'),
            Slider(
              value: _radius.clamp(25, 500),
              min: 25,
              max: 500,
              divisions: 19,
              label: '${_radius.round()} m',
              onChanged: (value) => setState(() => _radius = value),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Simpan Cabang',
              icon: Icons.save_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    FocusScope.of(context).unfocus();
    final position = await ref
        .read(branchProvider.notifier)
        .useCurrentLocation();
    if (position == null || !mounted) return;
    _latitudeController.text = position.$1.toStringAsFixed(6);
    _longitudeController.text = position.$2.toStringAsFixed(6);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(branchProvider.notifier)
        .save(
          Branch(
            id: current?.id ?? '',
            name: _nameController.text.trim(),
            code: _codeController.text.trim().toUpperCase(),
            address: _addressController.text.trim(),
            latitude: _coordinate(_latitudeController.text)!,
            longitude: _coordinate(_longitudeController.text)!,
            radiusMeters: _radius,
          ),
        );
    if (ok && mounted) Navigator.pop(context);
  }
}
