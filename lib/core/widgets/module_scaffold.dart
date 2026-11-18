import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../modules/auth/model.dart';
import '../../modules/auth/provider.dart';
import '../../modules/notification/provider.dart';
import '../theme/app_colors.dart';
import '../theme/dashboard_theme.dart';
import '../theme/theme_provider.dart';
import 'app_header.dart';
import 'floating_bottom_nav.dart';

class ModuleScaffold extends ConsumerWidget {
  const ModuleScaffold({
    required this.title,
    required this.body,
    this.currentIndex,
    this.notificationCount = 0,
    this.floatingActionButton,
    this.subtitle,
    this.profileHeader = false,
    this.showAppHeader = true,
    this.showPageHeading = true,
    this.showBackButton = false,
    this.backgroundGradient,
    this.contentPadding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      0,
    ),
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final int? currentIndex;
  final int notificationCount;
  final Widget? floatingActionButton;
  final bool profileHeader;
  final bool showAppHeader;
  final bool showPageHeading;
  final bool showBackButton;
  final Gradient? backgroundGradient;
  final EdgeInsetsGeometry contentPadding;

  static const navPaths = ['/dashboard', '/attendance', '/task', '/profile'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final unreadCount = notificationCount > 0
        ? notificationCount
        : ref.watch(notificationProvider).value?.unreadCount ?? 0;
    return Scaffold(
      extendBody: currentIndex != null,
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? backgroundGradient ??
                    (profileHeader
                        ? DashboardTheme.background
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.darkBackground,
                              AppColors.darkGradientMiddle,
                              AppColors.darkGradientEnd,
                            ],
                            stops: [0, 0.46, 1],
                          ))
              : null,
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showAppHeader) ...[
                  AppHeader(
                    notificationCount: unreadCount,
                    profileMode: profileHeader,
                    userName: user?.name,
                    role: user?.role,
                    tenantName: user?.tenantName,
                    onSearchPressed: profileHeader
                        ? () => context.push('/employees')
                        : null,
                    onNotificationPressed: () => context.push('/notifications'),
                    onMenuPressed: () => _openMenu(context, ref, user),
                  ),
                  SizedBox(
                    height: profileHeader ? AppSpacing.md : AppSpacing.lg,
                  ),
                ],
                if (showPageHeading) ...[
                  if (showBackButton)
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Kembali',
                          onPressed: context.pop,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: AppSizes.touchTarget),
                      ],
                    )
                  else
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  if (subtitle case final value?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(value, style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: currentIndex == null
          ? null
          : FloatingBottomNav(
              currentIndex: currentIndex!,
              notificationCount: unreadCount,
              onSelected: (index) => context.go(navPaths[index]),
            ),
    );
  }

  Future<void> _openMenu(BuildContext context, WidgetRef ref, AuthUser? user) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => _AppMenu(
        user: user,
        onLogout: ref.read(authProvider.notifier).logout,
        onToggleTheme: ref.read(themeModeProvider.notifier).toggle,
      ),
    );
  }
}

class _AppMenu extends StatelessWidget {
  const _AppMenu({
    required this.user,
    required this.onLogout,
    required this.onToggleTheme,
  });

  final AuthUser? user;
  final Future<void> Function() onLogout;
  final VoidCallback onToggleTheme;

  bool get _isAdmin => user?.role.toLowerCase().contains('admin') ?? false;

  @override
  Widget build(BuildContext context) {
    void open(String path) {
      Navigator.of(context).pop();
      context.push(path);
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: () => open('/profile'),
          leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
          title: Text(user?.name ?? 'Pengguna JAHRIS'),
          subtitle: Text(
            '${user?.role ?? 'Karyawan'} • ${user?.tenantName ?? 'JAHRIS'}',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
        const Divider(),
        if (_isAdmin) ...[
          _MenuTile(Icons.groups_rounded, 'Karyawan', () => open('/employees')),
          _MenuTile(Icons.business_rounded, 'Cabang', () => open('/branches')),
        ],
        _MenuTile(Icons.payments_rounded, 'Slip Gaji', () => open('/payroll')),
        if (_isAdmin)
          _MenuTile(
            Icons.settings_rounded,
            'Kelola Payroll',
            () => open('/payroll/manage'),
          ),
        _MenuTile(Icons.more_time_rounded, 'Lembur', () => open('/overtimes')),
        if (_isAdmin)
          _MenuTile(
            Icons.account_balance_wallet_rounded,
            'Petty Cash',
            () => open('/pettycash'),
          ),
        if (_isAdmin)
          _MenuTile(
            Icons.insights_rounded,
            'Performa',
            () => open('/performances'),
          ),
        _MenuTile(Icons.task_alt_rounded, 'Tugas', () => open('/task')),
        _MenuTile(
          Icons.receipt_long_rounded,
          'Reimburse',
          () => open('/reimburse'),
        ),
        if (_isAdmin)
          _MenuTile(
            Icons.settings_accessibility_rounded,
            'Pengaturan Kehadiran',
            () => open('/attendance/config'),
          ),
        _MenuTile(
          Icons.notifications_rounded,
          'Notifikasi',
          () => open('/notifications'),
        ),
        _MenuTile(
          Theme.of(context).brightness == Brightness.dark
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          Theme.of(context).brightness == Brightness.dark
              ? 'Mode Terang'
              : 'Mode Gelap',
          () {
            onToggleTheme();
            Navigator.of(context).pop();
          },
        ),
        _MenuTile(
          Icons.swap_horiz_rounded,
          'Ganti Tenant',
          () => open('/profile?tenant=true'),
        ),
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
          title: const Text(
            'Keluar',
            style: TextStyle(color: AppColors.danger),
          ),
          onTap: () async {
            Navigator.of(context).pop();
            await onLogout();
          },
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
