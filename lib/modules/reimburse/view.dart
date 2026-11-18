import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/reimburse_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/list_states.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/status_chip.dart';
import '../auth/provider.dart';
import 'model.dart';
import 'provider.dart';

class ReimburseView extends ConsumerWidget {
  const ReimburseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(reimburseProvider);
    final filteredItems = ref.watch(filteredReimbursementsProvider);
    final palette = _ReimbursePalette.of(context);
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
                child: _ReimburseHeader(),
              ),
              Expanded(
                child: value.when(
                  loading: () => const ListLoading(),
                  error: (error, _) => ListError(
                    message: networkErrorMessage(
                      error,
                      fallback: 'Data reimburse gagal dimuat.',
                    ),
                    onRetry: () => ref.invalidate(reimburseProvider),
                  ),
                  data: (data) => _ReimburseContent(
                    data: data,
                    visibleItems: filteredItems,
                  ),
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
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ReimburseTheme.primary,
                      foregroundColor: ReimburseTheme.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: AppColors.transparent,
                      builder: (_) => const _ReimburseForm(),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      'Ajukan Reimburse',
                      style: ReimburseTheme.button,
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

class _ReimbursePalette {
  const _ReimbursePalette({
    required this.scaffold,
    required this.background,
    required this.text,
    required this.surface,
    required this.border,
  });

  factory _ReimbursePalette.of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const _ReimbursePalette(
          scaffold: AppColors.darkBackground,
          background: ReimburseTheme.background,
          text: ReimburseTheme.white,
          surface: ReimburseTheme.surface,
          border: ReimburseTheme.border,
        )
      : const _ReimbursePalette(
          scaffold: AppColors.lightBackground,
          background: null,
          text: AppColors.lightText,
          surface: AppColors.lightSurface,
          border: AppColors.lightBorder,
        );

  final Color scaffold;
  final Gradient? background;
  final Color text;
  final Color surface;
  final Color border;
}

class _ReimburseHeader extends StatelessWidget {
  const _ReimburseHeader();

  @override
  Widget build(BuildContext context) {
    final palette = _ReimbursePalette.of(context);
    return Row(
      children: [
        Tooltip(
          message: 'Kembali',
          child: Material(
            color: palette.surface,
            shape: CircleBorder(side: BorderSide(color: palette.border)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/dashboard'),
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
            'Reimburse',
            textAlign: TextAlign.center,
            style: ReimburseTheme.title.copyWith(color: palette.text),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}

class _ReimburseContent extends ConsumerWidget {
  const _ReimburseContent({required this.data, required this.visibleItems});

  final ReimburseState data;
  final List<Reimbursement> visibleItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(reimburseProvider.notifier);
    final palette = _ReimbursePalette.of(context);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              Expanded(
                child: _Summary(
                  icon: Icons.check_rounded,
                  label: 'Disetujui',
                  amount: data.summary.approved,
                  color: ReimburseTheme.approved,
                ),
              ),
              const SizedBox(width: AppSpacing.compact),
              Expanded(
                child: _Summary(
                  icon: Icons.schedule_rounded,
                  label: 'Menunggu',
                  amount: data.summary.pending,
                  color: ReimburseTheme.pending,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _CategoryFilters(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Riwayat Pengajuan',
            style: ReimburseTheme.section.copyWith(color: palette.text),
          ),
          const SizedBox(height: AppSpacing.compact),
          if (data.message case final message?) ...[
            Text(
              message,
              textAlign: TextAlign.center,
              style: ReimburseTheme.rowDate,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (visibleItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'Belum ada klaim reimburse.',
                textAlign: TextAlign.center,
                style: ReimburseTheme.rowDate,
              ),
            )
          else ...[
            for (final item in visibleItems) ...[
              _ReimburseCard(item: item),
              const SizedBox(height: AppSpacing.sm + 2),
            ],
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

class _CategoryFilters extends ConsumerWidget {
  const _CategoryFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reimburseCategoryFilterProvider);
    final palette = _ReimbursePalette.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in const [
            'Semua',
            'Transport',
            'Makan',
            'Kesehatan',
          ]) ...[
            Material(
              color: selected == category
                  ? ReimburseTheme.primary
                  : palette.surface,
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected == category
                      ? ReimburseTheme.primary
                      : palette.border,
                ),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => ref
                    .read(reimburseCategoryFilterProvider.notifier)
                    .select(category),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    category,
                    style: ReimburseTheme.chip.copyWith(
                      color: selected == category
                          ? ReimburseTheme.white
                          : palette.text.withValues(alpha: 0.8),
                      fontWeight: selected == category
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = _ReimbursePalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: dark ? ReimburseTheme.summaryGradient : null,
        color: dark ? null : palette.surface,
        borderRadius: ReimburseTheme.cardRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: const BorderRadius.all(Radius.circular(7)),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: ReimburseTheme.summaryLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.compact),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppFormatters.rupiah(amount),
              maxLines: 1,
              style: ReimburseTheme.summaryValue.copyWith(
                color: color.readable(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReimburseCard extends StatelessWidget {
  const _ReimburseCard({required this.item});

  final Reimbursement item;

  @override
  Widget build(BuildContext context) {
    final palette = _ReimbursePalette.of(context);
    final statusColor = _statusColor(item.status);
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: ReimburseTheme.cardRadius,
        side: BorderSide(color: palette.border),
      ),
      child: InkWell(
        onTap: () => context.push('/reimburse/detail/${item.id}'),
        customBorder: const RoundedRectangleBorder(
          borderRadius: ReimburseTheme.cardRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.compact),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? ReimburseTheme.iconFill
                      : ReimburseTheme.primary.withValues(alpha: 0.1),
                  borderRadius: ReimburseTheme.iconRadius,
                ),
                child: Icon(
                  _categoryIcon(item.category, item.description),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? ReimburseTheme.icon
                      : ReimburseTheme.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: AppSpacing.compact),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ReimburseTheme.rowTitle.copyWith(
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM yyyy', 'id_ID').format(item.date),
                      style: ReimburseTheme.rowDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.rupiah(item.amount),
                    style: ReimburseTheme.amount.copyWith(color: palette.text),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.16),
                      borderRadius: ReimburseTheme.pillRadius,
                    ),
                    child: Text(
                      item.status,
                      style: ReimburseTheme.status.copyWith(
                        color: statusColor.readable(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final value = status.toLowerCase();
    if (value.contains('setuju') || value.contains('bayar')) {
      return ReimburseTheme.approved;
    }
    if (value.contains('tolak')) return ReimburseTheme.rejected;
    if (value.contains('tunggu')) return ReimburseTheme.pending;
    return ReimburseTheme.muted;
  }

  IconData _categoryIcon(String category, String description) {
    final value = '$category $description'.toLowerCase();
    if (value.contains('transport') ||
        value.contains('parkir') ||
        value.contains('tol')) {
      return Icons.directions_car_outlined;
    }
    if (value.contains('konsumsi') || value.contains('makan')) {
      return Icons.local_cafe_outlined;
    }
    if (value.contains('kesehatan') ||
        value.contains('obat') ||
        value.contains('klinik')) {
      return Icons.add_box_outlined;
    }
    return Icons.receipt_long_outlined;
  }
}

class ReimburseDetailView extends ConsumerWidget {
  const ReimburseDetailView({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(reimburseDetailProvider(id));
    final role = ref.watch(authProvider).user?.role.toLowerCase() ?? '';
    final canApprove =
        role.contains('admin') ||
        role.contains('atasan') ||
        role.contains('manager');
    return ModuleScaffold(
      title: 'Detail Reimburse',
      body: value.when(
        loading: () => const ListLoading(itemCount: 2),
        error: (error, _) => ListError(
          message: networkErrorMessage(
            error,
            fallback: 'Detail reimburse gagal dimuat.',
          ),
          onRetry: () => ref.invalidate(reimburseDetailProvider(id)),
        ),
        data: (item) => ListView(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.category,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      StatusChip(label: item.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Detail(label: 'Karyawan', value: item.employeeName),
                  _Detail(
                    label: 'Nominal',
                    value: AppFormatters.rupiah(item.amount),
                  ),
                  _Detail(
                    label: 'Tanggal',
                    value: AppFormatters.date(item.date),
                  ),
                  _Detail(label: 'Keterangan', value: item.description),
                  if (item.receiptPath != null)
                    _Detail(
                      label: 'Foto struk',
                      value: item.receiptPath!.split(RegExp(r'[/\\]')).last,
                    ),
                  if (item.approvalNote != null)
                    _Detail(label: 'Catatan', value: item.approvalNote!),
                ],
              ),
            ),
            if (canApprove && item.status == 'Menunggu') ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _decide(context, ref, item, false),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _decide(context, ref, item, true),
                      child: const Text('Setujui'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    Reimbursement item,
    bool approve,
  ) async {
    var note = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Setujui reimburse?' : 'Tolak reimburse?'),
        content: TextField(
          onChanged: (value) => note = value,
          decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(approve ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(reimburseProvider.notifier)
          .decide(item.id, approve: approve, note: note.trim());
    }
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(value),
      ],
    ),
  );
}

class _FormPalette {
  const _FormPalette({
    required this.sheet,
    required this.field,
    required this.fieldBorder,
    required this.handle,
    required this.text,
    required this.muted,
    required this.iconFill,
  });

  factory _FormPalette.of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const _FormPalette(
          sheet: ReimburseTheme.sheet,
          field: ReimburseTheme.sheetField,
          fieldBorder: ReimburseTheme.sheetFieldBorder,
          handle: ReimburseTheme.sheetHandle,
          text: ReimburseTheme.white,
          muted: ReimburseTheme.muted,
          iconFill: ReimburseTheme.iconFill,
        )
      : const _FormPalette(
          sheet: ReimburseTheme.lightSheet,
          field: ReimburseTheme.lightSheetField,
          fieldBorder: ReimburseTheme.lightSheetFieldBorder,
          handle: ReimburseTheme.lightSheetHandle,
          text: AppColors.lightText,
          muted: AppColors.lightMuted,
          iconFill: ReimburseTheme.lightIconFill,
        );

  final Color sheet;
  final Color field;
  final Color fieldBorder;
  final Color handle;
  final Color text;
  final Color muted;
  final Color iconFill;
}

class _ReimburseForm extends ConsumerStatefulWidget {
  const _ReimburseForm();

  @override
  ConsumerState<_ReimburseForm> createState() => _ReimburseFormState();
}

class _ReimburseFormState extends ConsumerState<_ReimburseForm> {
  static const _categories = <(String, IconData)>[
    ('Transportasi', Icons.directions_car_rounded),
    ('Konsumsi', Icons.restaurant_rounded),
    ('Akomodasi', Icons.hotel_rounded),
    ('Operasional', Icons.work_outline_rounded),
    ('Lainnya', Icons.more_horiz_rounded),
  ];

  String _category = _categories.first.$1;
  int _amount = 0;
  DateTime _date = DateTime.now();
  String _description = '';
  String? _receiptPath;
  bool _submitting = false;

  bool get _isValid =>
      _amount > 0 && _description.trim().length >= 5 && _receiptPath != null;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickReceipt() async {
    final palette = _FormPalette.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: palette.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: ReimburseTheme.sheetRadius,
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_camera_rounded,
                  label: 'Kamera',
                  palette: palette,
                  onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
              ),
              const SizedBox(width: AppSpacing.compact),
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  palette: palette,
                  onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    final photo = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );
    if (photo != null && mounted) setState(() => _receiptPath = photo.path);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await ref
        .read(reimburseProvider.notifier)
        .submit(
          category: _category,
          amount: _amount,
          date: _date,
          description: _description,
          receiptPath: _receiptPath,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _FormPalette.of(context);
    final receiptName = _receiptPath?.split(RegExp(r'[/\\]')).last;
    return Container(
      decoration: BoxDecoration(
        color: palette.sheet,
        borderRadius: ReimburseTheme.sheetRadius,
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.compact,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.handle,
                    borderRadius: ReimburseTheme.pillRadius,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajukan Reimburse',
                          style: ReimburseTheme.sheetTitle.copyWith(
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lengkapi data pengeluaran Anda',
                          style: ReimburseTheme.sheetSubtitle.copyWith(
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Tutup',
                    style: IconButton.styleFrom(
                      backgroundColor: palette.field,
                      foregroundColor: palette.text,
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _FieldLabel('Kategori', palette: palette),
              SizedBox(
                height: 40,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: const {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.invertedStylus,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: ListView.separated(
                    key: const ValueKey('reimburse-category-list'),
                    primary: false,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final (label, icon) = _categories[index];
                      final selected = label == _category;
                      return ChoiceChip(
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _category = label),
                        avatar: Icon(
                          icon,
                          size: 16,
                          color: selected
                              ? ReimburseTheme.white
                              : palette.muted,
                        ),
                        label: Text(label),
                        labelStyle: ReimburseTheme.chip.copyWith(
                          color: selected ? ReimburseTheme.white : palette.text,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        backgroundColor: palette.field,
                        selectedColor: ReimburseTheme.primary,
                        side: BorderSide(
                          color: selected
                              ? ReimburseTheme.primary
                              : palette.fieldBorder,
                        ),
                        shape: const StadiumBorder(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _FieldLabel('Nominal', palette: palette),
              _FieldBox(
                palette: palette,
                child: Row(
                  children: [
                    Text(
                      'Rp',
                      style: ReimburseTheme.amountInput.copyWith(
                        color: palette.muted,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [_ThousandsFormatter()],
                        style: ReimburseTheme.amountInput.copyWith(
                          color: palette.text,
                        ),
                        cursorColor: ReimburseTheme.primary,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: '0',
                          hintStyle: ReimburseTheme.amountInput.copyWith(
                            color: palette.muted.withValues(alpha: 0.5),
                          ),
                        ),
                        onChanged: (value) => setState(
                          () => _amount =
                              int.tryParse(
                                value.replaceAll(RegExp(r'[^0-9]'), ''),
                              ) ??
                              0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _FieldLabel('Tanggal', palette: palette),
              _TapTile(
                palette: palette,
                icon: Icons.calendar_month_rounded,
                title: DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_date),
                trailing: Icons.chevron_right_rounded,
                onTap: _pickDate,
              ),
              const SizedBox(height: AppSpacing.md),
              _FieldLabel('Keterangan', palette: palette),
              _FieldBox(
                palette: palette,
                child: TextField(
                  minLines: 3,
                  maxLines: 5,
                  style: ReimburseTheme.fieldValue.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: ReimburseTheme.primary,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Contoh: Taksi ke kantor klien PT ABC',
                    hintStyle: ReimburseTheme.fieldHint.copyWith(
                      color: palette.muted,
                      fontSize: 14,
                    ),
                  ),
                  onChanged: (value) => setState(() => _description = value),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _FieldLabel('Bukti / Foto struk', palette: palette),
              _TapTile(
                palette: palette,
                icon: receiptName == null
                    ? Icons.add_a_photo_rounded
                    : Icons.check_circle_rounded,
                iconColor: receiptName == null ? null : ReimburseTheme.approved,
                title: receiptName ?? 'Unggah foto struk',
                subtitle: receiptName == null
                    ? 'Ambil dari kamera atau galeri'
                    : 'Ketuk untuk mengganti',
                trailing: receiptName == null
                    ? Icons.upload_rounded
                    : Icons.edit_rounded,
                onTap: _pickReceipt,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ReimburseTheme.primary,
                    foregroundColor: ReimburseTheme.white,
                    disabledBackgroundColor: ReimburseTheme.primary.withValues(
                      alpha: 0.35,
                    ),
                    disabledForegroundColor: ReimburseTheme.white.withValues(
                      alpha: 0.7,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _isValid && !_submitting ? _submit : null,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ReimburseTheme.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _submitting ? 'Mengirim...' : 'Kirim Pengajuan',
                    style: ReimburseTheme.button,
                  ),
                ),
              ),
              if (!_isValid) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Isi nominal, keterangan (min. 5 huruf), dan foto struk.',
                  textAlign: TextAlign.center,
                  style: ReimburseTheme.fieldHint.copyWith(
                    color: palette.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.palette});

  final String text;
  final _FormPalette palette;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text,
      style: ReimburseTheme.fieldLabel.copyWith(color: palette.muted),
    ),
  );
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.palette, required this.child});

  final _FormPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
    decoration: BoxDecoration(
      color: palette.field,
      borderRadius: ReimburseTheme.fieldRadius,
      border: Border.all(color: palette.fieldBorder),
    ),
    child: child,
  );
}

class _TapTile extends StatelessWidget {
  const _TapTile({
    required this.palette,
    required this.icon,
    required this.title,
    required this.trailing,
    required this.onTap,
    this.subtitle,
    this.iconColor,
  });

  final _FormPalette palette;
  final IconData icon;
  final String title;
  final String? subtitle;
  final IconData trailing;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: palette.field,
    shape: RoundedRectangleBorder(
      borderRadius: ReimburseTheme.fieldRadius,
      side: BorderSide(color: palette.fieldBorder),
    ),
    child: InkWell(
      customBorder: const RoundedRectangleBorder(
        borderRadius: ReimburseTheme.fieldRadius,
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.compact),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.iconFill,
                borderRadius: ReimburseTheme.iconRadius,
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? ReimburseTheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.compact),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ReimburseTheme.fieldValue.copyWith(
                      color: palette.text,
                    ),
                  ),
                  if (subtitle case final value?) ...[
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: ReimburseTheme.fieldHint.copyWith(
                        color: palette.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(trailing, size: 20, color: palette.muted),
          ],
        ),
      ),
    ),
  );
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final _FormPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: palette.field,
    shape: RoundedRectangleBorder(
      borderRadius: ReimburseTheme.fieldRadius,
      side: BorderSide(color: palette.fieldBorder),
    ),
    child: InkWell(
      customBorder: const RoundedRectangleBorder(
        borderRadius: ReimburseTheme.fieldRadius,
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            Icon(icon, size: 28, color: ReimburseTheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: ReimburseTheme.fieldValue.copyWith(color: palette.text),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Memformat input angka menjadi 1.250.000 (locale id_ID).
class _ThousandsFormatter extends TextInputFormatter {
  final _format = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final number =
        int.tryParse(digits.length > 12 ? digits.substring(0, 12) : digits) ??
        0;
    final text = _format.format(number);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
