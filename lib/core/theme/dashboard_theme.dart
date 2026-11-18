import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class DashboardTheme {
  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF070D28), Color(0xFF172451)],
    stops: [0, 0.75],
  );
  static const green = Color(0xFF00CD71);
  static const greenLight = Color(0xFF13DE8C);
  static const location = Color(0xFF28E7B5);
  static const muted = Color(0xFF8E9CB8);
  static const halo = Color(0xFF245D60);
  static const glow = Color(0x5500CC83);
  static const white = AppColors.onPrimary;
  static const ink = Color(0xFF0B1435);
  static const divider = Color(0xFF2C3A62);
  static const clock = TextStyle(
    fontSize: 64,
    height: 1,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
  );
  static const date = TextStyle(fontSize: 13, height: 1.3, color: muted);
  static const shift = TextStyle(fontSize: 11, height: 1, color: ink);
  static const checkIn = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: white,
  );
  static const hint = TextStyle(fontSize: 12, color: muted);
  static const locationLabel = TextStyle(fontSize: 12, color: location);
  static const value = TextStyle(
    fontSize: 17,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );
  static const metricLabel = TextStyle(fontSize: 11, color: muted);
  static const greeting = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
  static const company = TextStyle(fontSize: 9, height: 1.2, color: muted);
  static const initials = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: ink,
  );
  static const buttonRadius = BorderRadius.all(Radius.circular(22));
  static const frameRadius = BorderRadius.all(Radius.circular(30));
  static const logoRadius = BorderRadius.all(Radius.circular(8));

  // Sheet "Semua Layanan"
  static const servicesSheet = [Color(0xFF26346A), Color(0xFF1A2552)];
  static const servicesHandle = Color(0x80FFFFFF);
  static const servicesBorder = Color(0x26FFFFFF);
  static const servicesSearchFill = Color(0x14FFFFFF);
  static const servicesGridFill = Color(0x0FFFFFFF);
  static const servicesIconFill = Color(0x1FFFFFFF);
  static const servicesRadius = BorderRadius.all(Radius.circular(14));
  static const servicesLabel = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w400,
  );
  static const servicesTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
}
