import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/login_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secure_screen.dart';
import 'model.dart';
import 'provider.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    final form = ref.read(loginFormProvider);
    _emailController.text = form.email;
    _passwordController.text = form.password;
  }

  @override
  void dispose() {
    _passwordController.clear();
    _emailController.dispose();
    _passwordController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _expandSheet() {
    if (!_sheetController.isAttached || _sheetController.size >= 0.85) return;
    _sheetController.animateTo(
      0.85,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleSheet(double initialSize, ScrollController scrollController) {
    if (!_sheetController.isAttached) return;
    final collapse = _sheetController.size > initialSize + 0.05;
    if (collapse) {
      FocusScope.of(context).unfocus();
      if (scrollController.hasClients) scrollController.jumpTo(0);
    }
    _sheetController.animateTo(
      collapse ? initialSize : 0.85,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _dragSheet(double dy, double maxHeight, double initialSize) {
    if (!_sheetController.isAttached || maxHeight <= 0) return;
    final next = (_sheetController.size - dy / maxHeight)
        .clamp(initialSize, 0.95)
        .toDouble();
    _sheetController.jumpTo(next);
  }

  void _settleSheet(
    double velocity,
    double initialSize,
    ScrollController scrollController,
  ) {
    if (!_sheetController.isAttached) return;
    final size = _sheetController.size;
    final double target;
    if (velocity < -300) {
      target = size < 0.85 ? 0.85 : 0.95;
    } else if (velocity > 300) {
      target = initialSize;
    } else {
      final stops = [initialSize, 0.85, 0.95];
      target = stops.reduce(
        (a, b) => (size - a).abs() <= (size - b).abs() ? a : b,
      );
    }
    if (target == initialSize) {
      FocusScope.of(context).unfocus();
      if (scrollController.hasClients) scrollController.jumpTo(0);
    }
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final form = ref.watch(loginFormProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SecureScreen(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: isDark
            ? LoginTheme.background.first
            : LoginTheme.white,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? LoginTheme.background
                  : const [LoginTheme.white, LoginTheme.white],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final initial =
                    ((350 + MediaQuery.paddingOf(context).bottom) /
                            constraints.maxHeight)
                        .clamp(0.42, 0.72)
                        .toDouble();
                return Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: _showCustomerService,
                            style: TextButton.styleFrom(
                              padding: LoginTheme.supportPadding,
                              minimumSize: const Size(0, AppSizes.touchTarget),
                              shape: LoginTheme.supportShape,
                              foregroundColor: isDark
                                  ? LoginTheme.white
                                  : LoginTheme.brand,
                            ),
                            icon: const Icon(
                              Icons.headset_mic_outlined,
                              size: 24,
                            ),
                            label: Text(
                              context.l10n.loginSupport,
                              style: LoginTheme.support.copyWith(
                                color: isDark
                                    ? LoginTheme.muted
                                    : LoginTheme.ink,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: context.l10n.loginToggleTheme,
                            onPressed: ref
                                .read(themeModeProvider.notifier)
                                .toggle,
                            color: isDark ? LoginTheme.white : LoginTheme.brand,
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: constraints.maxHeight * 0.24,
                      left: 16,
                      right: 16,
                      child: Column(
                        children: [
                          const _LoginBrand(),
                          const SizedBox(height: 46),
                          Text(
                            context.l10n.loginWelcome,
                            textAlign: TextAlign.center,
                            style: LoginTheme.heading.copyWith(
                              color: isDark ? LoginTheme.white : LoginTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.loginTagline,
                            textAlign: TextAlign.center,
                            style: LoginTheme.description.copyWith(
                              color: isDark
                                  ? LoginTheme.darkMuted
                                  : LoginTheme.lightMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DraggableScrollableSheet(
                      controller: _sheetController,
                      initialChildSize: initial,
                      minChildSize: initial,
                      maxChildSize: 0.95,
                      snap: true,
                      snapSizes: [initial, 0.85, 0.95],
                      builder: (context, controller) => Container(
                        key: const ValueKey('login-sheet'),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? LoginTheme.darkPanel
                                : LoginTheme.lightPanel,
                          ),
                          borderRadius: LoginTheme.panelRadius,
                          border: Border.all(
                            color: LoginTheme.border,
                            width: 0.7,
                          ),
                        ),
                        child: SingleChildScrollView(
                          controller: controller,
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            18,
                            0,
                            18,
                            12 +
                                MediaQuery.paddingOf(context).bottom +
                                MediaQuery.viewInsetsOf(context).bottom,
                          ),
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Semantics(
                                  label: context.l10n.loginToggleSheet,
                                  button: true,
                                  onTap: () =>
                                      _toggleSheet(initial, controller),
                                  child: GestureDetector(
                                    key: const ValueKey('login-sheet-toggle'),
                                    onVerticalDragUpdate: (d) => _dragSheet(
                                      d.primaryDelta ?? 0,
                                      constraints.maxHeight,
                                      initial,
                                    ),
                                    onVerticalDragEnd: (d) => _settleSheet(
                                      d.primaryVelocity ?? 0,
                                      initial,
                                      controller,
                                    ),
                                    behavior: HitTestBehavior.opaque,
                                    child: SizedBox(
                                      height: 40,
                                      child: Align(
                                        alignment: const Alignment(0, -0.55),
                                        child: Container(
                                          width: 38,
                                          height: 5,
                                          decoration: const BoxDecoration(
                                            color: LoginTheme.handle,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(AppRadius.pill),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _LoginLabel(context.l10n.loginEmail),
                                _LoginField(
                                  controller: _emailController,
                                  onTap: _expandSheet,
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  onChanged: ref
                                      .read(loginFormProvider.notifier)
                                      .setEmail,
                                ),
                                const SizedBox(height: AppSpacing.compact),
                                _LoginLabel(context.l10n.loginPassword),
                                _LoginField(
                                  controller: _passwordController,
                                  onTap: _expandSheet,
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: form.obscurePassword,
                                  autofillHints: const [AutofillHints.password],
                                  onChanged: ref
                                      .read(loginFormProvider.notifier)
                                      .setPassword,
                                  onSubmitted: (_) => _submit(),
                                  suffixIcon: IconButton(
                                    tooltip: form.obscurePassword
                                        ? context.l10n.commonShowPassword
                                        : context.l10n.commonHidePassword,
                                    onPressed: ref
                                        .read(loginFormProvider.notifier)
                                        .togglePassword,
                                    icon: Icon(
                                      form.obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: LoginTheme.muted,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: _forgotPassword,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.only(
                                        top: 6,
                                        bottom: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      context.l10n.loginForgot,
                                      style: LoginTheme.forgot,
                                    ),
                                  ),
                                ),
                                Text.rich(
                                  TextSpan(
                                    text: context.l10n.loginConsent,
                                    children: [
                                      TextSpan(
                                        text: context.l10n.loginTerms,
                                        style: LoginTheme.link,
                                      ),
                                      TextSpan(text: ' & '),
                                      TextSpan(
                                        text: context.l10n.loginPrivacy,
                                        style: LoginTheme.link,
                                      ),
                                      TextSpan(text: '.'),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  style: LoginTheme.consent,
                                ),
                                if (auth.errorMessage case final message?) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      message,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.md),
                                SizedBox(
                                  height: 50,
                                  child: FilledButton.icon(
                                    onPressed: auth.isLoading ? null : _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: LoginTheme.green,
                                      foregroundColor: LoginTheme.white,
                                      disabledBackgroundColor: LoginTheme.green
                                          .withValues(alpha: 0.5),
                                      shape: const StadiumBorder(),
                                    ),
                                    iconAlignment: IconAlignment.end,
                                    icon: auth.isLoading
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: LoginTheme.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.arrow_forward_rounded,
                                          ),
                                    label: Text(
                                      context.l10n.loginSubmit,
                                      style: LoginTheme.button,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                const Text(
                                  '©2026 Jahris mobile-v1.0.0 · Jaxer Grup Indonesia',
                                  textAlign: TextAlign.center,
                                  style: LoginTheme.copyright,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomerService() async {
    try {
      final opened = await launchUrl(
        Env.customerServiceUrl,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (opened) return;
    } catch (_) {
      // Tampilkan petunjuk jika browser atau aplikasi WhatsApp gagal dibuka.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.loginWhatsappError('081511496687'))),
    );
  }

  Future<void> _submit() async {
    if (ref.read(authProvider).isLoading) return;
    FocusScope.of(context).unfocus();
    final form = ref.read(loginFormProvider.notifier);
    form.setEmail(_emailController.text);
    form.setPassword(_passwordController.text);
    await ref.read(authProvider.notifier).login();
    if (!mounted) return;
    _passwordController.clear();
  }

  Future<void> _forgotPassword() async {
    ref.read(loginFormProvider.notifier).setEmail(_emailController.text);
    final sent = await ref.read(authProvider.notifier).forgotPassword();
    if (!mounted || !sent) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.loginResetSent)));
  }
}

class _LoginLabel extends StatelessWidget {
  const _LoginLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(text, style: LoginTheme.label),
  );
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.icon,
    required this.onChanged,
    required this.onTap,
    this.autofillHints,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofillHints: autofillHints,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    obscureText: obscureText,
    autocorrect: false,
    enableSuggestions: false,
    enableIMEPersonalizedLearning: false,
    onChanged: onChanged,
    onTap: onTap,
    scrollPadding: const EdgeInsets.all(24),
    onSubmitted: onSubmitted,
    style: LoginTheme.input,
    decoration: InputDecoration(
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? LoginTheme.field
          : LoginTheme.fieldLight,
      constraints: const BoxConstraints(minHeight: 50),
      isDense: true,
      border: LoginTheme.fieldOutline,
      enabledBorder: LoginTheme.fieldOutline,
      focusedBorder: LoginTheme.fieldFocusedOutline,
      prefixIcon: Icon(icon, color: LoginTheme.white, size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
    ),
  );
}

class RequiredPasswordChangeView extends ConsumerStatefulWidget {
  const RequiredPasswordChangeView({super.key});

  @override
  ConsumerState<RequiredPasswordChangeView> createState() =>
      _RequiredPasswordChangeViewState();
}

class _RequiredPasswordChangeViewState
    extends ConsumerState<RequiredPasswordChangeView> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirmation = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPassword.clear();
    _newPassword.clear();
    _confirmation.clear();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SecureScreen(
    child: Scaffold(
      appBar: AppBar(title: Text(context.l10n.forcePasswordTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              context.l10n.forcePasswordHeading,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.forcePasswordBody,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AuthPasswordField(
                      controller: _currentPassword,
                      label: context.l10n.passwordCurrent,
                      obscure: _obscureCurrent,
                      onToggle: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: (value) => value == null || value.isEmpty
                          ? context.l10n.forcePasswordCurrentRequired
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AuthPasswordField(
                      controller: _newPassword,
                      label: context.l10n.passwordNew,
                      obscure: _obscureNew,
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      validator: Validators.employeePassword,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AuthPasswordField(
                      controller: _confirmation,
                      label: context.l10n.passwordConfirm,
                      obscure: _obscureConfirmation,
                      onToggle: () => setState(
                        () => _obscureConfirmation = !_obscureConfirmation,
                      ),
                      validator: (value) => Validators.passwordConfirmation(
                        value,
                        _newPassword.text,
                      ),
                    ),
                    if (_errorMessage case final message?) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        message,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: context.l10n.forcePasswordSave,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _submit,
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final error = await ref
        .read(authProvider.notifier)
        .changeRequiredPassword(
          currentPassword: _currentPassword.text,
          newPassword: _newPassword.text,
          confirmation: _confirmation.text,
        );
    _currentPassword.clear();
    _newPassword.clear();
    _confirmation.clear();
    if (!mounted || error == null) return;
    setState(() {
      _isSaving = false;
      _errorMessage = error;
    });
  }
}

class _AuthPasswordField extends StatelessWidget {
  const _AuthPasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscure,
    autocorrect: false,
    enableSuggestions: false,
    enableIMEPersonalizedLearning: false,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        tooltip: obscure
            ? context.l10n.commonShowPassword
            : context.l10n.commonHidePassword,
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );
}

class _LoginBrand extends StatelessWidget {
  const _LoginBrand();

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.logoLabel,
    image: true,
    child: SizedBox(
      width: 60,
      height: 56,
      child: CustomPaint(
        painter: _LoginLogoPainter(
          Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    ),
  );
}

class _LoginLogoPainter extends CustomPainter {
  const _LoginLogoPainter(this.isDark);
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height * 0.97)
      ..lineTo(size.width * 0.84, size.height)
      ..lineTo(size.width * 0.5, size.height * 0.62)
      ..lineTo(size.width * 0.16, size.height)
      ..lineTo(0, size.height * 0.97)
      ..close();
    canvas.drawPath(
      shape,
      Paint()..color = isDark ? LoginTheme.white : LoginTheme.brand,
    );
    for (final side in [0.0, 1.0]) {
      final accent = Path()
        ..moveTo(size.width * side, size.height * 0.97)
        ..lineTo(size.width * 0.5, size.height * 0.62)
        ..lineTo(size.width * (side == 0 ? 0.16 : 0.84), size.height)
        ..close();
      canvas.drawPath(accent, Paint()..color = LoginTheme.green);
    }
  }

  @override
  bool shouldRepaint(_LoginLogoPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Splash sebelum login: tampil minimal [LoginTheme.splashDuration] dan
/// menunggu sesi selesai dicek, lalu pindah ke login (router mengalihkan ke
/// dashboard jika sesi masih aktif).
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  ProviderSubscription<AuthState>? _authSub;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future<void>.delayed(LoginTheme.splashDuration);
    if (!mounted) return;
    if (ref.read(authProvider).status != AuthStatus.checking) {
      _leave();
      return;
    }
    _authSub = ref.listenManual<AuthState>(authProvider, (_, next) {
      if (next.status != AuthStatus.checking) _leave();
    });
  }

  void _leave() {
    if (!mounted || _left) return;
    _left = true;
    ref.read(splashDoneProvider.notifier).markDone();
    context.go('/login');
  }

  @override
  void dispose() {
    _authSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? LoginTheme.white : LoginTheme.ink;
    return Scaffold(
      backgroundColor: isDark
          ? LoginTheme.splashDark.first
          : LoginTheme.splashLight.first,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? LoginTheme.splashDark : LoginTheme.splashLight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.9 + 0.1 * value,
                        child: child,
                      ),
                    ),
                    child: Semantics(
                      label: context.l10n.logoLabel,
                      image: true,
                      child: SizedBox.fromSize(
                        size: LoginTheme.splashLogoSize,
                        child: CustomPaint(painter: _LoginLogoPainter(isDark)),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.splashPoweredBy,
                      style: LoginTheme.poweredBy.copyWith(color: foreground),
                    ),
                    const SizedBox(height: 4),
                    Image.asset(
                      isDark
                          ? 'assets/images/jaxer_logo_white.png'
                          : 'assets/images/jaxer_logo_black.png',
                      height: 28,
                      semanticLabel: 'Jaxer Teknologi Indonesia',
                      filterQuality: FilterQuality.medium,
                    ),
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
