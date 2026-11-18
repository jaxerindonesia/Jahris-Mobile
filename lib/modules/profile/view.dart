import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/profile_theme.dart';
import '../../core/widgets/list_states.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secure_screen.dart';
import '../auth/provider.dart';
import 'model.dart';
import 'provider.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(profileProvider);
    return ModuleScaffold(
      title: context.l10n.profileTitle,
      currentIndex: 3,
      showAppHeader: false,
      showPageHeading: false,
      backgroundGradient: ProfileTheme.background,
      contentPadding: ProfileTheme.pagePadding,
      body: value.when(
        loading: () => const ListLoading(itemCount: 3),
        error: (_, _) => ListError(
          message: context.l10n.profileLoadError,
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (data) => _ProfileContent(data: data),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.data});
  final ProfileState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(profileProvider.notifier);
    final profile = data.profile;
    final stats = ref.watch(profileStatisticsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? ProfileTheme.white : AppColors.lightText;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
        children: [
          Row(
            children: [
              Text(
                context.l10n.profileTitle,
                style: ProfileTheme.heading.copyWith(color: foreground),
              ),
              const Spacer(),
              IconButton(
                tooltip: context.l10n.profileEdit,
                onPressed: () => _editProfile(context, ref, profile),
                style: IconButton.styleFrom(
                  backgroundColor: dark
                      ? ProfileTheme.iconSurface
                      : AppColors.lightSurface,
                  foregroundColor: foreground,
                  minimumSize: const Size.square(30),
                  padding: const EdgeInsets.all(7),
                  shape: const CircleBorder(),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: ProfileTheme.white,
                    child: Text(profile.initials, style: ProfileTheme.initials),
                  ),
                  SizedBox.square(
                    dimension: 24,
                    child: IconButton(
                      tooltip: context.l10n.profileEditFromAvatar,
                      onPressed: () => _editProfile(context, ref, profile),
                      style: IconButton.styleFrom(
                        backgroundColor: ProfileTheme.primary,
                        foregroundColor: ProfileTheme.white,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        shape: const CircleBorder(),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                profile.name,
                textAlign: TextAlign.center,
                style: ProfileTheme.name.copyWith(color: foreground),
              ),
              Text(
                '${profile.position} · ${profile.department}',
                textAlign: TextAlign.center,
                style: ProfileTheme.role,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: dark
                      ? ProfileTheme.chipSurface
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: ProfileTheme.pillRadius,
                ),
                child: Text(
                  'NIK ${profile.nik}',
                  style: dark
                      ? ProfileTheme.nik
                      : ProfileTheme.nik.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('profile-statistics'),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: dark ? ProfileTheme.surface : AppColors.lightSurface,
              borderRadius: ProfileTheme.cardRadius,
              border: Border.all(
                color: dark ? ProfileTheme.border : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ProfileStat(
                    value: stats.remainingLeave,
                    label: context.l10n.profileStatLeave,
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _ProfileStat(
                    value: stats.workDays,
                    label: context.l10n.profileStatPresent,
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _ProfileStat(
                    value: stats.overtime,
                    label: context.l10n.profileStatOvertime,
                  ),
                ),
              ],
            ),
          ),
          if (data.message case final message?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: ProfileTheme.metadata,
              ),
            ),
          const SizedBox(height: 16),
          _SectionLabel(context.l10n.profileSectionAccount),
          _ProfileGroup(
            children: [
              _MenuRow(
                icon: Icons.person_outline_rounded,
                title: context.l10n.profilePersonalData,
                onTap: () => _editProfile(context, ref, profile),
              ),
              _MenuRow(
                icon: Icons.description_outlined,
                title: context.l10n.profileDocuments,
                subtitle: context.l10n.profileDocumentsCount(3),
              ),
              _MenuRow(
                icon: Icons.credit_card_outlined,
                title: context.l10n.profileBankAccount,
                subtitle: profile.hasBankAccount
                    ? profile.maskedBankAccount
                    : context.l10n.profileBankNotSet,
                onTap: () => _editBank(context, profile),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionLabel(context.l10n.profileSectionSettings),
          _ProfileGroup(
            children: [
              _MenuRow(
                icon: Icons.notifications_none_rounded,
                title: context.l10n.profileNotifications,
                trailing: _ProfileSwitch(value: true, onChanged: (_) {}),
              ),
              _MenuRow(
                icon: Icons.dark_mode_outlined,
                title: context.l10n.profileDarkTheme,
                trailing: _ProfileSwitch(
                  value: dark,
                  onChanged: (_) => controller.toggleTheme(),
                ),
              ),
              _MenuRow(
                icon: Icons.language_rounded,
                title: context.l10n.profileLanguage,
                subtitle: ref.watch(localeProvider).languageCode == 'en'
                    ? context.l10n.languageEnglish
                    : context.l10n.languageIndonesian,
                onTap: () => _pickLanguage(context, ref),
              ),
              _MenuRow(
                icon: Icons.lock_outline_rounded,
                title: context.l10n.profileSecurity,
                onTap: () => _changePassword(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionLabel(context.l10n.profileSectionOther),
          _ProfileGroup(
            children: [
              _MenuRow(
                icon: Icons.help_outline_rounded,
                title: context.l10n.profileHelp,
                onTap: () => context.push('/bantuan'),
              ),
              _MenuRow(
                icon: Icons.info_outline_rounded,
                title: context.l10n.profileAbout,
                subtitle: 'v1.0.0',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, ref),
              style: OutlinedButton.styleFrom(
                backgroundColor: dark
                    ? ProfileTheme.logoutSurface
                    : ProfileTheme.danger.withValues(alpha: 0.08),
                foregroundColor: ProfileTheme.danger,
                side: const BorderSide(color: ProfileTheme.logoutBorder),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.logout_rounded, size: 15),
              label: Text(
                context.l10n.profileLogout,
                style: ProfileTheme.logout,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.profileLogoutTitle),
        content: Text(context.l10n.profileLogoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.onPrimary,
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.profileLogout),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ProfileForm(profile: profile),
  );

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: dark
          ? ProfileTheme.sheetSurface
          : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: ProfileTheme.sheetRadius,
      ),
      builder: (_) => const _LanguageSheet(),
    );
  }

  Future<void> _editBank(BuildContext context, UserProfile profile) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => SecureScreen(child: _BankForm(profile: profile)),
      );

  Future<void> _changePassword(BuildContext context, WidgetRef ref) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? ProfileTheme.sheetSurface
            : null,
        shape: const RoundedRectangleBorder(
          borderRadius: ProfileTheme.sheetRadius,
        ),
        builder: (_) => const SecureScreen(child: _PasswordForm()),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 8),
    child: Text(label, style: ProfileTheme.section),
  );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ProfileTheme.stat.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ProfileTheme.statLabel,
        ),
      ],
    ),
  );
}

class _ProfileGroup extends StatelessWidget {
  const _ProfileGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? ProfileTheme.surface : AppColors.lightSurface,
        borderRadius: ProfileTheme.cardRadius,
        border: Border.all(
          color: dark ? ProfileTheme.border : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 62,
                endIndent: 12,
                color: dark ? ProfileTheme.border : AppColors.lightBorder,
              ),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: dark
                      ? ProfileTheme.iconSurface
                      : AppColors.lightBorder,
                  borderRadius: ProfileTheme.iconRadius,
                ),
                child: Icon(
                  icon,
                  color: dark ? ProfileTheme.white : AppColors.lightText,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ProfileTheme.menu.copyWith(
                    color: dark ? ProfileTheme.white : AppColors.lightText,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else ...[
                if (subtitle != null) ...[
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: ProfileTheme.metadata,
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: ProfileTheme.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSwitch extends StatelessWidget {
  const _ProfileSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 38,
    height: 24,
    child: FittedBox(
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: ProfileTheme.white,
        activeTrackColor: ProfileTheme.primary,
        inactiveTrackColor: ProfileTheme.iconSurface,
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
  );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 32,
    color: Theme.of(context).brightness == Brightness.dark
        ? ProfileTheme.border
        : AppColors.lightBorder,
  );
}

class _ProfileForm extends ConsumerWidget {
  const _ProfileForm({required this.profile});
  final UserProfile profile;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var name = profile.name;
    var email = profile.email;
    var phone = profile.phone;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            context.l10n.profileFormTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            initialValue: name,
            decoration: InputDecoration(
              labelText: context.l10n.profileFormName,
            ),
            onChanged: (value) => name = value,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            initialValue: email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: context.l10n.profileFormEmail,
            ),
            onChanged: (value) => email = value,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            initialValue: phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: context.l10n.profileFormPhone,
            ),
            onChanged: (value) => phone = value,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: context.l10n.profileFormSave,
            icon: Icons.save_rounded,
            onPressed: () async {
              final ok = await ref
                  .read(profileProvider.notifier)
                  .updateProfile(name: name, email: email, phone: phone);
              if (ok && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _PasswordForm extends ConsumerStatefulWidget {
  const _PasswordForm();

  @override
  ConsumerState<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends ConsumerState<_PasswordForm> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await ref
        .read(profileProvider.notifier)
        .changePassword(
          currentPassword: _current.text,
          newPassword: _password.text,
          confirmation: _confirmation.text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? ProfileTheme.white : AppColors.lightText;
    final muted = isDark ? ProfileTheme.muted : AppColors.lightMuted;
    final strength = PasswordStrength.of(_password.text);
    final lengthOk = _password.text.length >= 6;
    final mixOk =
        strength == PasswordStrength.medium ||
        strength == PasswordStrength.strong;
    final matchOk =
        _confirmation.text.isNotEmpty && _confirmation.text == _password.text;
    final canSave = _current.text.isNotEmpty && lengthOk && matchOk;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: AutofillGroup(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: ProfileTheme.lockBadgeGradient,
                      borderRadius: ProfileTheme.fieldRadius,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: ProfileTheme.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.passwordFormTitle,
                          style: ProfileTheme.passwordTitle.copyWith(
                            color: text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.passwordFormSubtitle,
                          style: ProfileTheme.passwordSubtitle.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _PasswordField(
                label: l10n.passwordCurrent,
                hint: l10n.passwordCurrentHint,
                controller: _current,
                autofillHint: AutofillHints.password,
                icon: Icons.key_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              _PasswordField(
                label: l10n.passwordNew,
                hint: l10n.passwordNewHint,
                controller: _password,
                autofillHint: AutofillHints.newPassword,
                icon: Icons.lock_outline_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              _StrengthMeter(strength: strength),
              const SizedBox(height: AppSpacing.md),
              _PasswordField(
                label: l10n.passwordConfirm,
                hint: l10n.passwordConfirmHint,
                controller: _confirmation,
                autofillHint: AutofillHints.newPassword,
                icon: Icons.verified_user_outlined,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              _PasswordRule(label: l10n.passwordRuleLength, ok: lengthOk),
              _PasswordRule(label: l10n.passwordRuleMix, ok: mixOk),
              _PasswordRule(label: l10n.passwordRuleMatch, ok: matchOk),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: l10n.passwordFormTitle,
                icon: Icons.lock_reset_rounded,
                isLoading: _submitting,
                onPressed: canSave && !_submitting ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.onChanged,
    required this.autofillHint,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final String autofillHint;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? ProfileTheme.white : AppColors.lightText;
    final muted = isDark ? ProfileTheme.muted : AppColors.lightMuted;
    final border = OutlineInputBorder(
      borderRadius: ProfileTheme.fieldRadius,
      borderSide: BorderSide(
        color: isDark ? ProfileTheme.fieldBorder : AppColors.lightBorder,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: ProfileTheme.fieldLabel.copyWith(color: text),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: widget.controller,
          obscureText: _obscure,
          autofillHints: [widget.autofillHint],
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          onChanged: widget.onChanged,
          style: ProfileTheme.fieldText.copyWith(color: text),
          cursorColor: ProfileTheme.primary,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: ProfileTheme.fieldText.copyWith(color: muted),
            filled: true,
            fillColor: isDark
                ? ProfileTheme.fieldFill
                : AppColors.lightBackground,
            prefixIcon: Icon(widget.icon, size: 20, color: muted),
            suffixIcon: IconButton(
              tooltip: _obscure
                  ? context.l10n.commonShowPassword
                  : context.l10n.commonHidePassword,
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: muted,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: ProfileTheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (level, color, label) = switch (strength) {
      PasswordStrength.empty => (0, ProfileTheme.muted, ''),
      PasswordStrength.weak => (
        1,
        ProfileTheme.strengthWeak,
        l10n.passwordStrengthWeak,
      ),
      PasswordStrength.medium => (
        2,
        ProfileTheme.strengthMedium,
        l10n.passwordStrengthMedium,
      ),
      PasswordStrength.strong => (
        3,
        ProfileTheme.strengthStrong,
        l10n.passwordStrengthStrong,
      ),
    };
    return Semantics(
      label: '${l10n.passwordStrengthLabel}: $label',
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                decoration: BoxDecoration(
                  color: i < level ? color : ProfileTheme.strengthTrack,
                  borderRadius: ProfileTheme.pillRadius,
                ),
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 56,
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: ProfileTheme.ruleText.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordRule extends StatelessWidget {
  const _PasswordRule({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? ProfileTheme.muted : AppColors.lightMuted;
    final text = isDark ? ProfileTheme.white : AppColors.lightText;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: ok ? ProfileTheme.strengthStrong : muted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: ProfileTheme.ruleText.copyWith(color: ok ? text : muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankForm extends ConsumerStatefulWidget {
  const _BankForm({required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<_BankForm> createState() => _BankFormState();
}

class _BankFormState extends ConsumerState<_BankForm> {
  static const _banks = [
    'BCA',
    'BNI',
    'BRI',
    'Mandiri',
    'BSI',
    'CIMB Niaga',
    'Permata',
    'Danamon',
    'BTN',
    'OCBC',
  ];

  late String _bank;
  late final TextEditingController _number;
  late final TextEditingController _holder;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _bank = profile.bankName.isNotEmpty ? profile.bankName : _banks.first;
    _number = TextEditingController(text: profile.bankAccountNumber);
    _holder = TextEditingController(
      text: profile.bankAccountName.isNotEmpty
          ? profile.bankAccountName
          : profile.name,
    );
  }

  @override
  void dispose() {
    _number.dispose();
    _holder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(profileProvider).value?.isSaving ?? false;
    final message = ref.watch(profileProvider).value?.message;
    final banks = {..._banks, _bank}.toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            context.l10n.profileBankAccount,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.bankFormHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _bank,
            decoration: InputDecoration(labelText: context.l10n.bankFormBank),
            items: [
              for (final bank in banks)
                DropdownMenuItem(value: bank, child: Text(bank)),
            ],
            onChanged: (value) => setState(() => _bank = value ?? _bank),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _number,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.l10n.bankFormNumber),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _holder,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: context.l10n.bankFormHolder),
          ),
          if (message != null && !saving) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: saving
                ? context.l10n.commonSaving
                : context.l10n.bankFormSave,
            icon: Icons.save_rounded,
            onPressed: saving
                ? null
                : () async {
                    final ok = await ref
                        .read(profileProvider.notifier)
                        .updateBankAccount(
                          bankName: _bank,
                          accountNumber: _number.text,
                          accountName: _holder.text,
                        );
                    if (ok && context.mounted) Navigator.pop(context);
                  },
          ),
        ],
      ),
    );
  }
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? ProfileTheme.white : AppColors.lightText;
    final muted = dark ? ProfileTheme.muted : AppColors.lightMuted;
    final current = ref.watch(localeProvider).languageCode;

    void select(String code) {
      ref.read(localeProvider.notifier).setLocale(Locale(code));
      Navigator.pop(context);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.4),
                borderRadius: ProfileTheme.pillRadius,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ProfileTheme.primary.withValues(alpha: 0.16),
                  borderRadius: ProfileTheme.iconRadius,
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: ProfileTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.compact),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.languagePickerTitle,
                      style: ProfileTheme.sheetTitle.copyWith(color: text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.languagePickerSubtitle,
                      style: ProfileTheme.optionSub.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _LanguageOption(
            code: 'ID',
            badge: ProfileTheme.badgeIdGradient,
            badgeTextColor: ProfileTheme.ink,
            title: l10n.languageIndonesianTitle,
            subtitle: l10n.languageIndonesianSub,
            selected: current == 'id',
            onTap: () => select('id'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _LanguageOption(
            code: 'EN',
            badge: ProfileTheme.badgeEnGradient,
            badgeTextColor: ProfileTheme.white,
            title: l10n.languageEnglish,
            subtitle: l10n.languageEnglishSub,
            selected: current == 'en',
            onTap: () => select('en'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.languagePickerHint,
                  style: ProfileTheme.metadata.copyWith(color: muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.code,
    required this.badge,
    required this.badgeTextColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final Gradient badge;
  final Color badgeTextColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? ProfileTheme.white : AppColors.lightText;
    final muted = dark ? ProfileTheme.muted : AppColors.lightMuted;
    final surface = dark ? ProfileTheme.surface : AppColors.lightBackground;
    final border = dark ? ProfileTheme.border : AppColors.lightBorder;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: selected ? ProfileTheme.optionSelectedFill : surface,
        shape: RoundedRectangleBorder(
          borderRadius: ProfileTheme.optionRadius,
          side: BorderSide(
            color: selected ? ProfileTheme.primary : border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: ProfileTheme.optionRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.compact),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: badge,
                    shape: BoxShape.circle,
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    code,
                    style: ProfileTheme.badgeText.copyWith(
                      color: badgeTextColor,
                      shadows: const [
                        Shadow(color: ProfileTheme.badgeShadow, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.compact),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ProfileTheme.optionTitle.copyWith(color: text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: ProfileTheme.optionSub.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? ProfileTheme.primary
                        : AppColors.transparent,
                    border: Border.all(
                      color: selected ? ProfileTheme.primary : muted,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: ProfileTheme.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
