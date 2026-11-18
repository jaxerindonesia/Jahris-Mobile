import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/help_theme.dart';
import 'model.dart';
import 'provider.dart';
import 'service.dart';

class HelpCenterView extends ConsumerStatefulWidget {
  const HelpCenterView({super.key});

  @override
  ConsumerState<HelpCenterView> createState() => _HelpCenterViewState();
}

class _HelpCenterViewState extends ConsumerState<HelpCenterView> {
  final _expandedFaqs = <String>{helpFaqs.first.question};

  @override
  Widget build(BuildContext context) {
    final palette = _HelpPalette.of(context);
    final filter = ref.watch(helpCenterProvider);
    final faqs = ref.watch(filteredFaqsProvider);

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
                child: _HelpHeader(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  children: [
                    Text(
                      'Ada yang bisa kami bantu?',
                      style: HelpTheme.heading.copyWith(color: palette.text),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SearchField(
                      onChanged: ref.read(helpCenterProvider.notifier).setQuery,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        for (final (index, category)
                            in helpCategories.indexed) ...[
                          if (index > 0) const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _CategoryTile(
                              category: category,
                              selected: filter.categoryId == category.id,
                              onTap: () => ref
                                  .read(helpCenterProvider.notifier)
                                  .toggleCategory(category.id),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Pertanyaan Populer',
                      style: HelpTheme.section.copyWith(color: palette.text),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (faqs.isEmpty)
                      _EmptyFaq(palette: palette)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: HelpTheme.cardRadius,
                          border: Border.all(color: palette.border),
                        ),
                        child: Column(
                          children: [
                            for (final (index, faq) in faqs.indexed) ...[
                              if (index > 0)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: palette.divider,
                                ),
                              _FaqRow(
                                faq: faq,
                                expanded: _expandedFaqs.contains(faq.question),
                                onToggle: () => setState(() {
                                  if (!_expandedFaqs.remove(faq.question)) {
                                    _expandedFaqs.add(faq.question);
                                  }
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    const _NeedHelpCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpPalette {
  const _HelpPalette({
    required this.scaffold,
    required this.background,
    required this.text,
    required this.muted,
    required this.question,
    required this.surface,
    required this.border,
    required this.divider,
    required this.contactBackground,
    required this.contactBorder,
  });

  factory _HelpPalette.of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const _HelpPalette(
          scaffold: AppColors.darkBackground,
          background: HelpTheme.background,
          text: HelpTheme.white,
          muted: HelpTheme.muted,
          question: Color(0xFFD5DCF0),
          surface: HelpTheme.surface,
          border: HelpTheme.border,
          divider: HelpTheme.divider,
          contactBackground: HelpTheme.contactGradient,
          contactBorder: HelpTheme.contactBorder,
        )
      : const _HelpPalette(
          scaffold: AppColors.lightBackground,
          background: null,
          text: AppColors.lightText,
          muted: AppColors.lightMuted,
          question: AppColors.lightText,
          surface: AppColors.lightSurface,
          border: AppColors.lightBorder,
          divider: AppColors.lightBorder,
          contactBackground: null,
          contactBorder: AppColors.lightBorder,
        );

  final Color scaffold;
  final Gradient? background;
  final Color text;
  final Color muted;
  final Color question;
  final Color surface;
  final Color border;
  final Color divider;
  final Gradient? contactBackground;
  final Color contactBorder;
}

class _HelpHeader extends StatelessWidget {
  const _HelpHeader();

  @override
  Widget build(BuildContext context) {
    final palette = _HelpPalette.of(context);
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
            'Bantuan',
            textAlign: TextAlign.center,
            style: HelpTheme.title.copyWith(color: palette.text),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = _HelpPalette.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      borderSide: BorderSide(color: palette.border),
    );
    return TextField(
      onChanged: onChanged,
      style: HelpTheme.search.copyWith(color: palette.text),
      decoration: InputDecoration(
        hintText: 'Cari pertanyaan...',
        hintStyle: HelpTheme.search.copyWith(color: palette.muted),
        prefixIcon: Icon(Icons.search_rounded, color: palette.muted, size: 20),
        filled: true,
        fillColor: palette.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: HelpTheme.primary),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final HelpCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _HelpPalette.of(context);
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: HelpTheme.tileRadius,
        side: BorderSide(
          color: selected ? category.color : palette.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: HelpTheme.tileRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: category.color.withValues(alpha: 0.18),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  category.iconAsset,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    category.color,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                category.label,
                style: HelpTheme.categoryLabel.copyWith(
                  color: palette.question,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({
    required this.faq,
    required this.expanded,
    required this.onToggle,
  });

  final FaqItem faq;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = _HelpPalette.of(context);
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    faq.question,
                    style: expanded
                        ? HelpTheme.questionOpen.copyWith(color: palette.text)
                        : HelpTheme.question.copyWith(color: palette.question),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.chevron_right_rounded,
                  color: expanded ? HelpTheme.chevron : palette.muted,
                  size: 20,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        faq.answer,
                        style: HelpTheme.answer.copyWith(color: palette.muted),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFaq extends StatelessWidget {
  const _EmptyFaq({required this.palette});

  final _HelpPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: palette.surface,
      borderRadius: HelpTheme.cardRadius,
      border: Border.all(color: palette.border),
    ),
    child: Column(
      children: [
        Icon(Icons.search_off_rounded, color: palette.muted, size: 32),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tidak ada pertanyaan yang cocok.',
          textAlign: TextAlign.center,
          style: HelpTheme.answer.copyWith(color: palette.muted),
        ),
      ],
    ),
  );
}

class _NeedHelpCard extends StatelessWidget {
  const _NeedHelpCard();

  @override
  Widget build(BuildContext context) {
    final palette = _HelpPalette.of(context);
    Future<void> open(Uri url, String fallback) async {
      final messenger = ScaffoldMessenger.of(context);
      var opened = false;
      try {
        opened = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      } on Exception {
        opened = false;
      }
      if (opened) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(fallback)));
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.contactBackground == null ? palette.surface : null,
        gradient: palette.contactBackground,
        borderRadius: HelpTheme.cardRadius,
        border: Border.all(color: palette.contactBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masih butuh bantuan?',
            style: HelpTheme.contactTitle.copyWith(color: palette.text),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tim HR siap membantu Senin–Jumat, 08:00–17:00',
            style: HelpTheme.contactCaption.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: HelpTheme.primary,
                      foregroundColor: HelpTheme.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => open(
                      Env.customerServiceUrl,
                      'Tidak bisa membuka WhatsApp. Hubungi '
                      '${Env.supportWhatsappDisplay}.',
                    ),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('Chat HR', style: HelpTheme.button),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.text,
                      backgroundColor: palette.contactBackground == null
                          ? null
                          : HelpTheme.secondaryButton,
                      side: BorderSide(color: palette.border),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => open(
                      Env.supportEmailUrl,
                      'Tidak bisa membuka aplikasi email. Kirim ke '
                      '${Env.supportEmail}.',
                    ),
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: const Text('Email', style: HelpTheme.button),
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
