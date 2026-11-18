// Katalog FAQ statis — belum ada endpoint API khusus bantuan.

import '../../core/theme/help_theme.dart';
import 'model.dart';

const helpCategories = <HelpCategory>[
  HelpCategory(
    id: 'absensi',
    label: 'Absensi',
    iconAsset: 'assets/icons/help/absensi.svg',
    color: HelpTheme.absensi,
  ),
  HelpCategory(
    id: 'cuti',
    label: 'Cuti',
    iconAsset: 'assets/icons/help/cuti.svg',
    color: HelpTheme.cuti,
  ),
  HelpCategory(
    id: 'gaji',
    label: 'Gaji',
    iconAsset: 'assets/icons/help/gaji.svg',
    color: HelpTheme.gaji,
  ),
  HelpCategory(
    id: 'akun',
    label: 'Akun',
    iconAsset: 'assets/icons/help/akun.svg',
    color: HelpTheme.akun,
  ),
];

const helpFaqs = <FaqItem>[
  FaqItem(
    question: 'Kenapa saya tidak bisa check-in?',
    answer:
        'Pastikan GPS aktif dan kamu berada dalam radius kantor. '
        'Jika wajah tidak terdeteksi, cari tempat dengan pencahayaan cukup.',
    categoryId: 'absensi',
  ),
  FaqItem(
    question: 'Bagaimana cara mengajukan cuti?',
    answer:
        'Buka menu Cuti, pilih tanggal mulai–selesai, tulis alasan, '
        'lalu kirim. Pengajuan akan direview oleh atasan kamu.',
    categoryId: 'cuti',
  ),
  FaqItem(
    question: 'Kapan slip gaji tersedia?',
    answer:
        'Slip gaji tersedia setiap tanggal 1 untuk periode bulan '
        'sebelumnya di menu Slip Gaji.',
    categoryId: 'gaji',
  ),
  FaqItem(
    question: 'Cara mengganti password akun',
    answer:
        'Buka menu Profil, pilih Keamanan, lalu Ubah Password. '
        'Konfirmasi dengan password lama sebelum membuat password baru.',
    categoryId: 'akun',
  ),
];
