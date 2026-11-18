# Desain: Samakan Login JAHRIS dengan Referensi

## Tujuan
Samakan layar login Flutter dengan gambar 2: logo JAHRIS biru tua beraksen hijau, latar putih, header layanan pelanggan sederhana, ikon tema, dan panel login navy gelap dengan input abu-abu. Pengguna menginginkan kecocokan visual, bukan perubahan alur autentikasi.

## Cakupan
- Ubah hanya presentasi `lib/modules/auth/view.dart` dan token warna di `lib/core/theme/app_colors.dart` bila diperlukan.
- Pertahankan login, lupa password, visibilitas password, validasi, error, dukungan terang/gelap, dan seluruh aksi yang sudah ada.
- Samakan konten pada semua platform; status bar tetap native.
- Gunakan aset logo yang ada bila cocok; jangan menambah dependency.

## Bukan tujuan
Mengubah API/auth, navigasi, fitur, atau membuat status bar iPhone palsu di platform lain.

## Pendekatan
1. Menyetel ulang widget login dan warna terpusat agar cocok dengan gambar 2 — dipilih karena paling langsung dan mempertahankan perilaku.
2. Mengganti login dengan implementasi/komponen baru — ditolak karena menggandakan logika tanpa kebutuhan.
3. Mengubah hanya warna — ditolak karena logo, jarak, header, dan proporsi panel juga berbeda.

## Verifikasi
Jalankan `flutter analyze` dan tes terkait login yang tersedia. Periksa tampilan di ukuran mobile sempit serta tema terang/gelap.
