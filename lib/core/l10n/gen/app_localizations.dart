import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @navHome.
  ///
  /// In id, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAttendance.
  ///
  /// In id, this message translates to:
  /// **'Kehadiran'**
  String get navAttendance;

  /// No description provided for @navTask.
  ///
  /// In id, this message translates to:
  /// **'Tugas'**
  String get navTask;

  /// No description provided for @navProfile.
  ///
  /// In id, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @commonCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba Lagi'**
  String get commonRetry;

  /// No description provided for @commonSaving.
  ///
  /// In id, this message translates to:
  /// **'Menyimpan...'**
  String get commonSaving;

  /// No description provided for @commonShowPassword.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan password'**
  String get commonShowPassword;

  /// No description provided for @commonHidePassword.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan password'**
  String get commonHidePassword;

  /// No description provided for @languageIndonesian.
  ///
  /// In id, this message translates to:
  /// **'Indonesia'**
  String get languageIndonesian;

  /// No description provided for @languageEnglish.
  ///
  /// In id, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePickerTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Bahasa'**
  String get languagePickerTitle;

  /// No description provided for @languagePickerSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Atur bahasa tampilan aplikasi.'**
  String get languagePickerSubtitle;

  /// No description provided for @languageIndonesianTitle.
  ///
  /// In id, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesianTitle;

  /// No description provided for @languageIndonesianSub.
  ///
  /// In id, this message translates to:
  /// **'Bawaan aplikasi'**
  String get languageIndonesianSub;

  /// No description provided for @languageEnglishSub.
  ///
  /// In id, this message translates to:
  /// **'Bahasa Inggris'**
  String get languageEnglishSub;

  /// No description provided for @languagePickerHint.
  ///
  /// In id, this message translates to:
  /// **'Terjemahan diterapkan bertahap, beberapa halaman masih berbahasa Indonesia.'**
  String get languagePickerHint;

  /// No description provided for @profileTitle.
  ///
  /// In id, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileLoadError.
  ///
  /// In id, this message translates to:
  /// **'Profil gagal dimuat.'**
  String get profileLoadError;

  /// No description provided for @profileEdit.
  ///
  /// In id, this message translates to:
  /// **'Ubah profil'**
  String get profileEdit;

  /// No description provided for @profileEditFromAvatar.
  ///
  /// In id, this message translates to:
  /// **'Ubah profil dari avatar'**
  String get profileEditFromAvatar;

  /// No description provided for @profileStatLeave.
  ///
  /// In id, this message translates to:
  /// **'Sisa Cuti'**
  String get profileStatLeave;

  /// No description provided for @profileStatPresent.
  ///
  /// In id, this message translates to:
  /// **'Hadir Bulan Ini'**
  String get profileStatPresent;

  /// No description provided for @profileStatOvertime.
  ///
  /// In id, this message translates to:
  /// **'Lembur'**
  String get profileStatOvertime;

  /// No description provided for @profileSectionAccount.
  ///
  /// In id, this message translates to:
  /// **'AKUN'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionSettings.
  ///
  /// In id, this message translates to:
  /// **'PENGATURAN'**
  String get profileSectionSettings;

  /// No description provided for @profileSectionOther.
  ///
  /// In id, this message translates to:
  /// **'LAINNYA'**
  String get profileSectionOther;

  /// No description provided for @profilePersonalData.
  ///
  /// In id, this message translates to:
  /// **'Data Pribadi'**
  String get profilePersonalData;

  /// No description provided for @profileDocuments.
  ///
  /// In id, this message translates to:
  /// **'Dokumen Saya'**
  String get profileDocuments;

  /// No description provided for @profileDocumentsCount.
  ///
  /// In id, this message translates to:
  /// **'{count} file'**
  String profileDocumentsCount(int count);

  /// No description provided for @profileBankAccount.
  ///
  /// In id, this message translates to:
  /// **'Rekening Bank'**
  String get profileBankAccount;

  /// No description provided for @profileBankNotSet.
  ///
  /// In id, this message translates to:
  /// **'Belum diatur'**
  String get profileBankNotSet;

  /// No description provided for @profileNotifications.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi'**
  String get profileNotifications;

  /// No description provided for @profileDarkTheme.
  ///
  /// In id, this message translates to:
  /// **'Tema Gelap'**
  String get profileDarkTheme;

  /// No description provided for @profileLanguage.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get profileLanguage;

  /// No description provided for @profileSecurity.
  ///
  /// In id, this message translates to:
  /// **'Keamanan & Password'**
  String get profileSecurity;

  /// No description provided for @profileHelp.
  ///
  /// In id, this message translates to:
  /// **'Bantuan'**
  String get profileHelp;

  /// No description provided for @profileAbout.
  ///
  /// In id, this message translates to:
  /// **'Tentang Aplikasi'**
  String get profileAbout;

  /// No description provided for @profileLogout.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get profileLogout;

  /// No description provided for @profileLogoutTitle.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari Jahris?'**
  String get profileLogoutTitle;

  /// No description provided for @profileLogoutBody.
  ///
  /// In id, this message translates to:
  /// **'Sesi aktif Anda akan diakhiri.'**
  String get profileLogoutBody;

  /// No description provided for @profileFormTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah Profil'**
  String get profileFormTitle;

  /// No description provided for @profileFormName.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get profileFormName;

  /// No description provided for @profileFormEmail.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get profileFormEmail;

  /// No description provided for @profileFormPhone.
  ///
  /// In id, this message translates to:
  /// **'Telepon'**
  String get profileFormPhone;

  /// No description provided for @profileFormSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan Profil'**
  String get profileFormSave;

  /// No description provided for @passwordFormTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah Password'**
  String get passwordFormTitle;

  /// No description provided for @passwordCurrent.
  ///
  /// In id, this message translates to:
  /// **'Password saat ini'**
  String get passwordCurrent;

  /// No description provided for @passwordNew.
  ///
  /// In id, this message translates to:
  /// **'Password baru'**
  String get passwordNew;

  /// No description provided for @passwordConfirm.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi password baru'**
  String get passwordConfirm;

  /// No description provided for @passwordFormSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Gunakan password yang kuat dan belum pernah dipakai di akun lain.'**
  String get passwordFormSubtitle;

  /// No description provided for @passwordCurrentHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan password saat ini'**
  String get passwordCurrentHint;

  /// No description provided for @passwordNewHint.
  ///
  /// In id, this message translates to:
  /// **'Minimal 6 karakter'**
  String get passwordNewHint;

  /// No description provided for @passwordConfirmHint.
  ///
  /// In id, this message translates to:
  /// **'Ulangi password baru'**
  String get passwordConfirmHint;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In id, this message translates to:
  /// **'Lemah'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthMedium.
  ///
  /// In id, this message translates to:
  /// **'Sedang'**
  String get passwordStrengthMedium;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In id, this message translates to:
  /// **'Kuat'**
  String get passwordStrengthStrong;

  /// No description provided for @passwordStrengthLabel.
  ///
  /// In id, this message translates to:
  /// **'Kekuatan password'**
  String get passwordStrengthLabel;

  /// No description provided for @passwordRuleLength.
  ///
  /// In id, this message translates to:
  /// **'Minimal 6 karakter'**
  String get passwordRuleLength;

  /// No description provided for @passwordRuleMix.
  ///
  /// In id, this message translates to:
  /// **'Kombinasi huruf besar, angka, atau simbol'**
  String get passwordRuleMix;

  /// No description provided for @passwordRuleMatch.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi password sama'**
  String get passwordRuleMatch;

  /// No description provided for @bankFormTitle.
  ///
  /// In id, this message translates to:
  /// **'Rekening Bank'**
  String get bankFormTitle;

  /// No description provided for @bankFormHint.
  ///
  /// In id, this message translates to:
  /// **'Rekening ini dipakai untuk transfer gaji dan reimburse.'**
  String get bankFormHint;

  /// No description provided for @bankFormBank.
  ///
  /// In id, this message translates to:
  /// **'Nama bank'**
  String get bankFormBank;

  /// No description provided for @bankFormNumber.
  ///
  /// In id, this message translates to:
  /// **'Nomor rekening'**
  String get bankFormNumber;

  /// No description provided for @bankFormHolder.
  ///
  /// In id, this message translates to:
  /// **'Nama pemilik rekening'**
  String get bankFormHolder;

  /// No description provided for @bankFormSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan Rekening'**
  String get bankFormSave;

  /// No description provided for @dashboardShift.
  ///
  /// In id, this message translates to:
  /// **'Shift Pagi · 08:15 – 17:15'**
  String get dashboardShift;

  /// No description provided for @dashboardCheckIn.
  ///
  /// In id, this message translates to:
  /// **'Check In'**
  String get dashboardCheckIn;

  /// No description provided for @dashboardScanHint.
  ///
  /// In id, this message translates to:
  /// **'Tap untuk scan wajah'**
  String get dashboardScanHint;

  /// No description provided for @dashboardLocation.
  ///
  /// In id, this message translates to:
  /// **'Kantor Pusat · dalam radius'**
  String get dashboardLocation;

  /// No description provided for @dashboardIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get dashboardIn;

  /// No description provided for @dashboardOut.
  ///
  /// In id, this message translates to:
  /// **'Pulang'**
  String get dashboardOut;

  /// No description provided for @dashboardTotal.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get dashboardTotal;

  /// No description provided for @dashboardLeave.
  ///
  /// In id, this message translates to:
  /// **'Izin/Cuti'**
  String get dashboardLeave;

  /// No description provided for @dashboardReimburse.
  ///
  /// In id, this message translates to:
  /// **'Reimburse'**
  String get dashboardReimburse;

  /// No description provided for @dashboardPettyCash.
  ///
  /// In id, this message translates to:
  /// **'Petty Cash'**
  String get dashboardPettyCash;

  /// No description provided for @dashboardMore.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get dashboardMore;

  /// No description provided for @dashboardNextHoliday.
  ///
  /// In id, this message translates to:
  /// **'Libur berikutnya: {name}'**
  String dashboardNextHoliday(String name);

  /// No description provided for @dashboardMyRequests.
  ///
  /// In id, this message translates to:
  /// **'Pengajuan Saya'**
  String get dashboardMyRequests;

  /// No description provided for @dashboardNoRequests.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pengajuan terbaru.'**
  String get dashboardNoRequests;

  /// No description provided for @dashboardSummaryError.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan belum dapat dimuat.'**
  String get dashboardSummaryError;

  /// No description provided for @serviceAttendanceHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Absen'**
  String get serviceAttendanceHistory;

  /// No description provided for @serviceShift.
  ///
  /// In id, this message translates to:
  /// **'Jadwal Shift'**
  String get serviceShift;

  /// No description provided for @serviceOvertime.
  ///
  /// In id, this message translates to:
  /// **'Lembur'**
  String get serviceOvertime;

  /// No description provided for @servicePayslip.
  ///
  /// In id, this message translates to:
  /// **'Slip Gaji'**
  String get servicePayslip;

  /// No description provided for @serviceHoliday.
  ///
  /// In id, this message translates to:
  /// **'Kalender Libur'**
  String get serviceHoliday;

  /// No description provided for @serviceHelp.
  ///
  /// In id, this message translates to:
  /// **'Bantuan'**
  String get serviceHelp;

  /// No description provided for @servicesTitle.
  ///
  /// In id, this message translates to:
  /// **'Semua Layanan'**
  String get servicesTitle;

  /// No description provided for @servicesSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari layanan...'**
  String get servicesSearch;

  /// No description provided for @servicesEmpty.
  ///
  /// In id, this message translates to:
  /// **'Layanan tidak ditemukan.'**
  String get servicesEmpty;

  /// No description provided for @loginSupport.
  ///
  /// In id, this message translates to:
  /// **'Layanan Pelanggan'**
  String get loginSupport;

  /// No description provided for @splashPoweredBy.
  ///
  /// In id, this message translates to:
  /// **'Powered by'**
  String get splashPoweredBy;

  /// No description provided for @loginToggleTheme.
  ///
  /// In id, this message translates to:
  /// **'Ganti tema'**
  String get loginToggleTheme;

  /// No description provided for @loginWelcome.
  ///
  /// In id, this message translates to:
  /// **'Selamat datang di Jahris'**
  String get loginWelcome;

  /// No description provided for @loginTagline.
  ///
  /// In id, this message translates to:
  /// **'Satu akses untuk semua aktivitas kerja.\nAbsen, cek jadwal, dan ajukan cuti dari genggaman.'**
  String get loginTagline;

  /// No description provided for @loginToggleSheet.
  ///
  /// In id, this message translates to:
  /// **'Buka atau tutup panel login'**
  String get loginToggleSheet;

  /// No description provided for @loginEmail.
  ///
  /// In id, this message translates to:
  /// **'Email Address*'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In id, this message translates to:
  /// **'Password*'**
  String get loginPassword;

  /// No description provided for @loginForgot.
  ///
  /// In id, this message translates to:
  /// **'Lupa kata sandi?'**
  String get loginForgot;

  /// No description provided for @loginConsent.
  ///
  /// In id, this message translates to:
  /// **'Dengan melanjutkan, saya menyetujui pemrosesan data pribadi saya sesuai dengan '**
  String get loginConsent;

  /// No description provided for @loginTerms.
  ///
  /// In id, this message translates to:
  /// **'Ketentuan Layanan'**
  String get loginTerms;

  /// No description provided for @loginAnd.
  ///
  /// In id, this message translates to:
  /// **' dan '**
  String get loginAnd;

  /// No description provided for @loginPrivacy.
  ///
  /// In id, this message translates to:
  /// **'Kebijakan Privasi JAHRIS'**
  String get loginPrivacy;

  /// No description provided for @loginSubmit.
  ///
  /// In id, this message translates to:
  /// **'Masuk ke Jahris'**
  String get loginSubmit;

  /// No description provided for @loginWhatsappError.
  ///
  /// In id, this message translates to:
  /// **'WhatsApp tidak dapat dibuka. Hubungi {phone}.'**
  String loginWhatsappError(String phone);

  /// No description provided for @loginResetSent.
  ///
  /// In id, this message translates to:
  /// **'Petunjuk reset password telah dikirim.'**
  String get loginResetSent;

  /// No description provided for @forcePasswordTitle.
  ///
  /// In id, this message translates to:
  /// **'Ganti Password'**
  String get forcePasswordTitle;

  /// No description provided for @forcePasswordHeading.
  ///
  /// In id, this message translates to:
  /// **'Buat password baru'**
  String get forcePasswordHeading;

  /// No description provided for @forcePasswordBody.
  ///
  /// In id, this message translates to:
  /// **'Admin mewajibkan Anda mengganti password sebelum melanjutkan.'**
  String get forcePasswordBody;

  /// No description provided for @forcePasswordCurrentRequired.
  ///
  /// In id, this message translates to:
  /// **'Password saat ini wajib diisi.'**
  String get forcePasswordCurrentRequired;

  /// No description provided for @forcePasswordSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan Password Baru'**
  String get forcePasswordSave;

  /// No description provided for @logoLabel.
  ///
  /// In id, this message translates to:
  /// **'Logo JAHRIS'**
  String get logoLabel;

  /// No description provided for @attTitle.
  ///
  /// In id, this message translates to:
  /// **'Kehadiran'**
  String get attTitle;

  /// No description provided for @attSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Rekap kehadiran kamu'**
  String get attSubtitle;

  /// No description provided for @attLoadError.
  ///
  /// In id, this message translates to:
  /// **'Data kehadiran gagal dimuat.'**
  String get attLoadError;

  /// No description provided for @attPickMonth.
  ///
  /// In id, this message translates to:
  /// **'Pilih bulan kehadiran'**
  String get attPickMonth;

  /// No description provided for @attSummary.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan {month}'**
  String attSummary(String month);

  /// No description provided for @attRecent.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Terbaru'**
  String get attRecent;

  /// No description provided for @attSeeAll.
  ///
  /// In id, this message translates to:
  /// **'Lihat semua'**
  String get attSeeAll;

  /// No description provided for @attEmptyMonth.
  ///
  /// In id, this message translates to:
  /// **'Belum ada riwayat kehadiran pada bulan ini.'**
  String get attEmptyMonth;

  /// No description provided for @attHistoryTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Kehadiran'**
  String get attHistoryTitle;

  /// No description provided for @attHistoryError.
  ///
  /// In id, this message translates to:
  /// **'Riwayat kehadiran gagal dimuat.'**
  String get attHistoryError;

  /// No description provided for @attHistoryEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada riwayat kehadiran.'**
  String get attHistoryEmpty;

  /// No description provided for @attLoadMore.
  ///
  /// In id, this message translates to:
  /// **'Muat lainnya'**
  String get attLoadMore;

  /// No description provided for @attToday.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get attToday;

  /// No description provided for @attIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get attIn;

  /// No description provided for @attOut.
  ///
  /// In id, this message translates to:
  /// **'Pulang'**
  String get attOut;

  /// No description provided for @attDuration.
  ///
  /// In id, this message translates to:
  /// **'Durasi'**
  String get attDuration;

  /// No description provided for @attShift.
  ///
  /// In id, this message translates to:
  /// **'Shift Pagi · {start} – {end}'**
  String attShift(String start, String end);

  /// No description provided for @attPresent.
  ///
  /// In id, this message translates to:
  /// **'Hadir'**
  String get attPresent;

  /// No description provided for @attLate.
  ///
  /// In id, this message translates to:
  /// **'Terlambat'**
  String get attLate;

  /// No description provided for @attLeave.
  ///
  /// In id, this message translates to:
  /// **'Izin/Cuti'**
  String get attLeave;

  /// No description provided for @attAbsent.
  ///
  /// In id, this message translates to:
  /// **'Alpha'**
  String get attAbsent;

  /// No description provided for @attRate.
  ///
  /// In id, this message translates to:
  /// **'Tingkat kehadiran'**
  String get attRate;

  /// No description provided for @attNotOut.
  ///
  /// In id, this message translates to:
  /// **'Belum pulang'**
  String get attNotOut;

  /// No description provided for @attHoursMinutes.
  ///
  /// In id, this message translates to:
  /// **'{h}j {m}m'**
  String attHoursMinutes(String h, String m);

  /// No description provided for @attHoursShort.
  ///
  /// In id, this message translates to:
  /// **'{h}j'**
  String attHoursShort(String h);

  /// No description provided for @attStatusAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get attStatusAll;

  /// No description provided for @attStatusOnTime.
  ///
  /// In id, this message translates to:
  /// **'Tepat Waktu'**
  String get attStatusOnTime;

  /// No description provided for @attStatusLate.
  ///
  /// In id, this message translates to:
  /// **'Terlambat'**
  String get attStatusLate;

  /// No description provided for @attStatusPermit.
  ///
  /// In id, this message translates to:
  /// **'Izin'**
  String get attStatusPermit;

  /// No description provided for @attStatusAbsent.
  ///
  /// In id, this message translates to:
  /// **'Alpha'**
  String get attStatusAbsent;

  /// No description provided for @attStatusWorking.
  ///
  /// In id, this message translates to:
  /// **'Sedang Bekerja'**
  String get attStatusWorking;

  /// No description provided for @attStatusDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get attStatusDone;

  /// No description provided for @attStatusNotIn.
  ///
  /// In id, this message translates to:
  /// **'Belum Masuk'**
  String get attStatusNotIn;

  /// No description provided for @attLegendOnTime.
  ///
  /// In id, this message translates to:
  /// **'Tepat waktu'**
  String get attLegendOnTime;

  /// No description provided for @attBack.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get attBack;

  /// No description provided for @attHistoryAbsen.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Absen'**
  String get attHistoryAbsen;

  /// No description provided for @attFilterStatus.
  ///
  /// In id, this message translates to:
  /// **'Filter status'**
  String get attFilterStatus;

  /// No description provided for @attFilterTitle.
  ///
  /// In id, this message translates to:
  /// **'Filter Status'**
  String get attFilterTitle;

  /// No description provided for @attPrevMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan sebelumnya'**
  String get attPrevMonth;

  /// No description provided for @attNextMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan berikutnya'**
  String get attNextMonth;

  /// No description provided for @attAbsenError.
  ///
  /// In id, this message translates to:
  /// **'Riwayat absen gagal dimuat.'**
  String get attAbsenError;

  /// No description provided for @attAvgIn.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata masuk'**
  String get attAvgIn;

  /// No description provided for @attTotalHours.
  ///
  /// In id, this message translates to:
  /// **'Total jam kerja'**
  String get attTotalHours;

  /// No description provided for @attDaily.
  ///
  /// In id, this message translates to:
  /// **'Detail Harian'**
  String get attDaily;

  /// No description provided for @attDailyFiltered.
  ///
  /// In id, this message translates to:
  /// **'Detail Harian · {status}'**
  String attDailyFiltered(String status);

  /// No description provided for @attAbsenEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada riwayat absen di bulan ini.'**
  String get attAbsenEmpty;

  /// No description provided for @attNoStatusData.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada data dengan status {status}.'**
  String attNoStatusData(String status);

  /// No description provided for @weekdaysShort.
  ///
  /// In id, this message translates to:
  /// **'Sen,Sel,Rab,Kam,Jum,Sab,Min'**
  String get weekdaysShort;

  /// No description provided for @taskTitle.
  ///
  /// In id, this message translates to:
  /// **'Tugas'**
  String get taskTitle;

  /// No description provided for @taskAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah tugas'**
  String get taskAdd;

  /// No description provided for @taskLoadError.
  ///
  /// In id, this message translates to:
  /// **'Daftar tugas gagal dimuat.'**
  String get taskLoadError;

  /// No description provided for @taskSavedReady.
  ///
  /// In id, this message translates to:
  /// **'Tugas baru siap disimpan.'**
  String get taskSavedReady;

  /// No description provided for @taskSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari tugas'**
  String get taskSearch;

  /// No description provided for @taskOnDate.
  ///
  /// In id, this message translates to:
  /// **'Tugas {date}'**
  String taskOnDate(String date);

  /// No description provided for @taskShowAll.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan semua'**
  String get taskShowAll;

  /// No description provided for @taskEmptyFilter.
  ///
  /// In id, this message translates to:
  /// **'Belum ada tugas pada filter ini.'**
  String get taskEmptyFilter;

  /// No description provided for @taskEmptyToday.
  ///
  /// In id, this message translates to:
  /// **'Belum ada tugas untuk hari ini.'**
  String get taskEmptyToday;

  /// No description provided for @taskEmptyDate.
  ///
  /// In id, this message translates to:
  /// **'Belum ada tugas pada {date}.'**
  String taskEmptyDate(String date);

  /// No description provided for @taskProgressToday.
  ///
  /// In id, this message translates to:
  /// **'Progres hari ini'**
  String get taskProgressToday;

  /// No description provided for @taskProgressDate.
  ///
  /// In id, this message translates to:
  /// **'Progres {date}'**
  String taskProgressDate(String date);

  /// No description provided for @taskNone.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada tugas'**
  String get taskNone;

  /// No description provided for @taskProgressCount.
  ///
  /// In id, this message translates to:
  /// **'{done} dari {total} tugas selesai'**
  String taskProgressCount(int done, int total);

  /// No description provided for @taskHasPending.
  ///
  /// In id, this message translates to:
  /// **', ada tugas belum selesai'**
  String get taskHasPending;

  /// No description provided for @taskNoReminder.
  ///
  /// In id, this message translates to:
  /// **', tidak ada pengingat tugas'**
  String get taskNoReminder;

  /// No description provided for @taskFilterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua ({count})'**
  String taskFilterAll(int count);

  /// No description provided for @taskFilterPending.
  ///
  /// In id, this message translates to:
  /// **'Belum ({count})'**
  String taskFilterPending(int count);

  /// No description provided for @taskFilterDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai ({count})'**
  String taskFilterDone(int count);

  /// No description provided for @taskMarkUndone.
  ///
  /// In id, this message translates to:
  /// **'Tandai belum selesai'**
  String get taskMarkUndone;

  /// No description provided for @taskMarkDone.
  ///
  /// In id, this message translates to:
  /// **'Tandai selesai'**
  String get taskMarkDone;

  /// No description provided for @taskClearSearch.
  ///
  /// In id, this message translates to:
  /// **'Hapus pencarian'**
  String get taskClearSearch;

  /// No description provided for @taskNotFound.
  ///
  /// In id, this message translates to:
  /// **'Tugas tidak ditemukan.'**
  String get taskNotFound;

  /// No description provided for @taskPickDue.
  ///
  /// In id, this message translates to:
  /// **'Pilih tenggat tugas'**
  String get taskPickDue;

  /// No description provided for @taskNew.
  ///
  /// In id, this message translates to:
  /// **'Tugas Baru'**
  String get taskNew;

  /// No description provided for @taskFieldTitle.
  ///
  /// In id, this message translates to:
  /// **'Judul tugas'**
  String get taskFieldTitle;

  /// No description provided for @taskFieldTitleHint.
  ///
  /// In id, this message translates to:
  /// **'Siapkan materi presentasi Q4'**
  String get taskFieldTitleHint;

  /// No description provided for @taskFieldNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get taskFieldNote;

  /// No description provided for @taskFieldNoteHint.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan catatan (opsional)'**
  String get taskFieldNoteHint;

  /// No description provided for @taskDue.
  ///
  /// In id, this message translates to:
  /// **'Tenggat'**
  String get taskDue;

  /// No description provided for @taskDueToday.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get taskDueToday;

  /// No description provided for @taskDueTomorrow.
  ///
  /// In id, this message translates to:
  /// **'Besok'**
  String get taskDueTomorrow;

  /// No description provided for @taskDueWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu ini'**
  String get taskDueWeek;

  /// No description provided for @taskDuePick.
  ///
  /// In id, this message translates to:
  /// **'Pilih'**
  String get taskDuePick;

  /// No description provided for @taskPriority.
  ///
  /// In id, this message translates to:
  /// **'Prioritas'**
  String get taskPriority;

  /// No description provided for @taskPriorityLow.
  ///
  /// In id, this message translates to:
  /// **'Rendah'**
  String get taskPriorityLow;

  /// No description provided for @taskPriorityMedium.
  ///
  /// In id, this message translates to:
  /// **'Sedang'**
  String get taskPriorityMedium;

  /// No description provided for @taskPriorityHigh.
  ///
  /// In id, this message translates to:
  /// **'Tinggi'**
  String get taskPriorityHigh;

  /// No description provided for @taskSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan Tugas'**
  String get taskSave;

  /// No description provided for @taskRemind.
  ///
  /// In id, this message translates to:
  /// **'Ingatkan saya'**
  String get taskRemind;

  /// No description provided for @taskRemindHint.
  ///
  /// In id, this message translates to:
  /// **'30 menit sebelum tenggat'**
  String get taskRemindHint;

  /// No description provided for @taskMarkedDone.
  ///
  /// In id, this message translates to:
  /// **'Tugas ditandai selesai.'**
  String get taskMarkedDone;

  /// No description provided for @taskStatusUpdated.
  ///
  /// In id, this message translates to:
  /// **'Status tugas diperbarui.'**
  String get taskStatusUpdated;

  /// No description provided for @taskStatusFailed.
  ///
  /// In id, this message translates to:
  /// **'Status tugas gagal diperbarui. Coba lagi.'**
  String get taskStatusFailed;

  /// No description provided for @taskDetail.
  ///
  /// In id, this message translates to:
  /// **'Detail Tugas'**
  String get taskDetail;

  /// No description provided for @taskMenu.
  ///
  /// In id, this message translates to:
  /// **'Menu tugas'**
  String get taskMenu;

  /// No description provided for @taskComments.
  ///
  /// In id, this message translates to:
  /// **'Komentar'**
  String get taskComments;

  /// No description provided for @taskCommentsCount.
  ///
  /// In id, this message translates to:
  /// **'Komentar ({count})'**
  String taskCommentsCount(int count);

  /// No description provided for @taskMarkInProgress.
  ///
  /// In id, this message translates to:
  /// **'Tandai Berjalan'**
  String get taskMarkInProgress;

  /// No description provided for @taskMarkDoneTitle.
  ///
  /// In id, this message translates to:
  /// **'Tandai Selesai'**
  String get taskMarkDoneTitle;

  /// No description provided for @taskDetailError.
  ///
  /// In id, this message translates to:
  /// **'Detail tugas gagal dimuat.'**
  String get taskDetailError;

  /// No description provided for @taskPriorityLabel.
  ///
  /// In id, this message translates to:
  /// **'Prioritas {priority}'**
  String taskPriorityLabel(String priority);

  /// No description provided for @taskDescription.
  ///
  /// In id, this message translates to:
  /// **'Deskripsi'**
  String get taskDescription;

  /// No description provided for @taskSubtasks.
  ///
  /// In id, this message translates to:
  /// **'Subtugas'**
  String get taskSubtasks;

  /// No description provided for @taskSubtaskCount.
  ///
  /// In id, this message translates to:
  /// **'{done} dari {total}'**
  String taskSubtaskCount(int done, int total);

  /// No description provided for @taskAttachments.
  ///
  /// In id, this message translates to:
  /// **'{count} lampiran'**
  String taskAttachments(int count);

  /// No description provided for @taskDoneTitle.
  ///
  /// In id, this message translates to:
  /// **'Tugas Selesai'**
  String get taskDoneTitle;

  /// No description provided for @taskAssignedBy.
  ///
  /// In id, this message translates to:
  /// **'Ditugaskan oleh'**
  String get taskAssignedBy;

  /// No description provided for @taskStatus.
  ///
  /// In id, this message translates to:
  /// **'Status'**
  String get taskStatus;

  /// No description provided for @taskStatusInProgress.
  ///
  /// In id, this message translates to:
  /// **'Dikerjakan'**
  String get taskStatusInProgress;

  /// No description provided for @taskStatusDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get taskStatusDone;

  /// No description provided for @taskNoComments.
  ///
  /// In id, this message translates to:
  /// **'Belum ada komentar.'**
  String get taskNoComments;

  /// No description provided for @taskAddComment.
  ///
  /// In id, this message translates to:
  /// **'Tambah komentar'**
  String get taskAddComment;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
