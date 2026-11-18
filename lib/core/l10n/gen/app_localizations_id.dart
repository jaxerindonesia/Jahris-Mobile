// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navAttendance => 'Kehadiran';

  @override
  String get navTask => 'Tugas';

  @override
  String get navProfile => 'Profil';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonRetry => 'Coba Lagi';

  @override
  String get commonSaving => 'Menyimpan...';

  @override
  String get commonShowPassword => 'Tampilkan password';

  @override
  String get commonHidePassword => 'Sembunyikan password';

  @override
  String get languageIndonesian => 'Indonesia';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePickerTitle => 'Pilih Bahasa';

  @override
  String get languagePickerSubtitle => 'Atur bahasa tampilan aplikasi.';

  @override
  String get languageIndonesianTitle => 'Bahasa Indonesia';

  @override
  String get languageIndonesianSub => 'Bawaan aplikasi';

  @override
  String get languageEnglishSub => 'Bahasa Inggris';

  @override
  String get languagePickerHint =>
      'Terjemahan diterapkan bertahap, beberapa halaman masih berbahasa Indonesia.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileLoadError => 'Profil gagal dimuat.';

  @override
  String get profileEdit => 'Ubah profil';

  @override
  String get profileEditFromAvatar => 'Ubah profil dari avatar';

  @override
  String get profileStatLeave => 'Sisa Cuti';

  @override
  String get profileStatPresent => 'Hadir Bulan Ini';

  @override
  String get profileStatOvertime => 'Lembur';

  @override
  String get profileSectionAccount => 'AKUN';

  @override
  String get profileSectionSettings => 'PENGATURAN';

  @override
  String get profileSectionOther => 'LAINNYA';

  @override
  String get profilePersonalData => 'Data Pribadi';

  @override
  String get profileDocuments => 'Dokumen Saya';

  @override
  String profileDocumentsCount(int count) {
    return '$count file';
  }

  @override
  String get profileBankAccount => 'Rekening Bank';

  @override
  String get profileBankNotSet => 'Belum diatur';

  @override
  String get profileNotifications => 'Notifikasi';

  @override
  String get profileDarkTheme => 'Tema Gelap';

  @override
  String get profileLanguage => 'Bahasa';

  @override
  String get profileSecurity => 'Keamanan & Password';

  @override
  String get profileHelp => 'Bantuan';

  @override
  String get profileAbout => 'Tentang Aplikasi';

  @override
  String get profileLogout => 'Keluar';

  @override
  String get profileLogoutTitle => 'Keluar dari Jahris?';

  @override
  String get profileLogoutBody => 'Sesi aktif Anda akan diakhiri.';

  @override
  String get profileFormTitle => 'Ubah Profil';

  @override
  String get profileFormName => 'Nama';

  @override
  String get profileFormEmail => 'Email';

  @override
  String get profileFormPhone => 'Telepon';

  @override
  String get profileFormSave => 'Simpan Profil';

  @override
  String get passwordFormTitle => 'Ubah Password';

  @override
  String get passwordCurrent => 'Password saat ini';

  @override
  String get passwordNew => 'Password baru';

  @override
  String get passwordConfirm => 'Konfirmasi password baru';

  @override
  String get passwordFormSubtitle =>
      'Gunakan password yang kuat dan belum pernah dipakai di akun lain.';

  @override
  String get passwordCurrentHint => 'Masukkan password saat ini';

  @override
  String get passwordNewHint => 'Minimal 6 karakter';

  @override
  String get passwordConfirmHint => 'Ulangi password baru';

  @override
  String get passwordStrengthWeak => 'Lemah';

  @override
  String get passwordStrengthMedium => 'Sedang';

  @override
  String get passwordStrengthStrong => 'Kuat';

  @override
  String get passwordStrengthLabel => 'Kekuatan password';

  @override
  String get passwordRuleLength => 'Minimal 6 karakter';

  @override
  String get passwordRuleMix => 'Kombinasi huruf besar, angka, atau simbol';

  @override
  String get passwordRuleMatch => 'Konfirmasi password sama';

  @override
  String get bankFormTitle => 'Rekening Bank';

  @override
  String get bankFormHint =>
      'Rekening ini dipakai untuk transfer gaji dan reimburse.';

  @override
  String get bankFormBank => 'Nama bank';

  @override
  String get bankFormNumber => 'Nomor rekening';

  @override
  String get bankFormHolder => 'Nama pemilik rekening';

  @override
  String get bankFormSave => 'Simpan Rekening';

  @override
  String get dashboardShift => 'Shift Pagi · 08:15 – 17:15';

  @override
  String get dashboardCheckIn => 'Check In';

  @override
  String get dashboardScanHint => 'Tap untuk scan wajah';

  @override
  String get dashboardLocation => 'Kantor Pusat · dalam radius';

  @override
  String get dashboardIn => 'Masuk';

  @override
  String get dashboardOut => 'Pulang';

  @override
  String get dashboardTotal => 'Total';

  @override
  String get dashboardLeave => 'Izin/Cuti';

  @override
  String get dashboardReimburse => 'Reimburse';

  @override
  String get dashboardPettyCash => 'Petty Cash';

  @override
  String get dashboardMore => 'Lainnya';

  @override
  String dashboardNextHoliday(String name) {
    return 'Libur berikutnya: $name';
  }

  @override
  String get dashboardMyRequests => 'Pengajuan Saya';

  @override
  String get dashboardNoRequests => 'Belum ada pengajuan terbaru.';

  @override
  String get dashboardSummaryError => 'Ringkasan belum dapat dimuat.';

  @override
  String get serviceAttendanceHistory => 'Riwayat Absen';

  @override
  String get serviceShift => 'Jadwal Shift';

  @override
  String get serviceOvertime => 'Lembur';

  @override
  String get servicePayslip => 'Slip Gaji';

  @override
  String get serviceHoliday => 'Kalender Libur';

  @override
  String get serviceHelp => 'Bantuan';

  @override
  String get servicesTitle => 'Semua Layanan';

  @override
  String get servicesSearch => 'Cari layanan...';

  @override
  String get servicesEmpty => 'Layanan tidak ditemukan.';

  @override
  String get loginSupport => 'Layanan Pelanggan';

  @override
  String get splashPoweredBy => 'Powered by';

  @override
  String get loginToggleTheme => 'Ganti tema';

  @override
  String get loginWelcome => 'Selamat datang di Jahris';

  @override
  String get loginTagline =>
      'Satu akses untuk semua aktivitas kerja.\nAbsen, cek jadwal, dan ajukan cuti dari genggaman.';

  @override
  String get loginToggleSheet => 'Buka atau tutup panel login';

  @override
  String get loginEmail => 'Email Address*';

  @override
  String get loginPassword => 'Password*';

  @override
  String get loginForgot => 'Lupa kata sandi?';

  @override
  String get loginConsent =>
      'Dengan melanjutkan, saya menyetujui pemrosesan data pribadi saya sesuai dengan ';

  @override
  String get loginTerms => 'Ketentuan Layanan';

  @override
  String get loginAnd => ' dan ';

  @override
  String get loginPrivacy => 'Kebijakan Privasi JAHRIS';

  @override
  String get loginSubmit => 'Masuk ke Jahris';

  @override
  String loginWhatsappError(String phone) {
    return 'WhatsApp tidak dapat dibuka. Hubungi $phone.';
  }

  @override
  String get loginResetSent => 'Petunjuk reset password telah dikirim.';

  @override
  String get forcePasswordTitle => 'Ganti Password';

  @override
  String get forcePasswordHeading => 'Buat password baru';

  @override
  String get forcePasswordBody =>
      'Admin mewajibkan Anda mengganti password sebelum melanjutkan.';

  @override
  String get forcePasswordCurrentRequired => 'Password saat ini wajib diisi.';

  @override
  String get forcePasswordSave => 'Simpan Password Baru';

  @override
  String get logoLabel => 'Logo JAHRIS';

  @override
  String get attTitle => 'Kehadiran';

  @override
  String get attSubtitle => 'Rekap kehadiran kamu';

  @override
  String get attLoadError => 'Data kehadiran gagal dimuat.';

  @override
  String get attPickMonth => 'Pilih bulan kehadiran';

  @override
  String attSummary(String month) {
    return 'Ringkasan $month';
  }

  @override
  String get attRecent => 'Riwayat Terbaru';

  @override
  String get attSeeAll => 'Lihat semua';

  @override
  String get attEmptyMonth => 'Belum ada riwayat kehadiran pada bulan ini.';

  @override
  String get attHistoryTitle => 'Riwayat Kehadiran';

  @override
  String get attHistoryError => 'Riwayat kehadiran gagal dimuat.';

  @override
  String get attHistoryEmpty => 'Belum ada riwayat kehadiran.';

  @override
  String get attLoadMore => 'Muat lainnya';

  @override
  String get attToday => 'Hari ini';

  @override
  String get attIn => 'Masuk';

  @override
  String get attOut => 'Pulang';

  @override
  String get attDuration => 'Durasi';

  @override
  String attShift(String start, String end) {
    return 'Shift Pagi · $start – $end';
  }

  @override
  String get attPresent => 'Hadir';

  @override
  String get attLate => 'Terlambat';

  @override
  String get attLeave => 'Izin/Cuti';

  @override
  String get attAbsent => 'Alpha';

  @override
  String get attRate => 'Tingkat kehadiran';

  @override
  String get attNotOut => 'Belum pulang';

  @override
  String attHoursMinutes(String h, String m) {
    return '${h}j ${m}m';
  }

  @override
  String attHoursShort(String h) {
    return '${h}j';
  }

  @override
  String get attStatusAll => 'Semua';

  @override
  String get attStatusOnTime => 'Tepat Waktu';

  @override
  String get attStatusLate => 'Terlambat';

  @override
  String get attStatusPermit => 'Izin';

  @override
  String get attStatusAbsent => 'Alpha';

  @override
  String get attStatusWorking => 'Sedang Bekerja';

  @override
  String get attStatusDone => 'Selesai';

  @override
  String get attStatusNotIn => 'Belum Masuk';

  @override
  String get attLegendOnTime => 'Tepat waktu';

  @override
  String get attBack => 'Kembali';

  @override
  String get attHistoryAbsen => 'Riwayat Absen';

  @override
  String get attFilterStatus => 'Filter status';

  @override
  String get attFilterTitle => 'Filter Status';

  @override
  String get attPrevMonth => 'Bulan sebelumnya';

  @override
  String get attNextMonth => 'Bulan berikutnya';

  @override
  String get attAbsenError => 'Riwayat absen gagal dimuat.';

  @override
  String get attAvgIn => 'Rata-rata masuk';

  @override
  String get attTotalHours => 'Total jam kerja';

  @override
  String get attDaily => 'Detail Harian';

  @override
  String attDailyFiltered(String status) {
    return 'Detail Harian · $status';
  }

  @override
  String get attAbsenEmpty => 'Belum ada riwayat absen di bulan ini.';

  @override
  String attNoStatusData(String status) {
    return 'Tidak ada data dengan status $status.';
  }

  @override
  String get weekdaysShort => 'Sen,Sel,Rab,Kam,Jum,Sab,Min';

  @override
  String get taskTitle => 'Tugas';

  @override
  String get taskAdd => 'Tambah tugas';

  @override
  String get taskLoadError => 'Daftar tugas gagal dimuat.';

  @override
  String get taskSavedReady => 'Tugas baru siap disimpan.';

  @override
  String get taskSearch => 'Cari tugas';

  @override
  String taskOnDate(String date) {
    return 'Tugas $date';
  }

  @override
  String get taskShowAll => 'Tampilkan semua';

  @override
  String get taskEmptyFilter => 'Belum ada tugas pada filter ini.';

  @override
  String get taskEmptyToday => 'Belum ada tugas untuk hari ini.';

  @override
  String taskEmptyDate(String date) {
    return 'Belum ada tugas pada $date.';
  }

  @override
  String get taskProgressToday => 'Progres hari ini';

  @override
  String taskProgressDate(String date) {
    return 'Progres $date';
  }

  @override
  String get taskNone => 'Tidak ada tugas';

  @override
  String taskProgressCount(int done, int total) {
    return '$done dari $total tugas selesai';
  }

  @override
  String get taskHasPending => ', ada tugas belum selesai';

  @override
  String get taskNoReminder => ', tidak ada pengingat tugas';

  @override
  String taskFilterAll(int count) {
    return 'Semua ($count)';
  }

  @override
  String taskFilterPending(int count) {
    return 'Belum ($count)';
  }

  @override
  String taskFilterDone(int count) {
    return 'Selesai ($count)';
  }

  @override
  String get taskMarkUndone => 'Tandai belum selesai';

  @override
  String get taskMarkDone => 'Tandai selesai';

  @override
  String get taskClearSearch => 'Hapus pencarian';

  @override
  String get taskNotFound => 'Tugas tidak ditemukan.';

  @override
  String get taskPickDue => 'Pilih tenggat tugas';

  @override
  String get taskNew => 'Tugas Baru';

  @override
  String get taskFieldTitle => 'Judul tugas';

  @override
  String get taskFieldTitleHint => 'Siapkan materi presentasi Q4';

  @override
  String get taskFieldNote => 'Catatan';

  @override
  String get taskFieldNoteHint => 'Tambahkan catatan (opsional)';

  @override
  String get taskDue => 'Tenggat';

  @override
  String get taskDueToday => 'Hari ini';

  @override
  String get taskDueTomorrow => 'Besok';

  @override
  String get taskDueWeek => 'Minggu ini';

  @override
  String get taskDuePick => 'Pilih';

  @override
  String get taskPriority => 'Prioritas';

  @override
  String get taskPriorityLow => 'Rendah';

  @override
  String get taskPriorityMedium => 'Sedang';

  @override
  String get taskPriorityHigh => 'Tinggi';

  @override
  String get taskSave => 'Simpan Tugas';

  @override
  String get taskRemind => 'Ingatkan saya';

  @override
  String get taskRemindHint => '30 menit sebelum tenggat';

  @override
  String get taskMarkedDone => 'Tugas ditandai selesai.';

  @override
  String get taskStatusUpdated => 'Status tugas diperbarui.';

  @override
  String get taskStatusFailed => 'Status tugas gagal diperbarui. Coba lagi.';

  @override
  String get taskDetail => 'Detail Tugas';

  @override
  String get taskMenu => 'Menu tugas';

  @override
  String get taskComments => 'Komentar';

  @override
  String taskCommentsCount(int count) {
    return 'Komentar ($count)';
  }

  @override
  String get taskMarkInProgress => 'Tandai Berjalan';

  @override
  String get taskMarkDoneTitle => 'Tandai Selesai';

  @override
  String get taskDetailError => 'Detail tugas gagal dimuat.';

  @override
  String taskPriorityLabel(String priority) {
    return 'Prioritas $priority';
  }

  @override
  String get taskDescription => 'Deskripsi';

  @override
  String get taskSubtasks => 'Subtugas';

  @override
  String taskSubtaskCount(int done, int total) {
    return '$done dari $total';
  }

  @override
  String taskAttachments(int count) {
    return '$count lampiran';
  }

  @override
  String get taskDoneTitle => 'Tugas Selesai';

  @override
  String get taskAssignedBy => 'Ditugaskan oleh';

  @override
  String get taskStatus => 'Status';

  @override
  String get taskStatusInProgress => 'Dikerjakan';

  @override
  String get taskStatusDone => 'Selesai';

  @override
  String get taskNoComments => 'Belum ada komentar.';

  @override
  String get taskAddComment => 'Tambah komentar';
}
