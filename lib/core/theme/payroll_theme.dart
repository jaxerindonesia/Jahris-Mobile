import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Token desain halaman Slip Gaji (Stitch).
abstract final class PayrollTheme {
  static const lightBackground = Color(0xFFEDF1FB);
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
  static const divider = Color(0x1FFFFFFF);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C6AFF), Color(0xFF1840C8)],
  );
  static const heroCaption = Color(0xFFDBE5FF);
  static const heroBadge = Color(0x33FFFFFF);
  static const pdfText = Color(0xFF1840C8);

  static const earning = Color(0xFF4CEBA9);
  static const deduction = Color(0xFFFF6C7D);
  static const lightEarning = Color(0xFF00AA55);
  static const lightDeduction = Color(0xFFFF3B45);
  static const fileFill = Color(0xFF243A7A);
  static const fileIcon = Color(0xFF8FB0FF);

  static const cardRadius = BorderRadius.all(Radius.circular(20));
  static const tileRadius = BorderRadius.all(Radius.circular(16));
  static const iconRadius = BorderRadius.all(Radius.circular(10));

  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const tab = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
  static const badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const heroLabel = TextStyle(fontSize: 12, color: heroCaption);
  static const heroValue = TextStyle(
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: white,
  );
  static const heroMeta = TextStyle(fontSize: 12, color: heroCaption);
  static const pdfButton = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: pdfText,
  );
  static const group = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
  static const lineLabelColor = Color(0xFFC9D1E8);
  static const lineLabel = TextStyle(fontSize: 13, color: lineLabelColor);
  static const lineValue = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: white,
  );
  static const total = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const totalValue = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: white,
  );
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
  static const rowCaption = TextStyle(fontSize: 12, color: muted);
}
