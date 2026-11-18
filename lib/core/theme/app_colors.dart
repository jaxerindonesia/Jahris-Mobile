import 'package:flutter/material.dart';

abstract final class AppColors {
  // JAHRIS mobile brand palette from the supplied dark UI references.
  static const primary = Color(0xFF2463FF);
  static const success = Color(0xFF00D26A);
  static const warning = Color(0xFFF3A51F);
  static const purple = Color(0xFF8B5CF6);
  static const info = Color(0xFF38BDF8);
  static const danger = Color(0xFFEF4444);
  // Gradient dashboard mengikuti artwork Figma yang diberikan pengguna.
  static const darkBackground = Color(0xFF03081E);
  static const darkGradientMiddle = Color(0xFF08213F);
  static const darkGradientEnd = Color(0xFF1B2D68);
  static const darkSurface = Color(0xE6263567);
  static const darkSurfaceRaised = Color(0xFF263567);
  static const darkNavSurface = Color(0xF2263567);
  static const darkSurfaceInset = Color(0xB307102B);
  static const servicesSurface = Color(0xFF263567);
  static const highlightSurface = Color(0xFF183A86);
  static const darkText = Color(0xFFF8FAFC);
  static const darkMuted = Color(0xFF94A3B8);
  static const lightBackground = Color(0xFFF4F6FF);
  static const lightGradientEnd = Color(0xFFE7ECFF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF0B1642);
  static const lightMuted = Color(0xFF687291);
  static const lightBorder = Color(0xFFDCE3FA);
  static const transparent = Colors.transparent;
}

abstract final class AppRadius {
  static const small = 4.0;
  static const medium = 12.0;
  static const card = 20.0;
  static const nav = 28.0;
  static const logo = 18.0;
  static const pill = 999.0;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const compact = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const navClearance = 84.0;
}

abstract final class AppSizes {
  static const touchTarget = 48.0;
  static const icon = 24.0;
  static const iconSmall = 18.0;
  static const iconLarge = 32.0;
  static const avatar = 44.0;
  static const avatarSmall = 36.0;
  static const gauge = 128.0;
  static const quickAction = 72.0;
  static const progress = 8.0;
  static const navHeight = 60.0;
  static const navOuterHeight = 70.0;
  static const navCenterButton = 58.0;
  static const navIndicator = 3.0;
  static const navIcon = 26.0;
  static const skeletonLine = 14.0;
}

/// Membuat warna aksen neon tetap terbaca di mode terang.
extension AccentContrast on Color {
  /// Di mode gelap warna dikembalikan apa adanya; di mode terang warna
  /// digelapkan agar kontras di atas latar putih.
  Color readable(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) return this;
    final hsl = HSLColor.fromColor(this);
    if (hsl.lightness <= 0.45) return this;
    return hsl
        .withLightness(0.40)
        .withSaturation((hsl.saturation * 0.9).clamp(0, 1).toDouble())
        .toColor();
  }

  /// Isian lembut untuk latar chip/ikon di mode terang.
  Color softFill(BuildContext context, {double darkAlpha = 0.2}) => withValues(
    alpha: Theme.of(context).brightness == Brightness.dark ? darkAlpha : 0.14,
  );
}
