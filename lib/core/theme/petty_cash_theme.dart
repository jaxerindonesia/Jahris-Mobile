import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Token desain halaman Kas Kecil / Petty Cash (Stitch).
abstract final class PettyCashTheme {
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
  static const link = Color(0xFF7FA2FF);
  static const divider = Color(0x1FFFFFFF);

  static const balanceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C6AFF), Color(0xFF1840C8)],
  );
  static const balanceCaption = Color(0xFFDBE5FF);
  static const balanceTrack = Color(0x40FFFFFF);

  static const expense = Color(0xFFFF6C7D);
  static const expenseFill = Color(0x33FF6C7D);
  static const income = Color(0xFF4CEBA9);
  static const incomeFill = Color(0x334CEBA9);

  // Mode terang (Stitch light).
  static const lightBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF3F5FC), Color(0xFFE6EBF8)],
  );
  static const lightText = Color(0xFF0F1A3D);
  static const lightMuted = Color(0xFF7C86A2);
  static const lightHeaderButton = Color(0xFFE3E8F4);
  static const lightOutline = Color(0xFFC9D1E3);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardBorder = Color(0xFFE8ECF5);
  static const lightDivider = Color(0xFFEDF0F6);
  static const lightLink = Color(0xFF2463FF);
  static const lightExpense = Color(0xFFE5484D);
  static const lightExpenseFill = Color(0xFFFDE4E4);
  static const lightIncome = Color(0xFF16A34A);
  static const lightIncomeFill = Color(0xFFDDF5E6);

  static const cardRadius = BorderRadius.all(Radius.circular(20));
  static const iconRadius = BorderRadius.all(Radius.circular(12));

  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const balanceLabel = TextStyle(fontSize: 12, color: balanceCaption);
  static const balanceValue = TextStyle(
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: white,
  );
  static const balanceMeta = TextStyle(fontSize: 12, color: balanceCaption);
  static const button = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
  static const section = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const linkText = TextStyle(fontSize: 12, color: link);
  static const rowTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const rowCaption = TextStyle(fontSize: 12, color: muted);
  static const amount = TextStyle(fontSize: 14, fontWeight: FontWeight.w800);
}
