import 'package:flutter/foundation.dart';

abstract final class Env {
  static final customerServiceUrl = Uri.https('wa.me', '/6281511496687');
  static const supportWhatsappDisplay = '081511496687';
  static const supportEmail = 'support@jahris.id';
  static final supportEmailUrl = Uri(
    scheme: 'mailto',
    path: supportEmail,
    query: 'subject=Bantuan%20JAHRIS',
  );

  static const _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) return _configuredApiBaseUrl;

    return kIsWeb
        ? 'http://localhost:3000/dev-api'
        : 'https://dev.jahris.id/api';
  }

  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

  static const holidayApiBaseUrl = String.fromEnvironment(
    'HOLIDAY_API_BASE_URL',
    defaultValue: 'https://date.nager.at/api/v3',
  );

  static const mockFaceVerifyResult = String.fromEnvironment(
    'MOCK_FACE_VERIFY',
    defaultValue: 'success',
  );
}
