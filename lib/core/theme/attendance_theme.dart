import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AttendanceTheme {
  static const designWidth = 366.0;
  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF080E29), Color(0xFF1B295B)],
    stops: [0, 0.7],
  );
  static const today = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF12265F), Color(0xFF1E357D)],
  );
  static const surface = Color(0xFF26315B);
  static const border = Color(0xFF3A456C);
  static const todayBorder = Color(0xFF3E5DB3);
  static const badge = Color(0xFF354164);
  static const muted = Color(0xFF9AA6C3);
  static const white = AppColors.onPrimary;
  static const green = Color(0xFF4CEBA9);
  static const yellow = Color(0xFFFFD15E);
  static const purple = Color(0xFF9DA6FF);
  static const red = Color(0xFFFF6C7D);
  static const track = Color(0xFF3C476C);
  static const pagePadding = EdgeInsets.fromLTRB(12, 16, 12, 0);
  static const cardRadius = BorderRadius.all(Radius.circular(20));
  static const rowRadius = BorderRadius.all(Radius.circular(16));
  static const badgeRadius = BorderRadius.all(Radius.circular(9));
  static const pillRadius = BorderRadius.all(Radius.circular(AppRadius.pill));
  static const heading = TextStyle(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );
  static const subtitle = TextStyle(fontSize: 11, height: 1.3, color: muted);
  static const month = TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
  static const date = TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const caption = TextStyle(fontSize: 10, height: 1.3, color: muted);
  static const time = TextStyle(
    fontSize: 17,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );
  static const section = TextStyle(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const count = TextStyle(
    fontSize: 23,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );
  static const history = TextStyle(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const detail = TextStyle(fontSize: 10, height: 1.3, color: muted);
  static const status = TextStyle(
    fontSize: 9,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );
  // Riwayat Absen
  static const historyTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const historyMonth = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: white,
  );
  static const calendarWeekday = TextStyle(fontSize: 10, color: muted);
  static const calendarDay = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const legend = TextStyle(fontSize: 10, color: muted);
  static const statValue = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const statLabel = TextStyle(fontSize: 10, color: muted);
  static const sectionTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const dayBadgeNumber = TextStyle(
    fontSize: 15,
    height: 1.1,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const dayBadgeName = TextStyle(fontSize: 9, color: muted);
  static const rowTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: white,
  );
  static const rowCaption = TextStyle(fontSize: 10, color: muted);
  static const calendarCellSize = 28.0;
  static const iconButtonFill = Color(0xFF26315B);
  static const panelFill = Color(0x9926315B);
  static const panelRadius = BorderRadius.all(Radius.circular(16));
  static const rowRadius12 = BorderRadius.all(Radius.circular(12));
  static const day = TextStyle(
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );
}
