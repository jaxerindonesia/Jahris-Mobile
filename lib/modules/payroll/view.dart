import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/payroll_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/list_states.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/status_chip.dart';
import 'model.dart';
import 'provider.dart';

class PayrollView extends ConsumerWidget {
  const PayrollView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const _EmployeeSlipPage();
}

class PayrollManagementView extends ConsumerWidget {
  const PayrollManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(payrollProvider);
    return ModuleScaffold(
      title: 'Payroll',
      subtitle: 'Ringkasan dan komponen payroll tenant.',
      body: value.when(
        loading: () => const ListLoading(),
        error: (_, _) => ListError(
          message: 'Data payroll gagal dimuat.',
          onRetry: () => ref.invalidate(payrollProvider),
        ),
        data: (data) => _PayrollContent(data: data, isAdmin: true),
      ),
    );
  }
}

class _PayrollContent extends ConsumerWidget {
  const _PayrollContent({required this.data, required this.isAdmin});
  final PayrollState data;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(payrollProvider.notifier);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          if (isAdmin) ...[
            StatCard(
              title: 'Gaji Dibayarkan',
              value: AppFormatters.rupiah(data.summary.paid),
              subtitle: 'Tahun ${data.summary.year}',
              icon: Icons.check_circle_rounded,
              accent: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.md),
            StatCard(
              title: 'Gaji Pending',
              value: AppFormatters.rupiah(data.summary.pending),
              subtitle: 'Tahun ${data.summary.year}',
              icon: Icons.schedule_rounded,
              accent: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            StatCard(
              title: 'Total Gaji',
              value: AppFormatters.rupiah(data.summary.total),
              subtitle: 'Tahun ${data.summary.year}',
              icon: Icons.payments_rounded,
              accent: AppColors.purple,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _openComponents(context, ref, data.components),
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Kelola Komponen Payroll'),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (!isAdmin && data.slips.isNotEmpty) ...[
            _LatestSlipCard(slip: data.slips.first),
            const SizedBox(height: AppSpacing.xl),
          ],
          Text(
            isAdmin
                ? 'Periode Payroll'
                : data.slips.length > 1
                ? 'Slip Sebelumnya'
                : 'Slip Gaji Saya',
            style: Theme.of(context).textTheme.headlineSmall,
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
          if (data.slips.isEmpty)
            const GlassCard(child: Center(child: Text('Belum ada slip gaji.')))
          else ...[
            for (final slip in data.slips) ...[
              GlassCard(
                onTap: () => context.push('/payroll/slip/${slip.id}'),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.purple,
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slip.period,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            isAdmin
                                ? slip.employeeName
                                : AppFormatters.date(slip.paidAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            AppFormatters.rupiah(slip.net),
                            style: const TextStyle(
                              color: AppColors.purple,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(label: slip.status),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              'Menampilkan ${data.slips.length} dari ${data.total} slip',
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

  Future<void> _openComponents(
    BuildContext context,
    WidgetRef ref,
    List<PayrollComponent> components,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Komponen Payroll',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Tambah komponen',
                  onPressed: () => _editComponent(sheetContext, ref),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (components.isEmpty)
              const Text('Belum ada komponen payroll.')
            else
              for (final item in components)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.type} • ${AppFormatters.rupiah(item.amount)}',
                  ),
                  leading: Icon(
                    item.type == 'Potongan'
                        ? Icons.remove_circle_outline_rounded
                        : Icons.add_circle_outline_rounded,
                    color: item.type == 'Potongan'
                        ? AppColors.danger
                        : AppColors.success,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') {
                        _editComponent(sheetContext, ref, item);
                      }
                      if (action == 'delete') {
                        ref
                            .read(payrollProvider.notifier)
                            .deleteComponent(item.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Ubah')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _editComponent(
    BuildContext context,
    WidgetRef ref, [
    PayrollComponent? current,
  ]) async {
    var name = current?.name ?? '';
    var type = current?.type ?? 'Pendapatan';
    var amount = current?.amount.toString() ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(current == null ? 'Tambah Komponen' : 'Ubah Komponen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(labelText: 'Nama'),
              onChanged: (value) => name = value,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Jenis'),
              items: const ['Pendapatan', 'Potongan']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => type = value ?? type,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal'),
              onChanged: (value) => amount = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true &&
        name.trim().isNotEmpty &&
        (int.tryParse(amount) ?? 0) > 0) {
      await ref
          .read(payrollProvider.notifier)
          .saveComponent(
            PayrollComponent(
              id: current?.id ?? '',
              name: name.trim(),
              type: type,
              amount: int.parse(amount),
              active: current?.active ?? true,
            ),
          );
    }
  }
}

class PayrollSlipDetailView extends ConsumerWidget {
  const PayrollSlipDetailView({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(payrollSlipProvider(id));
    return ModuleScaffold(
      title: 'Detail Slip Gaji',
      body: value.when(
        loading: () => const ListLoading(itemCount: 2),
        error: (_, _) => ListError(
          message: 'Slip gaji gagal dimuat.',
          onRetry: () => ref.invalidate(payrollSlipProvider(id)),
        ),
        data: (slip) => ListView(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          slip.period,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      StatusChip(label: slip.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Ledger(label: 'Karyawan', value: slip.employeeName),
                  _Ledger(
                    label: 'Pendapatan bruto',
                    value: AppFormatters.rupiah(slip.gross),
                  ),
                  _Ledger(
                    label: 'Potongan',
                    value: AppFormatters.rupiah(slip.deductions),
                  ),
                  const Divider(),
                  _Ledger(
                    label: 'Gaji bersih',
                    value: AppFormatters.rupiah(slip.net),
                    accent: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(payrollProvider.notifier).download(slip.id),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Unduh PDF'),
            ),
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(payrollProvider.notifier)
                  .download(slip.id, share: true),
              icon: const Icon(Icons.share_rounded),
              label: const Text('Bagikan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestSlipCard extends StatelessWidget {
  const _LatestSlipCard({required this.slip});
  final PayrollSlip slip;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.card),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.info],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'GAJI BERSIH TERBARU',
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            StatusChip(label: slip.status),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppFormatters.rupiah(slip.net),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          slip.period,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SlipMetric(
                label: 'Pendapatan',
                value: AppFormatters.rupiah(slip.gross),
              ),
            ),
            Expanded(
              child: _SlipMetric(
                label: 'Potongan',
                value: AppFormatters.rupiah(slip.deductions),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.tonalIcon(
          onPressed: () => context.push('/payroll/slip/${slip.id}'),
          icon: const Icon(Icons.receipt_long_rounded),
          label: const Text('Lihat Slip'),
        ),
      ],
    ),
  );
}

class _SlipMetric extends StatelessWidget {
  const _SlipMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.7)),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        value,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _Ledger extends StatelessWidget {
  const _Ledger({
    required this.label,
    required this.value,
    this.accent = false,
  });
  final String label;
  final String value;
  final bool accent;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Text(
          value,
          style: accent
              ? Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: AppColors.purple)
              : null,
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Slip Gaji karyawan (desain Stitch).
// ---------------------------------------------------------------------------

class _PayrollPalette {
  const _PayrollPalette({
    required this.scaffold,
    required this.background,
    required this.text,
    required this.muted,
    required this.lineLabel,
    required this.surface,
    required this.border,
    required this.divider,
  });

  factory _PayrollPalette.of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const _PayrollPalette(
          scaffold: AppColors.darkBackground,
          background: PayrollTheme.background,
          text: PayrollTheme.white,
          muted: PayrollTheme.muted,
          lineLabel: PayrollTheme.lineLabelColor,
          surface: PayrollTheme.surface,
          border: PayrollTheme.border,
          divider: PayrollTheme.divider,
        )
      : const _PayrollPalette(
          scaffold: PayrollTheme.lightBackground,
          background: null,
          text: AppColors.lightText,
          muted: AppColors.lightMuted,
          lineLabel: AppColors.lightMuted,
          surface: AppColors.lightSurface,
          border: AppColors.lightBorder,
          divider: AppColors.lightBorder,
        );

  final Color scaffold;
  final Gradient? background;
  final Color text;
  final Color muted;
  final Color lineLabel;
  final Color surface;
  final Color border;
  final Color divider;
}

class _EmployeeSlipPage extends ConsumerStatefulWidget {
  const _EmployeeSlipPage();

  @override
  ConsumerState<_EmployeeSlipPage> createState() => _EmployeeSlipPageState();
}

class _EmployeeSlipPageState extends ConsumerState<_EmployeeSlipPage> {
  int? _year;
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    ref.listen(payrollProvider, (previous, next) {
      final message = next.value?.message;
      if (message != null && message != previous?.value?.message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });
    final value = ref.watch(payrollProvider);
    final palette = _PayrollPalette.of(context);

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
                child: _SlipHeader(),
              ),
              Expanded(
                child: value.when(
                  loading: () => const ListLoading(),
                  error: (_, _) => ListError(
                    message: 'Data slip gaji gagal dimuat.',
                    onRetry: () => ref.invalidate(payrollProvider),
                  ),
                  data: _buildContent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(PayrollState data) {
    final palette = _PayrollPalette.of(context);
    final controller = ref.read(payrollProvider.notifier);
    final loadedYears = {
      for (final slip in data.slips) slip.periodMonth.year,
    }.toList()..sort((a, b) => b.compareTo(a));
    final years = [
      ...loadedYears,
      if (data.hasMore && loadedYears.isNotEmpty) loadedYears.last - 1,
    ];
    final year = _year ?? (years.isEmpty ? DateTime.now().year : years.first);
    final slips =
        data.slips.where((slip) => slip.periodMonth.year == year).toList()
          ..sort((a, b) => b.periodMonth.compareTo(a.periodMonth));
    final selected = slips.isEmpty
        ? null
        : slips.firstWhere(
            (slip) => slip.id == _selectedId,
            orElse: () => slips.first,
          );
    final others = slips.where((slip) => slip != selected).toList();

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          if (years.isNotEmpty) ...[
            _YearTabs(
              years: years,
              selected: year,
              onSelected: (value) {
                setState(() {
                  _year = value;
                  _selectedId = null;
                });
                final hasSlips = data.slips.any(
                  (slip) => slip.periodMonth.year == value,
                );
                if (!hasSlips && data.hasMore) controller.loadMore();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (selected == null)
            _SlipEmpty(
              palette: palette,
              message: data.hasMore
                  ? 'Memuat slip gaji tahun $year...'
                  : 'Belum ada slip gaji untuk tahun $year.',
            )
          else ...[
            _SlipHero(
              slip: selected,
              downloading: data.isDownloading,
              onDownload: () => controller.download(selected.id),
            ),
            const SizedBox(height: AppSpacing.md),
            _SlipBreakdown(slip: selected),
          ],
          if (others.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Slip Sebelumnya',
              style: PayrollTheme.section.copyWith(color: palette.text),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final slip in others) ...[
              _PreviousSlipTile(
                slip: slip,
                onTap: () => setState(() => _selectedId = slip.id),
                onDownload: data.isDownloading
                    ? null
                    : () => controller.download(slip.id),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          if (data.hasMore && slips.isNotEmpty)
            TextButton(
              onPressed: controller.loadMore,
              child: const Text('Muat lainnya'),
            ),
        ],
      ),
    );
  }
}

class _SlipHeader extends StatelessWidget {
  const _SlipHeader();

  @override
  Widget build(BuildContext context) {
    final palette = _PayrollPalette.of(context);
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
            'Slip Gaji',
            textAlign: TextAlign.center,
            style: PayrollTheme.title.copyWith(color: palette.text),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}

class _YearTabs extends StatelessWidget {
  const _YearTabs({
    required this.years,
    required this.selected,
    required this.onSelected,
  });

  final List<int> years;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = _PayrollPalette.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final year in years) ...[
            Material(
              color: year == selected ? PayrollTheme.primary : palette.surface,
              shape: StadiumBorder(
                side: BorderSide(
                  color: year == selected
                      ? PayrollTheme.primary
                      : palette.border,
                ),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onSelected(year),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    '$year',
                    style: PayrollTheme.tab.copyWith(
                      color: year == selected
                          ? PayrollTheme.white
                          : palette.muted,
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

class _SlipHero extends StatefulWidget {
  const _SlipHero({
    required this.slip,
    required this.downloading,
    required this.onDownload,
  });

  final PayrollSlip slip;
  final bool downloading;
  final VoidCallback onDownload;

  @override
  State<_SlipHero> createState() => _SlipHeroState();
}

class _SlipHeroState extends State<_SlipHero> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final slip = widget.slip;
    final paid = slip.status.toLowerCase() != 'pending';
    final paidDate = DateFormat('d MMM yyyy', 'id_ID').format(slip.paidAt);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        gradient: PayrollTheme.heroGradient,
        borderRadius: PayrollTheme.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: PayrollTheme.heroBadge,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              DateFormat('MMMM yyyy', 'id_ID').format(slip.periodMonth),
              style: PayrollTheme.badge,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Gaji bersih (take home pay)',
            style: PayrollTheme.heroLabel,
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  _hidden ? 'Rp ••••••' : AppFormatters.rupiah(slip.net),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PayrollTheme.heroValue,
                ),
              ),
              IconButton(
                tooltip: _hidden ? 'Tampilkan nominal' : 'Sembunyikan nominal',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: PayrollTheme.white,
                  size: 20,
                ),
              ),
            ],
          ),
          Text(
            paid ? 'Dibayarkan $paidDate' : 'Menunggu pembayaran',
            style: PayrollTheme.heroMeta,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 40,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: PayrollTheme.white,
                foregroundColor: PayrollTheme.pdfText,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              onPressed: widget.downloading ? null : widget.onDownload,
              icon: widget.downloading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: const Text('Unduh PDF', style: PayrollTheme.pdfButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlipBreakdown extends StatelessWidget {
  const _SlipBreakdown({required this.slip});
  final PayrollSlip slip;

  @override
  Widget build(BuildContext context) {
    final palette = _PayrollPalette.of(context);
    final earnings = slip.earnings.isEmpty
        ? [PayrollLine(name: 'Pendapatan bruto', amount: slip.gross)]
        : slip.earnings;
    final deductions = slip.deductionLines.isEmpty
        ? [
            PayrollLine(
              name: 'Total potongan',
              amount: slip.deductions,
              isDeduction: true,
            ),
          ]
        : slip.deductionLines;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: PayrollTheme.cardRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pendapatan',
            style: PayrollTheme.group.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? PayrollTheme.earning
                  : PayrollTheme.lightEarning,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final item in earnings) _BreakdownLine(item: item),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Potongan',
            style: PayrollTheme.group.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? PayrollTheme.deduction
                  : PayrollTheme.lightDeduction,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final item in deductions) _BreakdownLine(item: item),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: palette.divider),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total diterima',
                  style: PayrollTheme.total.copyWith(color: palette.text),
                ),
              ),
              Text(
                AppFormatters.rupiah(slip.net),
                style: PayrollTheme.totalValue.copyWith(color: palette.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownLine extends StatelessWidget {
  const _BreakdownLine({required this.item});
  final PayrollLine item;

  @override
  Widget build(BuildContext context) {
    final palette = _PayrollPalette.of(context);
    final amount = AppFormatters.rupiah(item.amount);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              style: PayrollTheme.lineLabel.copyWith(color: palette.lineLabel),
            ),
          ),
          Text(
            item.isDeduction ? '- $amount' : amount,
            style: PayrollTheme.lineValue.copyWith(
              color: item.isDeduction
                  ? Theme.of(context).brightness == Brightness.dark
                        ? PayrollTheme.deduction
                        : PayrollTheme.lightDeduction
                  : palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviousSlipTile extends StatelessWidget {
  const _PreviousSlipTile({
    required this.slip,
    required this.onTap,
    required this.onDownload,
  });

  final PayrollSlip slip;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final palette = _PayrollPalette.of(context);
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: PayrollTheme.tileRadius,
        side: BorderSide(color: palette.border),
      ),
      child: InkWell(
        borderRadius: PayrollTheme.tileRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? PayrollTheme.fileFill
                      : PayrollTheme.primary.withValues(alpha: 0.1),
                  borderRadius: PayrollTheme.iconRadius,
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? PayrollTheme.fileIcon
                      : PayrollTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy', 'id_ID').format(slip.periodMonth),
                      style: PayrollTheme.rowTitle.copyWith(
                        color: palette.text,
                      ),
                    ),
                    Text(
                      AppFormatters.rupiah(slip.net),
                      style: PayrollTheme.rowCaption.copyWith(
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: AppColors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: PayrollTheme.iconRadius,
                  side: BorderSide(color: palette.border),
                ),
                child: IconButton(
                  tooltip: 'Unduh slip',
                  onPressed: onDownload,
                  icon: Icon(
                    Icons.download_rounded,
                    color: palette.text,
                    size: 18,
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

class _SlipEmpty extends StatelessWidget {
  const _SlipEmpty({required this.palette, required this.message});
  final _PayrollPalette palette;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: palette.surface,
      borderRadius: PayrollTheme.cardRadius,
      border: Border.all(color: palette.border),
    ),
    child: Column(
      children: [
        Icon(Icons.receipt_long_outlined, color: palette.muted, size: 32),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: PayrollTheme.rowCaption.copyWith(color: palette.muted),
        ),
      ],
    ),
  );
}
