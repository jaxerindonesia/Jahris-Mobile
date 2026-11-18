import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/dashboard_theme.dart';
import '../theme/theme_provider.dart';
import 'jahris_mark.dart';

class AppHeader extends ConsumerWidget {
  const AppHeader({
    required this.onMenuPressed,
    this.onNotificationPressed,
    this.onSearchPressed,
    this.notificationCount = 0,
    this.profileMode = false,
    this.userName,
    this.role,
    this.tenantName,
    super.key,
  });

  final VoidCallback onMenuPressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onSearchPressed;
  final int notificationCount;
  final bool profileMode;
  final String? userName;
  final String? role;
  final String? tenantName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (profileMode) {
      return Row(
        children: [
          const _LogoMark(size: 28),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${_firstName(userName)} 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardTheme.greeting,
                ),
                Text(
                  'Jahris',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardTheme.company,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: onNotificationPressed,
            icon: Badge(
              isLabelVisible: notificationCount > 0,
              smallSize: 5,
              child: const _NotificationIcon(),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Tooltip(
            message: 'Buka menu',
            child: InkWell(
              onTap: onMenuPressed,
              customBorder: const CircleBorder(),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DashboardTheme.white,
                ),
                child: Text(
                  _initials(userName),
                  style: DashboardTheme.initials,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        const _JaxerLogo(),
        const Spacer(),
        if (onNotificationPressed != null) ...[
          Badge(
            isLabelVisible: notificationCount > 0,
            label: Text(notificationCount > 99 ? '99+' : '$notificationCount'),
            child: IconButton(
              tooltip: 'Notifikasi',
              onPressed: onNotificationPressed,
              icon: const _NotificationIcon(),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        IconButton(
          tooltip: isDark ? 'Gunakan mode terang' : 'Gunakan mode gelap',
          onPressed: ref.read(themeModeProvider.notifier).toggle,
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filled(
          tooltip: 'Buka menu',
          onPressed: onMenuPressed,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.menu_rounded),
        ),
      ],
    );
  }

  String _firstName(String? value) {
    final name = value?.trim();
    if (name == null || name.isEmpty) return 'Ahmad';
    return name.split(RegExp(r'\s+')).first;
  }

  String _initials(String? value) {
    final parts = value
        ?.trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts == null || parts.isEmpty) return 'AY';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon();

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/notification.svg',
    width: 22,
    height: 22,
    colorFilter: ColorFilter.mode(
      Theme.of(context).colorScheme.onSurface,
      BlendMode.srcIn,
    ),
  );
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(AppSpacing.xs),
    decoration: BoxDecoration(
      color: DashboardTheme.white,
      borderRadius: DashboardTheme.logoRadius,
    ),
    child: Semantics(
      label: 'Logo JAHRIS',
      image: true,
      child: const JahrisMark(),
    ),
  );
}

class _JaxerLogo extends StatelessWidget {
  const _JaxerLogo();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'JAHRIS',
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const SizedBox.square(
              dimension: 36,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Image(
                  image: AssetImage('assets/images/icon_jahris_white.webp'),
                  fit: BoxFit.contain,
                  semanticLabel: 'Logo JAHRIS',
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'JAHRIS',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(letterSpacing: 1.8, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
