import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class TaskDetailTheme {
  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A102E), Color(0xFF172451)],
    stops: [0, 0.65],
  );
  static const surface = Color(0xFF232F59);
  static const border = Color(0xFF364166);
  static const muted = Color(0xFF98A5C3);
  static const descriptionColor = Color(0xFFB7C3DB);
  static const blue = Color(0xFF225BFF);
  static const blueText = Color(0xFF83A5FF);
  static const blueTint = Color(0xFF20356D);
  static const green = Color(0xFF00BF68);
  static const checked = Color(0xFF52EDAA);
  static const high = Color(0xFFFF667A);
  static const white = AppColors.onPrimary;
  static const controlSurface = Color(0x1FFFFFFF);
  static const track = Color(0xFF303D67);
  static const checkBorder = Color(0xFF7986A6);
  static const cardRadius = BorderRadius.all(Radius.circular(20));
  static const rowRadius = BorderRadius.all(Radius.circular(14));
  static const iconRadius = BorderRadius.all(Radius.circular(10));
  static const checkRadius = BorderRadius.all(Radius.circular(6));
  static const pillRadius = BorderRadius.all(Radius.circular(AppRadius.pill));
  static const header = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const title = TextStyle(
    fontSize: 21,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );
  static const chip = TextStyle(
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );
  static const label = TextStyle(fontSize: 13, height: 1.3, color: muted);
  static const value = TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );
  static const section = TextStyle(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const description = TextStyle(fontSize: 13, height: 1.5);
  static const subtask = TextStyle(fontSize: 13, height: 1.35);
  static const button = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
}
