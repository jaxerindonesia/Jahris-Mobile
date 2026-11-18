import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/leave_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/list_states.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/status_chip.dart';
import '../auth/provider.dart';
import 'model.dart';
import 'provider.dart';

class LeaveView extends ConsumerWidget {
  const LeaveView({this.showApprovals = false, super.key});

  final bool showApprovals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(leaveProvider);
    final palette = _LeavePalette.of(context);
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
                        color: palette.surface,
                        shape: CircleBorder(
                          side: BorderSide(color: palette.border),
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.canPop()
                              ? context.pop()
                              : context.go('/dashboard'),
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
                        'Izin / Cuti',
                        textAlign: TextAlign.center,
                        style: LeaveTheme.title.copyWith(color: palette.text),
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
                      fallback: 'Data cuti gagal dimuat.',
                    ),
                    onRetry: () => ref.invalidate(leaveProvider),
                  ),
                  data: (data) => _LeaveContent(
                    data: data,
                    approvalsOnly: showApprovals,
                    onNewRequest: (hint) => _openForm(context, hint),
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
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: LeaveTheme.primary,
                      foregroundColor: LeaveTheme.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => _openForm(context, null),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      'Ajukan Izin/Cuti',
                      style: LeaveTheme.button,
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

  Future<void> _openForm(BuildContext context, String? typeHint) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => _LeaveFormPage(typeHint: typeHint)),
      );
}

class _LeavePalette {
  const _LeavePalette({
    required this.scaffold,
    required this.background,
    required this.text,
    required this.surface,
    required this.border,
    required this.muted,
    required this.headerButton,
    required this.headerButtonBorder,
    required this.field,
    required this.fieldBorder,
    required this.dash,
    required this.card,
    required this.cardBorder,
    required this.link,
    required this.infoFill,
    required this.uploadFill,
  });

  factory _LeavePalette.of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  static const _dark = _LeavePalette(
    scaffold: AppColors.darkBackground,
    background: LeaveTheme.background,
    text: LeaveTheme.white,
    surface: LeaveTheme.surface,
    border: LeaveTheme.border,
    muted: LeaveTheme.muted,
    headerButton: LeaveTheme.surface,
    headerButtonBorder: LeaveTheme.border,
    field: LeaveTheme.surface,
    fieldBorder: LeaveTheme.border,
    dash: LeaveTheme.border,
    card: LeaveTheme.surface,
    cardBorder: LeaveTheme.border,
    link: LeaveTheme.link,
    infoFill: LeaveTheme.infoFill,
    uploadFill: LeaveTheme.uploadFill,
  );

  static const _light = _LeavePalette(
    scaffold: AppColors.lightBackground,
    background: LeaveTheme.lightBackground,
    text: LeaveTheme.lightText,
    surface: AppColors.lightSurface,
    border: AppColors.lightBorder,
    muted: LeaveTheme.lightMuted,
    headerButton: LeaveTheme.lightHeaderButton,
    headerButtonBorder: LeaveTheme.lightHeaderButton,
    field: LeaveTheme.lightField,
    fieldBorder: LeaveTheme.lightFieldBorder,
    dash: LeaveTheme.lightDash,
    card: LeaveTheme.lightCard,
    cardBorder: LeaveTheme.lightCardBorder,
    link: LeaveTheme.lightLink,
    infoFill: LeaveTheme.lightInfoFill,
    uploadFill: LeaveTheme.lightUploadFill,
  );

  final Color muted;
  final Color headerButton;
  final Color headerButtonBorder;
  final Color field;
  final Color fieldBorder;
  final Color dash;
  final Color card;
  final Color cardBorder;
  final Color link;
  final Color infoFill;
  final Color uploadFill;

  final Color scaffold;
  final Gradient? background;
  final Color text;
  final Color surface;
  final Color border;
}

/// Jenis pengajuan pada grid (label, kata kunci tipe API, ikon, warna).
const _leaveTypes = <(String, String, IconData, Color)>[
  ('Cuti Tahunan', 'tahunan', Icons.calendar_today_outlined, LeaveTheme.annual),
  ('Sakit', 'sakit', Icons.add_box_outlined, LeaveTheme.sick),
  ('Izin', 'izin', Icons.schedule_rounded, LeaveTheme.permit),
  ('Cuti Khusus', 'khusus', Icons.flag_outlined, LeaveTheme.special),
];

(IconData, Color) _typeVisual(String type) {
  final lower = type.toLowerCase();
  return switch (lower) {
    _ when lower.contains('sakit') => (Icons.add_box_outlined, LeaveTheme.sick),
    _ when lower.contains('khusus') => (
      Icons.flag_outlined,
      LeaveTheme.special,
    ),
    _ when lower.contains('izin') => (
      Icons.schedule_rounded,
      LeaveTheme.permit,
    ),
    _ => (Icons.calendar_today_outlined, LeaveTheme.annual),
  };
}

Color _statusColor(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('setuju')) return LeaveTheme.approved;
  if (lower.contains('tolak')) return LeaveTheme.rejected;
  if (lower.contains('tunggu')) return LeaveTheme.pending;
  return LeaveTheme.muted;
}

class _LeaveContent extends ConsumerStatefulWidget {
  const _LeaveContent({
    required this.data,
    required this.approvalsOnly,
    required this.onNewRequest,
  });

  final LeaveState data;
  final bool approvalsOnly;
  final ValueChanged<String?> onNewRequest;

  @override
  ConsumerState<_LeaveContent> createState() => _LeaveContentState();
}

class _LeaveContentState extends ConsumerState<_LeaveContent> {
  static const _previewCount = 4;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final palette = _LeavePalette.of(context);
    final controller = ref.read(leaveProvider.notifier);
    final role = ref.watch(authProvider).user?.role.toLowerCase() ?? '';
    final canApprove =
        role.contains('admin') ||
        role.contains('atasan') ||
        role.contains('manager');
    final allItems = widget.approvalsOnly
        ? data.items.where((item) => item.status == 'Menunggu').toList()
        : data.items;
    final items = _showAll
        ? allItems
        : allItems.take(_previewCount).toList(growable: false);

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _LeaveBalanceCard(balance: data.balance),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Jenis Pengajuan',
            style: LeaveTheme.section.copyWith(color: palette.text),
          ),
          const SizedBox(height: AppSpacing.compact),
          Row(
            children: [
              for (final (index, type) in _leaveTypes.indexed) ...[
                if (index > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _LeaveTypeTile(
                    label: type.$1,
                    icon: type.$3,
                    color: type.$4,
                    onTap: () => widget.onNewRequest(type.$2),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  canApprove ? 'Permohonan Karyawan' : 'Riwayat Pengajuan',
                  style: LeaveTheme.section.copyWith(color: palette.text),
                ),
              ),
              if (allItems.length > _previewCount)
                InkWell(
                  onTap: () => setState(() => _showAll = !_showAll),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Text(
                      _showAll ? 'Lebih sedikit' : 'Lihat semua',
                      style: LeaveTheme.linkText,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.compact),
          if (data.message case final message?) ...[
            Text(
              message,
              textAlign: TextAlign.center,
              style: LeaveTheme.rowCaption,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'Belum ada pengajuan izin/cuti.',
                textAlign: TextAlign.center,
                style: LeaveTheme.rowCaption,
              ),
            )
          else ...[
            for (final item in items) ...[
              _LeaveCard(
                item: item,
                canApprove: canApprove,
                onDecision: (approve) => controller.decide(
                  item.id,
                  approve: approve,
                  note: approve
                      ? 'Disetujui melalui aplikasi mobile.'
                      : 'Ditolak melalui aplikasi mobile.',
                ),
              ),
              const SizedBox(height: AppSpacing.compact),
            ],
            if (_showAll && data.hasMore)
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

class _LeaveBalanceCard extends StatelessWidget {
  const _LeaveBalanceCard({required this.balance});

  final LeaveBalance balance;

  @override
  Widget build(BuildContext context) {
    final progress = balance.total == 0
        ? 0.0
        : (balance.remaining / balance.total).clamp(0.0, 1.0);
    final yearEnd = DateTime(DateTime.now().year, 12, 31);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        gradient: LeaveTheme.balanceGradient,
        borderRadius: LeaveTheme.cardRadius,
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
                    const Text(
                      'Sisa Cuti Tahunan',
                      style: LeaveTheme.balanceLabel,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${balance.remaining} hari',
                      style: LeaveTheme.balanceValue,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'dari ${balance.total} hari · berlaku s/d '
                      '${DateFormat('d MMM yyyy', 'id_ID').format(yearEnd)}',
                      style: LeaveTheme.balanceMeta,
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: LeaveTheme.balanceIconFill,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: LeaveTheme.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.compact),
          ClipRRect(
            borderRadius: LeaveTheme.pillRadius,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: LeaveTheme.balanceTrack,
              valueColor: const AlwaysStoppedAnimation(LeaveTheme.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveTypeTile extends StatelessWidget {
  const _LeaveTypeTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _LeavePalette.of(context);
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: LeaveTheme.tileRadius,
        side: BorderSide(color: palette.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const RoundedRectangleBorder(
          borderRadius: LeaveTheme.tileRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.compact,
            horizontal: AppSpacing.xs,
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: LeaveTheme.typeLabel.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? null
                      : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({
    required this.item,
    required this.canApprove,
    required this.onDecision,
  });

  final LeaveRequest item;
  final bool canApprove;
  final ValueChanged<bool> onDecision;

  @override
  Widget build(BuildContext context) {
    final palette = _LeavePalette.of(context);
    final (icon, color) = _typeVisual(item.type);
    final statusColor = _statusColor(item.status);
    final days = item.endDate.difference(item.startDate).inDays + 1;
    final duration = item.durationLabel?.toLowerCase() ?? '$days hari';
    final title = canApprove
        ? '${item.employeeName} · ${item.type}'
        : item.type;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: LeaveTheme.tileRadius,
        side: BorderSide(color: palette.border),
      ),
      child: InkWell(
        onTap: () => context.push('/leave/detail/${item.id}'),
        customBorder: const RoundedRectangleBorder(
          borderRadius: LeaveTheme.tileRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.compact),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: LeaveTheme.iconRadius,
                    ),
                    child: Icon(icon, color: color, size: 18),
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
                          style: LeaveTheme.rowTitle.copyWith(
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_dateRange(item.startDate, item.endDate)} · $duration',
                          style: LeaveTheme.rowCaption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.compact,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.16),
                      borderRadius: LeaveTheme.pillRadius,
                    ),
                    child: Text(
                      item.status,
                      style: LeaveTheme.status.copyWith(
                        color: statusColor.readable(context),
                      ),
                    ),
                  ),
                ],
              ),
              if (canApprove && item.status == 'Menunggu') ...[
                const SizedBox(height: AppSpacing.compact),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onDecision(false),
                        child: const Text('Tolak'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => onDecision(true),
                        child: const Text('Setujui'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Contoh: "28 Okt 2026", "3–5 Nov 2026", "30 Okt – 2 Nov 2026".
  String _dateRange(DateTime start, DateTime end) {
    final full = DateFormat('d MMM yyyy', 'id_ID');
    if (DateUtils.isSameDay(start, end)) return full.format(start);
    if (start.year == end.year && start.month == end.month) {
      return '${start.day}–${full.format(end)}';
    }
    if (start.year == end.year) {
      return '${DateFormat('d MMM', 'id_ID').format(start)} – '
          '${full.format(end)}';
    }
    return '${full.format(start)} – ${full.format(end)}';
  }
}

class LeaveDetailView extends ConsumerWidget {
  const LeaveDetailView({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(leaveDetailProvider(id));
    final role = ref.watch(authProvider).user?.role.toLowerCase() ?? '';
    final canApprove =
        role.contains('admin') ||
        role.contains('atasan') ||
        role.contains('manager');
    return ModuleScaffold(
      title: 'Detail Cuti',
      body: detail.when(
        loading: () => const ListLoading(itemCount: 2),
        error: (error, _) => ListError(
          message: networkErrorMessage(
            error,
            fallback: 'Detail cuti gagal dimuat.',
          ),
          onRetry: () => ref.invalidate(leaveDetailProvider(id)),
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
                          item.type,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      StatusChip(label: item.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Detail(label: 'Karyawan', value: item.employeeName),
                  if (item.department case final department?)
                    _Detail(label: 'Departemen', value: department),
                  _Detail(
                    label: 'Periode',
                    value:
                        '${AppFormatters.date(item.startDate)} – ${AppFormatters.date(item.endDate)}',
                  ),
                  _Detail(label: 'Alasan', value: item.reason),
                  if (item.attachmentName case final attachment?)
                    _Detail(label: 'Lampiran', value: attachment),
                  if (item.approvalNote case final note?)
                    _Detail(label: 'Catatan', value: note),
                  if (item.reviewedBy case final reviewer?)
                    _Detail(label: 'Ditinjau oleh', value: reviewer),
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
    LeaveRequest item,
    bool approve,
  ) async {
    var note = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Setujui cuti?' : 'Tolak cuti?'),
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
    if (confirmed == true) {
      await ref
          .read(leaveProvider.notifier)
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

/// Halaman penuh "Ajukan Cuti".
class _LeaveFormPage extends ConsumerStatefulWidget {
  const _LeaveFormPage({this.typeHint});

  /// Kata kunci jenis pengajuan yang dipilih otomatis (mis. "sakit").
  final String? typeHint;

  @override
  ConsumerState<_LeaveFormPage> createState() => _LeaveFormPageState();
}

class _LeaveFormPageState extends ConsumerState<_LeaveFormPage> {
  String? _typeId;
  late DateTime _start = _nextDay();
  late DateTime _end = _start;
  final _reasonController = TextEditingController();
  String? _attachmentPath;

  static DateTime _nextDay() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  /// Jumlah hari kerja (Senin–Jumat) dalam rentang tanggal.
  int get _workingDays {
    var count = 0;
    for (
      var day = _start;
      !day.isAfter(_end);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      if (day.weekday <= DateTime.friday) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final palette = _LeavePalette.of(context);
    final types = ref.watch(submissionTypesProvider);
    final leaveState = ref.watch(leaveProvider).value;
    final user = ref.watch(authProvider).user;
    final typeItems = types.value ?? const <SubmissionType>[];
    final selectedId = _selectedTypeId(typeItems);
    final selectedName = typeItems
        .where((item) => item.id == selectedId)
        .map((item) => item.name)
        .firstOrNull;
    final isAnnual = (selectedName ?? '').toLowerCase().contains('tahunan');
    final remaining = leaveState?.balance.remaining;
    final days = _workingDays;
    final info = isAnnual && remaining != null
        ? '$days hari kerja · sisa cuti setelahnya '
              '${(remaining - days).clamp(0, remaining)} hari'
        : '$days hari kerja';
    final fileName = _attachmentPath?.split(RegExp(r'[/\\]')).last;

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
                        'Ajukan Cuti',
                        textAlign: TextAlign.center,
                        style: LeaveTheme.title.copyWith(color: palette.text),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    const _FormLabel('Jenis cuti'),
                    types.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (error, _) => Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Jenis cuti gagal dimuat.',
                              style: TextStyle(color: LeaveTheme.rejected),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(submissionTypesProvider),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                      data: (items) => _FormBox(
                        onTap: items.isEmpty
                            ? null
                            : () => _pickType(items, selectedId),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedName ?? 'Belum ada jenis cuti',
                                style: LeaveTheme.formValue.copyWith(
                                  color: palette.text,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: palette.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.compact),
                    const _FormLabel('Tanggal'),
                    Row(
                      children: [
                        Expanded(
                          child: _DateBox(
                            label: 'Mulai',
                            date: _start,
                            onTap: () => _pickDate(isStart: true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _DateBox(
                            label: 'Selesai',
                            date: _end,
                            onTap: () => _pickDate(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.compact,
                        vertical: AppSpacing.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        color: palette.infoFill,
                        borderRadius: LeaveTheme.iconRadius,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: palette.link,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              info,
                              style: LeaveTheme.infoText.copyWith(
                                color: palette.link,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.compact),
                    const _FormLabel('Alasan'),
                    TextField(
                      controller: _reasonController,
                      minLines: 3,
                      maxLines: 5,
                      style: LeaveTheme.formValue.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w400,
                      ),
                      cursorColor: LeaveTheme.primary,
                      decoration: InputDecoration(
                        hintText: 'Tuliskan alasan pengajuan',
                        hintStyle: LeaveTheme.rowCaption.copyWith(
                          color: palette.muted,
                        ),
                        filled: true,
                        fillColor: palette.field,
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: LeaveTheme.fieldRadius,
                          borderSide: BorderSide(color: palette.fieldBorder),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: LeaveTheme.fieldRadius,
                          borderSide: BorderSide(color: LeaveTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.compact),
                    const _FormLabel('Lampiran (opsional)'),
                    InkWell(
                      onTap: _pickAttachment,
                      borderRadius: LeaveTheme.fieldRadius,
                      child: CustomPaint(
                        painter: _DashedBorderPainter(
                          color: palette.dash,
                          fill: palette.field,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: palette.uploadFill,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  fileName == null
                                      ? Icons.upload_rounded
                                      : Icons.description_outlined,
                                  color: palette.link,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.compact),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fileName ?? 'Unggah dokumen',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: LeaveTheme.rowTitle.copyWith(
                                        color: palette.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fileName == null
                                          ? 'PDF, JPG atau PNG · maks. 5 MB'
                                          : 'Ketuk untuk mengganti',
                                      style: LeaveTheme.rowCaption.copyWith(
                                        color: palette.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (fileName != null)
                                IconButton(
                                  tooltip: 'Hapus lampiran',
                                  onPressed: () =>
                                      setState(() => _attachmentPath = null),
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: palette.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.compact),
                    const _FormLabel('Disetujui oleh'),
                    _FormBox(
                      color: palette.card,
                      borderColor: palette.cardBorder,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: LeaveTheme.approverFill,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.supervisor_account_rounded,
                              color: LeaveTheme.approverText,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.compact),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Atasan langsung',
                                  style: LeaveTheme.rowTitle.copyWith(
                                    color: palette.text,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.branchName.isNotEmpty == true
                                      ? 'Sesuai alur persetujuan ${user!.branchName}'
                                      : 'Sesuai alur persetujuan perusahaan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: LeaveTheme.rowCaption.copyWith(
                                    color: palette.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (leaveState?.message case final message?
                        when leaveState?.isSubmitting == false &&
                            !message.contains('berhasil')) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: LeaveTheme.rowCaption.copyWith(
                          color: LeaveTheme.rejected,
                        ),
                      ),
                    ],
                  ],
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
                      backgroundColor: LeaveTheme.primary,
                      foregroundColor: LeaveTheme.white,
                      disabledBackgroundColor: LeaveTheme.primary.withValues(
                        alpha: 0.4,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    onPressed:
                        typeItems.isNotEmpty &&
                            !(leaveState?.isSubmitting ?? false)
                        ? _submit
                        : null,
                    icon: leaveState?.isSubmitting ?? false
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: LeaveTheme.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 20),
                    label: const Text(
                      'Kirim Pengajuan',
                      style: LeaveTheme.button,
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

  String? _selectedTypeId(List<SubmissionType> items) {
    if (_typeId != null && items.any((item) => item.id == _typeId)) {
      return _typeId;
    }
    final hint = widget.typeHint;
    if (hint != null) {
      for (final item in items) {
        if (item.id.isNotEmpty && item.name.toLowerCase().contains(hint)) {
          return item.id;
        }
      }
    }
    return items.isEmpty ? null : items.first.id;
  }

  Future<void> _pickType(List<SubmissionType> items, String? current) async {
    final palette = _LeavePalette.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: palette.surface,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final item in items.where((item) => item.id.isNotEmpty))
              ListTile(
                title: Text(
                  item.name,
                  style: LeaveTheme.rowTitle.copyWith(color: palette.text),
                ),
                trailing: item.id == current
                    ? const Icon(Icons.check_rounded, color: LeaveTheme.primary)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(item.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _typeId = picked);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: isStart
          ? DateTime(today.year, today.month, today.day)
          : _start,
      lastDate: today.add(const Duration(days: 730)),
      initialDate: isStart ? _start : _end,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result?.path case final path?) {
      setState(() => _attachmentPath = path);
    }
  }

  Future<void> _submit() async {
    final types = ref.read(submissionTypesProvider).value ?? const [];
    final typeId = _selectedTypeId(types);
    if (typeId == null || typeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis cuti terlebih dahulu.')),
      );
      return;
    }
    final ok = await ref
        .read(leaveProvider.notifier)
        .submit(
          type: typeId,
          startDate: _start,
          endDate: _end,
          reason: _reasonController.text,
          attachmentPath: _attachmentPath,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan cuti berhasil dikirim.')),
      );
      Navigator.of(context).pop();
    }
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text,
      style: LeaveTheme.formLabel.copyWith(
        color: _LeavePalette.of(context).muted,
      ),
    ),
  );
}

class _FormBox extends StatelessWidget {
  const _FormBox({
    required this.child,
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = _LeavePalette.of(context);
    return Material(
      color: color ?? palette.field,
      shape: RoundedRectangleBorder(
        borderRadius: LeaveTheme.fieldRadius,
        side: BorderSide(color: borderColor ?? palette.fieldBorder),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const RoundedRectangleBorder(
          borderRadius: LeaveTheme.fieldRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.compact,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _LeavePalette.of(context);
    return _FormBox(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: LeaveTheme.formLabel.copyWith(color: palette.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM yyyy', 'id_ID').format(date),
                  style: LeaveTheme.formValue.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.calendar_today_outlined, size: 18, color: palette.link),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.fill});

  final Color color;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      LeaveTheme.fieldRadius.topLeft,
    );
    canvas.drawRRect(rrect, Paint()..color = fill);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fill != fill;
}
