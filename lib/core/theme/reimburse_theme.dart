import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Token desain halaman Reimburse (Stitch).
abstract final class ReimburseTheme {
  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1230), Color(0xFF18295E)],
  );
  static const primary = Color(0xFF2463FF);
  static const white = AppColors.onPrimary;
  static const muted = Color(0xFF95A0BD);
  static const surface = Color(0xFF222D57);
  static const border = Color(0xFF34406C);
  static const summaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF243466), Color(0xFF1B2754)],
  );
  static const iconFill = Color(0xFF243A7A);
  static const icon = Color(0xFF8FB0FF);
  static const approved = Color(0xFF4CEBA9);
  static const pending = Color(0xFFF7B733);
  static const rejected = Color(0xFFFF6C7D);

  // Bottom sheet form pengajuan.
  static const sheet = Color(0xFF111B3F);
  static const sheetField = Color(0xFF1C2852);
  static const sheetFieldBorder = Color(0xFF2E3B6B);
  static const sheetHandle = Color(0xFF3A4675);
  static const lightSheet = Color(0xFFFFFFFF);
  static const lightSheetField = Color(0xFFF3F5FB);
  static const lightSheetFieldBorder = Color(0xFFE1E6F2);
  static const lightSheetHandle = Color(0xFFD3DAEA);
  static const lightIconFill = Color(0xFFE6EDFF);

  static const sheetRadius = BorderRadius.vertical(top: Radius.circular(28));
  static const fieldRadius = BorderRadius.all(Radius.circular(16));

  static const sheetTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );
  static const sheetSubtitle = TextStyle(fontSize: 12.5);
  static const fieldLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
  static const amountInput = TextStyle(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );
  static const fieldValue = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const fieldHint = TextStyle(fontSize: 12);

  static const cardRadius = BorderRadius.all(Radius.circular(18));
  static const iconRadius = BorderRadius.all(Radius.circular(10));
  static const pillRadius = BorderRadius.all(Radius.circular(AppRadius.pill));

  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const summaryLabel = TextStyle(fontSize: 12, color: muted);
  static const summaryValue = TextStyle(
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );
  static const chip = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
  static const section = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const rowTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const rowDate = TextStyle(fontSize: 11, color: muted);
  static const amount = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: white,
  );
  static const status = TextStyle(fontSize: 10, fontWeight: FontWeight.w600);
  static const button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: white,
  );
}
