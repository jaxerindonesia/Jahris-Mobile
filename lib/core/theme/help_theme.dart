import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Token desain halaman Bantuan (Stitch).
abstract final class HelpTheme {
  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E1638), Color(0xFF1A2A66)],
  );
  static const primary = Color(0xFF2463FF);
  static const white = AppColors.onPrimary;
  static const muted = Color(0xFF95A0BD);
  static const surface = Color(0xFF222E5E);
  static const border = Color(0xFF3A4678);
  static const divider = Color(0x1FFFFFFF);
  static const chevron = Color(0xFF8FA6E8);

  static const absensi = Color(0xFF4CEBA9);
  static const cuti = Color(0xFF8FB0FF);
  static const gaji = Color(0xFFF7B733);
  static const akun = Color(0xFFFF7C8E);

  static const contactGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F3888), Color(0xFF172B6A)],
  );
  static const secondaryButton = Color(0xFF15214F);
  static const contactBorder = Color(0xFF3B62D6);

  static const cardRadius = BorderRadius.all(Radius.circular(20));
  static const tileRadius = BorderRadius.all(Radius.circular(18));

  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: white,
  );
  static const search = TextStyle(fontSize: 14, color: white);
  static const categoryLabel = TextStyle(
    fontSize: 12,
    color: Color(0xFFD5DCF0),
  );
  static const section = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const question = TextStyle(fontSize: 14, color: Color(0xFFD5DCF0));
  static const questionOpen = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const answer = TextStyle(fontSize: 13, height: 1.5, color: muted);
  static const contactTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: white,
  );
  static const contactCaption = TextStyle(fontSize: 12, color: muted);
  static const button = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
}
