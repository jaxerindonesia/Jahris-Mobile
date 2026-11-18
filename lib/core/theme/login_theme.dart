import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Token halaman login, mengikuti referensi dark dan light JAHRIS.
abstract final class LoginTheme {
  static const background = [Color(0xFF060B23), Color(0xFF1B2A60)];
  static const darkPanel = [Color(0xFF1A2756), Color(0xFF333D63)];
  static const splashDark = [Color(0xFF060B23), Color(0xFF172255)];
  static const splashLight = [Color(0xFFF5F8FF), Color(0xFFE6ECF8)];
  static const splashDuration = Duration(milliseconds: 2200);
  static const splashLogoSize = Size(84, 78);
  static const poweredBy = TextStyle(fontSize: 8, fontWeight: FontWeight.w500);
  static const jaxerWordmark = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.4,
    height: 1,
  );
  static const jaxerTagline = TextStyle(
    fontSize: 4.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );
  static const lightPanel = [Color(0xFF26315C), Color(0xFF080F2B)];
  static const white = AppColors.onPrimary;
  static const ink = Color(0xFF080808);
  static const brand = Color(0xFF231D86);
  static const green = Color(0xFF00D365);
  static const darkMuted = Color(0xFFA1A7C0);
  static const lightMuted = Color(0xFF686868);
  static const field = Color(0xFF606A88);
  static const fieldLight = Color(0xFF58617C);
  static const muted = Color(0xFFC3C8DB);
  static const footer = Color(0xFF8A92AB);
  static const handle = Color(0xFF8C94AC);
  static const border = Color(0xFF525C7D);
  static const panelRadius = BorderRadius.vertical(top: Radius.circular(22));
  static const fieldRadius = BorderRadius.all(Radius.circular(12));
  static const fieldOutline = OutlineInputBorder(
    borderRadius: fieldRadius,
    borderSide: BorderSide(color: Color(0x24FFFFFF), width: 1.5),
  );
  static const fieldFocusedOutline = OutlineInputBorder(
    borderRadius: fieldRadius,
    borderSide: BorderSide(color: Color(0x99FFFFFF), width: 1.5),
  );
  static const heading = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static const description = TextStyle(fontSize: 12, height: 1.35);
  static const support = TextStyle(fontSize: 11, fontWeight: FontWeight.w400);
  static const supportPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 12,
  );
  static const supportShape = StadiumBorder();
  static const label = TextStyle(color: white, fontSize: 11);
  static const input = TextStyle(color: white, fontSize: 14);
  static const forgot = TextStyle(
    color: muted,
    fontSize: 9,
    fontStyle: FontStyle.italic,
    decoration: TextDecoration.underline,
  );
  static const consent = TextStyle(color: white, fontSize: 9.5, height: 1.3);
  static const link = TextStyle(
    color: green,
    decoration: TextDecoration.underline,
  );
  static const button = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
  static const copyright = TextStyle(color: footer, fontSize: 7.5);
}
