import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../storage/secure_storage.dart';
import 'dio_adapter_stub.dart' if (dart.library.html) 'dio_adapter_web.dart';

const serverRejectedMessage = 'Server menolak permintaan, hubungi admin';

final sessionExpiryProvider = NotifierProvider<SessionExpiryController, int>(
  SessionExpiryController.new,
);

class SessionExpiryController extends Notifier<int> {
  @override
  int build() => 0;

  void notifyExpired() => state++;
}

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  // Ekstrak base origin dari apiBaseUrl (contoh: https://dev.jahris.id)
  final baseOrigin = _originFromUrl(Env.apiBaseUrl);
  // Native tidak mengirim Origin secara otomatis. Di web, Origin/Referer/Cookie
  // adalah forbidden headers dan harus sepenuhnya dikelola oleh browser.
  final baseHeaders = <String, String>{'Accept': 'application/json'};
  if (!kIsWeb && baseOrigin != null) {
    baseHeaders['Origin'] = baseOrigin;
    baseHeaders['Referer'] = '$baseOrigin/';
  }
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: baseHeaders,
    ),
  );
  configureDioAdapter(dio);
  dio.interceptors.add(
    SessionCookieInterceptor(
      storage,
      manageCookiesManually: !kIsWeb,
      onSessionExpired: () =>
          ref.read(sessionExpiryProvider.notifier).notifyExpired(),
    ),
  );
  return dio;
});

class SessionCookieInterceptor extends QueuedInterceptor {
  SessionCookieInterceptor(
    this._storage, {
    required this.onSessionExpired,
    this.manageCookiesManually = true,
  });

  final SecureStorage _storage;
  final void Function() onSessionExpired;
  final bool manageCookiesManually;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (manageCookiesManually) {
      final cookie = await _storage.readSessionCookie();
      if (cookie != null && cookie.isNotEmpty) {
        options.headers[HttpHeaders.cookieHeader] = cookie;
      }
    }
    if (options.path.toLowerCase().contains('verify')) {
      options.sendTimeout = const Duration(seconds: 60);
      options.receiveTimeout = const Duration(seconds: 60);
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (manageCookiesManually) {
      await _persistCookies(response.headers.map[HttpHeaders.setCookieHeader]);
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final error = err;
    if (manageCookiesManually) {
      await _persistCookies(
        error.response?.headers.map[HttpHeaders.setCookieHeader],
      );
    }
    final status = error.response?.statusCode;
    final path = error.requestOptions.path.toLowerCase();
    if (status == 401 &&
        !path.endsWith('/auth/login') &&
        !path.contains('/auth/callback/credentials')) {
      await _storage.clearSession();
      onSessionExpired();
    }
    if (_isCloudflareRejection(error)) {
      error.response?.data = const <String, dynamic>{
        'error': serverRejectedMessage,
      };
      handler.next(
        DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: serverRejectedMessage,
          message: serverRejectedMessage,
        ),
      );
      return;
    }
    handler.next(error);
  }

  bool _isCloudflareRejection(DioException error) {
    if (error.response?.statusCode != 403) return false;
    final contentType = error.response?.headers.value(
      HttpHeaders.contentTypeHeader,
    );
    final data = error.response?.data;
    return contentType?.toLowerCase().contains('text/html') == true ||
        (data is String && data.trimLeft().startsWith('<'));
  }

  Future<void> _persistCookies(List<String>? setCookieHeaders) async {
    if (setCookieHeaders == null || setCookieHeaders.isEmpty) return;
    final cookies = <String, String>{};
    final stored = await _storage.readSessionCookie();
    if (stored != null) {
      for (final segment in stored.split(';')) {
        final separator = segment.indexOf('=');
        if (separator <= 0) continue;
        cookies[segment.substring(0, separator).trim()] = segment
            .substring(separator + 1)
            .trim();
      }
    }
    for (final header in setCookieHeaders) {
      // Parse manual: lebih tahan terhadap SameSite=Lax/None dan atribut
      // non-standar yang membuat Cookie.fromSetCookieValue() melempar
      // FormatException sehingga cookie tidak tersimpan diam-diam.
      final parsed = _parseSetCookie(header);
      if (parsed == null) continue;
      final name = parsed['name']!;
      final value = parsed['value']!;
      final maxAgeStr = parsed['max-age'];
      final expiresStr = parsed['expires'];
      final maxAge = int.tryParse(maxAgeStr ?? '');
      final expires = expiresStr != null ? HttpDate.parse(expiresStr) : null;
      final expired =
          (maxAge != null && maxAge <= 0) ||
          (expires?.isBefore(DateTime.now().toUtc()) ?? false);
      if (expired || value.isEmpty) {
        cookies.remove(name);
      } else {
        cookies[name] = value;
      }
    }
    await _storage.writeSessionCookie(
      cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
    );
  }

  /// Mem-parse header Set-Cookie tanpa melempar exception.
  /// Mengembalikan map dengan 'name', 'value', dan atribut lowercase lainnya.
  Map<String, String>? _parseSetCookie(String header) {
    final segments = header.split(';');
    if (segments.isEmpty) return null;
    final firstPart = segments.first;
    final eq = firstPart.indexOf('=');
    if (eq <= 0) return null;
    final name = firstPart.substring(0, eq).trim();
    final value = firstPart.substring(eq + 1).trim();
    if (name.isEmpty) return null;
    final result = <String, String>{'name': name, 'value': value};
    for (final seg in segments.skip(1)) {
      final attrEq = seg.indexOf('=');
      if (attrEq > 0) {
        result[seg.substring(0, attrEq).trim().toLowerCase()] = seg
            .substring(attrEq + 1)
            .trim();
      }
    }
    return result;
  }
} // end SessionCookieInterceptor

String networkErrorMessage(
  Object error, {
  String fallback = 'Layanan tidak tersedia. Silakan coba lagi.',
}) => error is DioException
    ? dioErrorMessage(error, fallback: fallback)
    : fallback;

String dioErrorMessage(
  DioException error, {
  String fallback = 'Layanan tidak tersedia. Silakan coba lagi.',
}) {
  if (error.message == serverRejectedMessage ||
      error.error == serverRejectedMessage) {
    return serverRejectedMessage;
  }
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final errorValue = data['error'];
    if (errorValue is String && errorValue.isNotEmpty) return errorValue;
    if (errorValue is Map<String, dynamic>) {
      final message = errorValue['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
  }
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return 'Tidak ada koneksi. Periksa internet lalu coba lagi.';
  }
  return fallback;
}

/// Mengekstrak origin (scheme + host + port jika tidak default) dari URL.
/// Contoh: 'https://dev.jahris.id/api' → 'https://dev.jahris.id'
String? _originFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final port =
      uri.hasPort &&
          !((uri.scheme == 'https' && uri.port == 443) ||
              (uri.scheme == 'http' && uri.port == 80))
      ? ':${uri.port}'
      : '';
  return '${uri.scheme}://${uri.host}$port';
}
