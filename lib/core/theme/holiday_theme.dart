import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Token desain halaman Kalender Libur (Stitch).
abstract final class HolidayTheme {
  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1230), Color(0xFF18295E)],
  );
  static const white = AppColors.onPrimary;
  static const muted = Color(0xFF95A0BD);
  static const weekend = Color(0xFF5E6A8C);
  static const surface = Color(0xFF1E2A55);
  static const border = Color(0xFF34406C);

  static const national = Color(0xFFFF6C7D);
  static const nationalFill = Color(0x40FF6C7D);
  static const nationalBadge = Color(0x59D94A5C);
  static const collective = Color(0xFFF7B733);
  static const collectiveFill = Color(0x40F7B733);
  static const collectiveBadge = Color(0x597A5A1E);

  static const cardRadius = BorderRadius.all(Radius.circular(20));
  static const tileRadius = BorderRadius.all(Radius.circular(16));
  static const dateRadius = BorderRadius.all(Radius.circular(10));

  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const month = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const weekday = TextStyle(fontSize: 11, color: muted);
  static const day = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
  static const legend = TextStyle(fontSize: 11, color: muted);
  static const section = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const dateNumber = TextStyle(
    fontSize: 15,
    height: 1.1,
    fontWeight: FontWeight.w800,
  );
  static const dateMonth = TextStyle(fontSize: 9, fontWeight: FontWeight.w500);
  static const rowTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const rowCaption = TextStyle(fontSize: 12, color: muted);
  static const badge = TextStyle(fontSize: 10, fontWeight: FontWeight.w700);
}
