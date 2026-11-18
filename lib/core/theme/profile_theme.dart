import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class ProfileTheme {
  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF080E28), Color(0xFF1A2859)],
    stops: [0, 0.7],
  );
  static const surface = Color(0xFF25315B);
  static const border = Color(0xFF384365);
  static const muted = Color(0xFF99A5C0);
  static const iconSurface = Color(0xFF344062);
  static const white = AppColors.onPrimary;
  static const ink = Color(0xFF080D24);
  static const primary = Color(0xFF215CFF);
  static const chipText = Color(0xFF89AAFF);
  static const chipSurface = Color(0xFF25376B);
  static const danger = Color(0xFFFF677F);
  static const logoutSurface = Color(0xFF332B50);
  static const logoutBorder = Color(0xFF7B375C);
  static const sheetSurface = Color(0xFF151E40);
  // Sheet ubah password
  static const fieldFill = Color(0xFF1E2850);
  static const fieldBorder = Color(0xFF34406C);
  static const fieldRadius = BorderRadius.all(Radius.circular(14));
  static const lockBadgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B7BFF), Color(0xFF1F4FE0)],
  );
  static const strengthTrack = Color(0xFF2C3762);
  static const strengthWeak = Color(0xFFFF677F);
  static const strengthMedium = Color(0xFFF7B733);
  static const strengthStrong = Color(0xFF34D399);
  static const passwordTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );
  static const passwordSubtitle = TextStyle(
    fontSize: 12,
    height: 1.4,
    color: muted,
  );
  static const fieldLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const fieldText = TextStyle(fontSize: 14);
  static const ruleText = TextStyle(fontSize: 12);
  static const badgeShadow = Color(0x40000000);
  static const sheetRadius = BorderRadius.vertical(top: Radius.circular(24));
  static const optionRadius = BorderRadius.all(Radius.circular(16));
  static const optionSelectedFill = Color(0x262463FF);
  static const badgeIdGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE5394B),
      Color(0xFFE5394B),
      Color(0xFFF4F6FF),
      Color(0xFFF4F6FF),
    ],
    stops: [0, 0.5, 0.5, 1],
  );
  static const badgeEnGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B4AA8), Color(0xFF1B2F73)],
  );
  static const sheetTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );
  static const optionTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
  static const optionSub = TextStyle(fontSize: 12, color: muted);
  static const badgeText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );
  static const cardRadius = BorderRadius.all(Radius.circular(18));
  static const iconRadius = BorderRadius.all(Radius.circular(8));
  static const pillRadius = BorderRadius.all(Radius.circular(AppRadius.pill));
  static const pagePadding = EdgeInsets.fromLTRB(12, 12, 12, 0);
  static const heading = TextStyle(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );
  static const initials = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w600,
    color: ink,
  );
  static const name = TextStyle(
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );
  static const role = TextStyle(fontSize: 11, height: 1.3, color: muted);
  static const nik = TextStyle(fontSize: 10, height: 1.2, color: chipText);
  static const stat = TextStyle(
    fontSize: 17,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );
  static const statLabel = TextStyle(fontSize: 10, height: 1.3, color: muted);
  static const section = TextStyle(fontSize: 9, height: 1.3, color: muted);
  static const menu = TextStyle(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );
  static const metadata = TextStyle(fontSize: 11, height: 1.3, color: muted);
  static const logout = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
}
