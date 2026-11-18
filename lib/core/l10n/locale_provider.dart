import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../storage/secure_storage.dart';
import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// Bahasa yang didukung aplikasi. Indonesia adalah bawaan.
const supportedAppLocales = [Locale('id'), Locale('en')];

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _restore();
    return const Locale('id');
  }

  Future<void> _restore() async {
    try {
      final saved = await ref.read(secureStorageProvider).readLanguage();
      if (saved != null && saved != state.languageCode) {
        _apply(Locale(saved));
      }
    } on Exception {
      // Penyimpanan tidak tersedia (mis. test/web): tetap pakai bawaan.
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedAppLocales.contains(locale)) return;
    _apply(locale);
    try {
      await ref.read(secureStorageProvider).writeLanguage(locale.languageCode);
    } on Exception {
      // Abaikan: pilihan tetap berlaku selama sesi ini.
    }
  }

  void _apply(Locale locale) {
    Intl.defaultLocale = locale.languageCode == 'en' ? 'en_US' : 'id_ID';
    state = locale;
  }
}

extension AppLocalizationsX on BuildContext {
  /// Teks terjemahan. Jatuh ke Bahasa Indonesia bila delegasi belum terpasang
  /// (mis. pada widget test yang memakai MaterialApp polos).
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('id'));
}

extension DateLocaleX on BuildContext {
  /// Locale intl untuk nama hari/bulan sesuai bahasa aktif.
  String get dateLocale => l10n.localeName == 'en' ? 'en_US' : 'id_ID';
}
