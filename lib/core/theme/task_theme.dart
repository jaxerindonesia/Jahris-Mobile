import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class TaskTheme {
  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF080E2A), Color(0xFF1B2859)],
  );
  static const primary = Color(0xFF215CFF);
  static const progressGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C6AFF), Color(0xFF183DCB)],
  );
  static const surface = Color(0xFF242F5A);
  static const muted = Color(0xFF95A0BD);
  static const white = AppColors.onPrimary;
  static const border = Color(0xFF36416A);
  static const high = Color(0xFFFF6F7C);
  static const medium = Color(0xFFFFCE63);
  static const low = Color(0xFF55EDAD);
  static const pagePadding = EdgeInsets.fromLTRB(12, 16, 12, 0);
  static const dayRadius = BorderRadius.all(Radius.circular(16));
  static const cardRadius = BorderRadius.all(Radius.circular(20));
  static const pillRadius = BorderRadius.all(Radius.circular(AppRadius.pill));
  static const heading = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );
  static const date = TextStyle(fontSize: 12, color: muted);
  static const progressCaption = TextStyle(
    fontSize: 12,
    height: 1.2,
    color: Color(0xFFDBE5FF),
  );
  static const progressTitle = TextStyle(
    fontSize: 17,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const percent = TextStyle(
    fontSize: 22,
    height: 1,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const weekday = TextStyle(fontSize: 10, height: 1.2, color: muted);
  static const day = TextStyle(
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );
  static const filter = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: muted,
  );
  static const title = TextStyle(
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );
  static const metadata = TextStyle(fontSize: 11, height: 1.2, color: muted);
  static const priority = TextStyle(fontSize: 10, height: 1.2);
  // Sheet "Tugas Baru"
  static const sheetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF16214A), Color(0xFF0E1838)],
  );
  static const sheetBarrier = Color(0xD903081E);
  static const sheetBorder = Color(0xFF2A3666);
  static const sheetHandle = Color(0xFF8A94B3);
  static const sheetRadius = BorderRadius.vertical(top: Radius.circular(24));
  static const fieldFill = Color(0xFF1F2A52);
  static const fieldBorder = Color(0xFF34406C);
  static const fieldRadius = BorderRadius.all(Radius.circular(14));
  static const chipFill = Color(0xFF1C2750);
  static const chipBorder = Color(0xFF34406C);
  static const reminderFill = Color(0xFF1C2750);
  static const reminderIconFill = Color(0xFF243A7A);
  static const reminderIcon = Color(0xFF8FB0FF);
  // Mode terang (Stitch)
  static const lightFieldFill = Color(0xFFEEEFF3);
  static const lightFieldBorder = Color(0xFFE2E4EA);
  static const lightChipFill = Color(0xFFE9EBF0);
  static const lightChipBorder = Color(0xFFD9DCE4);
  static const lightReminderFill = Color(0xFFEEF0F5);
  static const priorityRadius = BorderRadius.all(Radius.circular(10));
  static const sheetTitle = TextStyle(
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const sheetLabel = TextStyle(fontSize: 12, height: 1.2, color: muted);
  static const fieldText = TextStyle(fontSize: 14, color: white);
  static const fieldHint = TextStyle(fontSize: 14, color: Color(0xFF6E7899));
  static const chipText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xFFD5DCF0),
  );
  static const reminderTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: white,
  );
  static const reminderCaption = TextStyle(fontSize: 11, color: muted);
  static const saveText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: white,
  );
  static const reminderSize = 5.0;
  static const dayHeight = 64.0;
  static const dayGap = 8.0;
}
