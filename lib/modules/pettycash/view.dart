import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/petty_cash_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/list_states.dart';
import 'model.dart';
import 'provider.dart';

class PettyCashView extends ConsumerWidget {
  const PettyCashView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(pettyCashProvider);
    final palette = _PettyCashPalette.of(context);
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
                child: _Header(),
              ),
              Expanded(
                child: value.when(
                  loading: () => const ListLoading(),
                  error: (error, _) => ListError(
                    message: networkErrorMessage(
                      error,
                      fallback: 'Data kas kecil gagal dimuat.',
                    ),
                    onRetry: () => ref.invalidate(pettyCashProvider),
                  ),
                  data: (data) => _Content(data: data),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PettyCashPalette {
  const _PettyCashPalette({
    required this.scaffold,
    required this.background,
    required this.text,
    required this.muted,
    required this.surface,
    required this.border,
    required this.divider,
    required this.headerButton,
    required this.headerButtonBorder,
    required this.link,
    required this.expense,
    required this.expenseFill,
    required this.income,
    required this.incomeFill,
  });

  factory _PettyCashPalette.of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  static const _dark = _PettyCashPalette(
    scaffold: AppColors.darkBackground,
    background: PettyCashTheme.background,
    text: PettyCashTheme.white,
    muted: PettyCashTheme.muted,
    surface: PettyCashTheme.surface,
    border: PettyCashTheme.border,
    divider: PettyCashTheme.divider,
    headerButton: PettyCashTheme.surface,
    headerButtonBorder: PettyCashTheme.border,
    link: PettyCashTheme.link,
    expense: PettyCashTheme.expense,
    expenseFill: PettyCashTheme.expenseFill,
    income: PettyCashTheme.income,
    incomeFill: PettyCashTheme.incomeFill,
  );

  static const _light = _PettyCashPalette(
    scaffold: AppColors.lightBackground,
    background: PettyCashTheme.lightBackground,
    text: PettyCashTheme.lightText,
    muted: PettyCashTheme.lightMuted,
    surface: PettyCashTheme.lightCard,
    border: PettyCashTheme.lightCardBorder,
    divider: PettyCashTheme.lightDivider,
    headerButton: PettyCashTheme.lightHeaderButton,
    headerButtonBorder: PettyCashTheme.lightHeaderButton,
    link: PettyCashTheme.lightLink,
    expense: PettyCashTheme.lightExpense,
    expenseFill: PettyCashTheme.lightExpenseFill,
    income: PettyCashTheme.lightIncome,
    incomeFill: PettyCashTheme.lightIncomeFill,
  );

  final Color headerButton;
  final Color headerButtonBorder;
  final Color link;
  final Color expense;
  final Color expenseFill;
  final Color income;
  final Color incomeFill;
  final Color scaffold;
  final Gradient background;
  final Color text;
  final Color muted;
  final Color surface;
  final Color border;
  final Color divider;
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final palette = _PettyCashPalette.of(context);
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
            'Petty Cash',
            textAlign: TextAlign.center,
            style: PettyCashTheme.title.copyWith(color: palette.text),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}

class _Content extends ConsumerStatefulWidget {
  const _Content({required this.data});
  final PettyCashState data;

  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content> {
  static const _previewCount = 5;
  bool _showAll = false;

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Fitur $feature belum tersedia.')));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final palette = _PettyCashPalette.of(context);
    final controller = ref.read(pettyCashProvider.notifier);
    final summary = PettyCashSummary.fromItems(data.items);
    final items = _showAll
        ? data.items
        : data.items.take(_previewCount).toList();
    final canExpand = data.items.length > _previewCount || data.hasMore;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          _BalanceCard(summary: summary),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: PettyCashTheme.primary,
                foregroundColor: PettyCashTheme.white,
                shape: const StadiumBorder(),
              ),
              onPressed: () => _comingSoon('catat kas keluar'),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Catat Keluar', style: PettyCashTheme.button),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Transaksi Terakhir',
                  style: PettyCashTheme.section.copyWith(color: palette.text),
                ),
              ),
              if (canExpand)
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  onTap: () {
                    setState(() => _showAll = !_showAll);
                    if (_showAll && data.hasMore) controller.loadMore();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Text(
                      _showAll ? 'Lebih sedikit' : 'Lihat semua',
                      style: PettyCashTheme.linkText.copyWith(
                        color: palette.link,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (items.isEmpty)
            _EmptyCard(palette: palette)
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: PettyCashTheme.cardRadius,
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                        color: palette.divider,
                      ),
                    _TransactionRow(item: items[i]),
                  ],
                ],
              ),
            ),
          if (_showAll && data.hasMore)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: TextButton(
                onPressed: controller.loadMore,
                child: const Text('Muat lainnya'),
              ),
            ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatefulWidget {
  const _BalanceCard({required this.summary});
  final PettyCashSummary summary;

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _hidden = false;

  String _money(num value) =>
      _hidden ? 'Rp ••••••' : AppFormatters.rupiah(value.toInt());

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: PettyCashTheme.balanceGradient,
        borderRadius: PettyCashTheme.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Saldo Kas', style: PettyCashTheme.balanceLabel),
              ),
              IconButton(
                tooltip: _hidden ? 'Tampilkan saldo' : 'Sembunyikan saldo',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: PettyCashTheme.white,
                  size: 20,
                ),
              ),
            ],
          ),
          Text(
            _money(summary.balance),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PettyCashTheme.balanceValue,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Terpakai ${_money(summary.expense)} dari '
            '${_money(summary.income)} kas masuk',
            style: PettyCashTheme.balanceMeta,
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: summary.usedRatio,
              minHeight: 8,
              backgroundColor: PettyCashTheme.balanceTrack,
              valueColor: const AlwaysStoppedAnimation(PettyCashTheme.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item});
  final PettyCashRecord item;

  static IconData _iconFor(PettyCashRecord item) {
    if (item.isIncome) return Icons.account_balance_wallet_outlined;
    final text = '${item.category ?? ''} ${item.purpose ?? ''}'.toLowerCase();
    if (text.contains('konsumsi') ||
        text.contains('makan') ||
        text.contains('minum')) {
      return Icons.local_cafe_outlined;
    }
    if (text.contains('kurir') ||
        text.contains('kirim') ||
        text.contains('paket')) {
      return Icons.inventory_2_outlined;
    }
    if (text.contains('bensin') ||
        text.contains('transport') ||
        text.contains('parkir') ||
        text.contains('tol')) {
      return Icons.directions_car_outlined;
    }
    return Icons.receipt_long_outlined;
  }

  static String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final day = isToday
        ? 'Hari ini'
        : DateFormat('d MMM', 'id_ID').format(date);
    return '$day · ${DateFormat('HH:mm', 'id_ID').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PettyCashPalette.of(context);
    final income = item.isIncome;
    final accent = income ? palette.income : palette.expense;
    final date = item.date;
    final amount = item.amount;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: income ? palette.incomeFill : palette.expenseFill,
              borderRadius: PettyCashTheme.iconRadius,
            ),
            child: Icon(_iconFor(item), color: accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.purpose ?? 'Transaksi kas kecil',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PettyCashTheme.rowTitle.copyWith(color: palette.text),
                ),
                const SizedBox(height: 2),
                Text(
                  date == null ? 'Tanggal belum tersedia' : _dateLabel(date),
                  style: PettyCashTheme.rowCaption.copyWith(
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            amount == null
                ? '-'
                : '${income ? '+' : '-'} '
                      '${AppFormatters.rupiah(amount.toInt())}',
            style: PettyCashTheme.amount.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.palette});
  final _PettyCashPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: PettyCashTheme.cardRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: palette.muted, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Belum ada transaksi kas kecil.',
            textAlign: TextAlign.center,
            style: PettyCashTheme.rowCaption.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}
