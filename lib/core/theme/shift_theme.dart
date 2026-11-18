import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Token desain halaman Jadwal Shift (Stitch).
abstract final class ShiftTheme {
  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1230), Color(0xFF18295E)],
  );
  static const primary = Color(0xFF2463FF);
  static const surface = Color(0xFF222D57);
  static const border = Color(0xFF34406C);
  static const muted = Color(0xFF95A0BD);
  static const white = AppColors.onPrimary;
  static const dot = Color(0xFF7FA2FF);
  static const morning = Color(0xFF2463FF);
  static const afternoon = Color(0xFFF3A51F);
  static const night = Color(0xFF8B5CF6);
  static const off = Color(0xFF6B7595);
  static const sun = Color(0xFFF7B733);
  static const location = Color(0xFF7FA2FF);
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C3C9A), Color(0xFF13286B)],
  );
  static const heroBorder = Color(0xFF3A5BC0);
  static const heroBadge = Color(0xFF2B4FB8);
  static const heroIconFill = Color(0x33FFFFFF);
  static const heroBadgeText = Color(0xFFC9D6FF);
  static const heroTimeColor = Color(0xFFDDE5FF);

  // Mode terang (Stitch light).
  static const lightBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF3F5FC), Color(0xFFE6EBF8)],
  );
  static const lightText = Color(0xFF0F1A3D);
  static const lightMuted = Color(0xFF7C86A2);
  static const lightChip = Color(0xFFE3E8F4);
  static const lightChipBorder = Color(0xFFD3DAEA);
  static const lightHeaderButton = Color(0xFFE3E8F4);
  static const lightTile = Color(0xFFFFFFFF);
  static const lightTileBorder = Color(0xFFE8ECF5);
  static const lightButtonBorder = Color(0xFFC9D1E3);
  static const lightHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDDE6FF), Color(0xFFD3DEFC)],
  );
  static const lightHeroBorder = Color(0xFF9DB5F5);
  static const lightHeroBadge = Color(0xFFC3D3FF);
  static const lightHeroBadgeText = Color(0xFF2463FF);
  static const lightHeroMeta = Color(0xFF4A5577);
  static const lightHeroIconFill = Color(0xFFE5DDCB);
  static const lightSun = Color(0xFFE09A1A);
  static const lightLocation = Color(0xFF2463FF);

  static const chipRadius = BorderRadius.all(Radius.circular(14));
  static const cardRadius = BorderRadius.all(Radius.circular(20));
  static const tileRadius = BorderRadius.all(Radius.circular(16));
  static const squareButtonRadius = BorderRadius.all(Radius.circular(12));
  static const pillRadius = BorderRadius.all(Radius.circular(AppRadius.pill));

  static const chipHeight = 54.0;
  static const headerButton = 36.0;

  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const weekday = TextStyle(fontSize: 11, color: muted);
  static const day = TextStyle(
    fontSize: 17,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Color(0xFFC9D6FF),
  );
  static const heroTitle = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: white,
  );
  static const heroTime = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFFDDE5FF),
  );
  static const heroMeta = TextStyle(fontSize: 12, color: Color(0xFFC9D6FF));
  static const section = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const tileTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const tileDate = TextStyle(fontSize: 11, color: muted);
  static const tileTime = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: white,
  );
}
