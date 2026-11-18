import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Token desain halaman Lembur (Stitch).
abstract final class OvertimeTheme {
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
    colors: [Color(0xFF1C3C9A), Color(0xFF13286B)],
  );
  static const summaryBorder = Color(0xFF3A5BC0);
  static const summaryDivider = Color(0x33FFFFFF);
  static const statsText = Color(0xFF8FB0FF);
  static const pay = Color(0xFF4CEBA9);
  static const pending = Color(0xFFF7B733);
  static const approved = Color(0xFF4CEBA9);
  static const rejected = Color(0xFFFF6C7D);
  static const summaryLabelColor = Color(0xFFC9D6FF);
  static const tileTimeColor = Color(0xFFD5DCF0);

  // Mode terang (Stitch light, selaras Jadwal Shift).
  static const lightBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF3F5FC), Color(0xFFE6EBF8)],
  );
  static const lightText = Color(0xFF0F1A3D);
  static const lightMuted = Color(0xFF7C86A2);
  static const lightHeaderButton = Color(0xFFE3E8F4);
  static const lightTile = Color(0xFFFFFFFF);
  static const lightTileBorder = Color(0xFFE8ECF5);
  static const lightSegment = Color(0xFFE3E8F4);
  static const lightSegmentBorder = Color(0xFFD3DAEA);
  static const lightSummaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDDE6FF), Color(0xFFD3DEFC)],
  );
  static const lightSummaryBorder = Color(0xFF9DB5F5);
  static const lightSummaryDivider = Color(0xFFB7C8F5);
  static const lightSummaryLabel = Color(0xFF4A5577);
  static const lightStats = Color(0xFF2463FF);
  static const lightPay = Color(0xFF0E9F6E);
  static const lightTileTime = Color(0xFF4A5577);

  // Status mode terang: warna teks/ikon dan latar chip.
  static const lightPending = Color(0xFFC98A0B);
  static const lightPendingFill = Color(0xFFFCEFD3);
  static const lightApproved = Color(0xFF1E9E5A);
  static const lightApprovedFill = Color(0xFFDDF4E7);
  static const lightRejected = Color(0xFFD9364A);
  static const lightRejectedFill = Color(0xFFFCE3E6);
  static const lightOtherFill = Color(0xFFE9ECF3);

  static const cardRadius = BorderRadius.all(Radius.circular(20));
  static const tileRadius = BorderRadius.all(Radius.circular(18));
  static const iconRadius = BorderRadius.all(Radius.circular(10));
  static const pillRadius = BorderRadius.all(Radius.circular(AppRadius.pill));

  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const summaryLabel = TextStyle(fontSize: 12, color: Color(0xFFC9D6FF));
  static const summaryValue = TextStyle(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: white,
  );
  static const payValue = TextStyle(
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w800,
    color: pay,
  );
  static const stats = TextStyle(fontSize: 11, color: statsText);
  static const tab = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
  static const tileTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const tileTime = TextStyle(fontSize: 12, color: Color(0xFFD5DCF0));
  static const tileNote = TextStyle(fontSize: 12, color: muted);
  static const status = TextStyle(fontSize: 10, fontWeight: FontWeight.w600);
  static const button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: white,
  );
}
