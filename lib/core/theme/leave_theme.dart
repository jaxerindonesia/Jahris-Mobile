import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Token desain halaman Izin / Cuti (Stitch).
abstract final class LeaveTheme {
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

  // Mode terang (Stitch light, form Ajukan Cuti).
  static const lightBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF3F5FC), Color(0xFFE6EBF8)],
  );
  static const lightText = Color(0xFF0F1A3D);
  static const lightMuted = Color(0xFF7C86A2);
  static const lightHeaderButton = Color(0xFFE3E8F4);
  static const lightField = Color(0xFFE3E8F4);
  static const lightFieldBorder = Color(0xFFD3DAEA);
  static const lightDash = Color(0xFFC3CBDD);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardBorder = Color(0xFFE8ECF5);
  static const lightLink = Color(0xFF2463FF);
  static const lightInfoFill = Color(0xFFD3DEFC);
  static const lightUploadFill = Color(0xFFC9D7FF);

  static const balanceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C6AFF), Color(0xFF1840C8)],
  );
  static const balanceCaption = Color(0xFFDBE5FF);
  static const balanceIconFill = Color(0x33FFFFFF);
  static const balanceTrack = Color(0x40FFFFFF);

  static const annual = Color(0xFF7FA2FF);
  static const sick = Color(0xFFFF6C7D);
  static const permit = Color(0xFFF7B733);
  static const special = Color(0xFF4CEBA9);

  static const pending = Color(0xFFF7B733);
  static const approved = Color(0xFF4CEBA9);
  static const rejected = Color(0xFFFF6C7D);

  static const cardRadius = BorderRadius.all(Radius.circular(20));
  static const tileRadius = BorderRadius.all(Radius.circular(18));
  static const iconRadius = BorderRadius.all(Radius.circular(10));
  static const pillRadius = BorderRadius.all(Radius.circular(AppRadius.pill));

  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const balanceLabel = TextStyle(fontSize: 13, color: balanceCaption);
  static const balanceValue = TextStyle(
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: white,
  );
  static const balanceMeta = TextStyle(fontSize: 12, color: balanceCaption);
  static const section = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const linkText = TextStyle(fontSize: 12, color: link);
  static const typeLabel = TextStyle(fontSize: 11, color: Color(0xFFD5DCF0));
  static const rowTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const rowCaption = TextStyle(fontSize: 12, color: muted);
  static const status = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
  static const formLabel = TextStyle(fontSize: 12, color: muted);
  static const formValue = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: white,
  );
  static const infoText = TextStyle(fontSize: 12, color: link);
  static const infoFill = Color(0xFF1C3474);
  static const uploadFill = Color(0xFF243A7A);
  static const approverFill = Color(0xFFFFCE63);
  static const approverText = Color(0xFF3A2A00);
  static const fieldRadius = BorderRadius.all(Radius.circular(16));
  static const button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: white,
  );
}
