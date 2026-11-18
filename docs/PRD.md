PRD — JAHRIS Mobile App (Flutter)
Produk: JAHRIS Mobile v1.0 · Pemilik: PT Jaxer Grup Indonesia · Basis: web dev.jahris.id
(v2.0.17) · Stack: Flutter + Riverpod · Backend Next.js
1. Ringkasan
JAHRIS adalah sistem HR Management multi-tenant berbasis web. Versi mobile Flutter
dibuat agar karyawan dan admin dapat melakukan aktivitas harian (absensi, cuti, tugas,
reimburse, payroll, kelola karyawan) langsung dari smartphone dengan pengalaman
native: lebih cepat, akses GPS/kamera yang stabil, dan notifikasi push.
PRD ini disusun dari tampilan web yang sudah ada: Login, Dashboard, Cabang, Karyawan,
Kehadiran, dan Payroll. Gambar referensi pertama (aplikasi dengan kartu glass bergaya
modern) dipakai sebagai inspirasi gaya kartu, sedangkan identitas visual tetap mengikuti
JAHRIS: navy/biru dengan tema glass.
2.Tujuan dan Metrik
Non-goals v1: fitur baru di luar web (hanya porting + penyesuaian mobile), versi
tablet/desktop, mode offline penuh (hanya cache baca).
Tujuan Metrik keberhasilan
Absensi mudah dari HP Check In/Out selesai kurang dari 5 detik setelah
lokasi terkunci
Mengurangi pekerjaan admin di
desktop
Minimal 70% persetujuan cuti/reimburse
dilakukan lewat mobile
Pengalaman mobile lebih baik dari web Waktu buka aplikasi (cold start) kurang dari 3
detik
Stabil Crash-free sessions di atas 99%
Adopsi 60% karyawan aktif per tenant memakai mobile
dalam 3 bulan
PRD JAHRIS Mobile (Flutter)
Page 1 of 13
3. Pengguna dan Peran
Menu dan tombol ditampilkan sesuai role (RBAC) dari backend.
4.Inventaris Layar dariWeb
Peran Kebutuhan utama di mobile
Karyawan Check In/Out, ajukan cuti, lihat tugas, ajukan
reimburse, lihat slip gaji
Atasan/Manajer Setujui cuti, reimburse, dan tugas tim
Admin Tenant (contoh: Admin JGI) Dashboard ringkasan, kelola karyawan, cabang,
departemen, konfigurasi kehadiran, komponen
payroll
SuperAdmin (opsional) Pindah tenant bila diperlukan
# Layar Isi yang terlihat di web Penyesuaian di mobile
1 Login Logo, Selamat Datang, Email,
Password (toggle lihat), Ingat
saya, tombol Masuk ke
Dashboard
Tambah biometrik (opsional) dan
lupa password
2 Dashboard Kartu Total Karyawan, Karyawan
Aktif (dengan jumlah tidak
aktif), Total Departemen, dst.
Kartu bisa diketuk menuju daftar
terkait; pull-to-refresh
3 Cabang Tabel: Nama Cabang, Kode,
Radius, kolom lain; tombol
Tambah dan Filter
Ganti tabel yang terpotong menjadi
daftar kartu; form dengan pemilih
peta untuk radius
4 Karyawan Kelola Departemen, Tambah,
Filter, Download Semua PDF,
Export Excel, Import; tabel
Karyawan dan NIK
Daftar kartu dengan pencarian; aksi
Export/Import/PDF dipindah ke
menu aksi (bottom sheet)
PRD JAHRIS Mobile (Flutter)
Page 2 of 13
Catatan: layar 7-9 belum ada di tangkapan layar, sehingga rincian field perlu dikonfirmasi
dari web.
5. Kebutuhan Fungsional
5.1 Auth
Login email dan password ke API Next.js; simpan access dan refresh token di secure
storage.
Ingat saya, lupa password, logout, sesi kedaluwarsa otomatis menuju login.
Opsional: kunci aplikasi dengan biometrik.
5.2 Dashboard
Sapaan nama pengguna, kartu statistik (karyawan, aktif/tidak aktif, departemen, dan
lainnya sesuai role).
Tombol ganti tema terang/gelap dan menu hamburger (profil, ganti tenant, pengaturan,
logout).
Karyawan biasa melihat ringkasan pribadi: status absen hari ini, sisa cuti, tugas aktif.
# Layar Isi yang terlihat di web Penyesuaian di mobile
5 Kehadiran Jam berjalan, jam default tenant
(08:15 - 17:15), Check In, info izin
lokasi, Konfigurasi Kehadiran,
Filter, Export Excel, daftar
riwayat
Check In/Out sebagai aksi utama;
izin lokasi diminta dengan
penjelasan; validasi radius cabang
6 Payroll Kartu Gaji Dibayarkan, Gaji
Pending, Total Gaji (tahun
berjalan), Kelola Komponen
Payroll
Tampilan admin dan tampilan slip
gaji pribadi untuk karyawan
7 Cuti Menu bawah (belum ada
tangkapan layar)
Form pengajuan, saldo cuti, status
persetujuan
8 Tugas Menu bawah (belum ada
tangkapan layar)
Daftar tugas, status, detail
9 Reimburse Menu bawah (belum ada
tangkapan layar)
Form dengan foto bukti, status
persetujuan
PRD JAHRIS Mobile (Flutter)
Page 3 of 13
PRD JAHRIS Mobile (Flutter)
5.3 Kehadiran
Jam real-time dan jam kerja default tenant.
Check In/Out dengan GPS, validasi radius cabang, dan penanda terlambat.
Riwayat dengan filter tanggal dan karyawan; Export Excel (admin).
Konfigurasi Kehadiran (admin): jam kerja, toleransi, cabang dan radius.
Status izin lokasi jelas (belum diizinkan, ditolak, diizinkan) dengan tombol menuju
pengaturan.
5.4 Cuti
Ajukan cuti (jenis, tanggal, alasan, lampiran), lihat saldo dan riwayat.
Persetujuan oleh atasan/admin dengan catatan.
5.5Tugas
Daftar tugas dengan filter status, detail, ubah status, komentar singkat.
5.6 Reimburse
Ajukan reimburse (kategori, nominal, tanggal, foto struk dari kamera/galeri).
Alur persetujuan dan status pembayaran.
5.7 Payroll
Admin: ringkasan Gaji Dibayarkan, Pending, Total per tahun; kelola komponen payroll.
Karyawan: daftar slip gaji dan detail, unduh PDF.
5.8 Karyawan, Departemen, Cabang (Admin)
CRUD, pencarian, filter, kelola departemen.
Download PDF, Export Excel, dan Import dijalankan oleh backend; mobile memanggil
API lalu membuka/membagikan file.
5.9 Notifikasi
Push notification (FCM) untuk persetujuan, pengingat absen, dan status pengajuan.
Page 4 of 13
6. Arsitektur
Flutter App (Riverpod)
View -> Provider (Notifier) -> Service (Dio) -> Next.js API (/api/...) ->
Database
Presentation: view.dart (widget saja, tanpa logika bisnis).
State: provider.dart (Riverpod Notifier / AsyncNotifier ).
Data: service.dart (panggilan HTTP) dan model.dart (entitas dan JSON).
Routing: go_router dengan guard login dan role.
HTTP: Dio dengan interceptor token (pasang header, auto refresh, tangani 401).
Paket utama: flutter_riverpod, dio, go_router, flutter_secure_storage, geolocator,
permission_handler, image_picker, intl, firebase_messaging, open_filex / share_plus.
7. Struktur Folder
Setiap modul memiliki folder sendiri berisi empat file: service.dart , view.dart ,
model.dart , provider.dart .
lib/
├── main.dart
├── app.dart # MaterialApp.router, tema, ProviderScope
├── core/
│ ├── config/env.dart # base URL API
│ ├── network/dio_client.dart # Dio + interceptor token
│ ├── router/app_router.dart
│ ├── storage/secure_storage.dart
│ ├── theme/ # app_colors.dart, app_theme.dart
│ ├── utils/ # formatter rupiah, tanggal, validator
│ └── widgets/ # glass_card, primary_button, stat_card,
bottom_nav
└── modules/
├── auth/
│ ├── service.dart
│ ├── view.dart
│ ├── model.dart
│ └── provider.dart
├── dashboard/ (service, view, model, provider)
├── attendance/ (service, view, model, provider) # Kehadiran
├── leave/ (service, view, model, provider) # Cuti
PRD JAHRIS Mobile (Flutter)
Page 5 of 13
├── task/ (service, view, model, provider) # Tugas
├── reimburse/ (service, view, model, provider)
├── payroll/ (service, view, model, provider)
├── employee/ (service, view, model, provider) # Karyawan +
departemen
├── branch/ (service, view, model, provider) # Cabang
├── notification/ (service, view, model, provider)
└── profile/ (service, view, model, provider) # profil, tema,
tenant
Aturan: modul tidak saling import view.dart ; berbagi data lewat provider. Komponen UI
bersama ada di core/widgets .
Contoh pola (modul attendance)
// model.dart
class AttendanceRecord {
final String id;
final String employeeName;
final DateTime date;
final DateTime? checkIn;
final DateTime? checkOut;
final String status;
AttendanceRecord({required this.id, required this.employeeName, required
this.date, this.checkIn, this.checkOut, required this.status});
factory AttendanceRecord.fromJson(Map<String, dynamic> j) =>
AttendanceRecord(
id: j['id'].toString(),
employeeName: j['employeeName'] ?? '',
date: DateTime.parse(j['date']),
checkIn: j['checkIn'] != null ? DateTime.parse(j['checkIn']) : null,
checkOut: j['checkOut'] != null ? DateTime.parse(j['checkOut']) :
null,
status: j['status'] ?? '',
);
}
// service.dart
class AttendanceService {
final Dio _dio;
PRD JAHRIS Mobile (Flutter)
Page 6 of 13
AttendanceService(this._dio);
Future<List<AttendanceRecord>> list({DateTime? from, DateTime? to}) async {
final res = await _dio.get('/attendance', queryParameters: {
if (from != null) 'from': from.toIso8601String(),
if (to != null) 'to': to.toIso8601String(),
});
return (res.data['data'] as List).map((e) =>
AttendanceRecord.fromJson(e)).toList();
}
Future<void> check({required bool isIn, required double lat, required
double lng}) async {
await _dio.post(isIn ? '/attendance/check-in' : '/attendance/check-out',
data: {'lat': lat, 'lng': lng});
}
}
// provider.dart
final attendanceServiceProvider = Provider((ref) =>
AttendanceService(ref.watch(dioProvider)));
class AttendanceNotifier extends AsyncNotifier<List<AttendanceRecord>> {
@override
Future<List<AttendanceRecord>> build() =>
ref.read(attendanceServiceProvider).list();
Future<void> check(bool isIn, double lat, double lng) async {
await ref.read(attendanceServiceProvider).check(isIn: isIn, lat: lat,
lng: lng);
ref.invalidateSelf();
}
}
final attendanceProvider = AsyncNotifierProvider<AttendanceNotifier,
List<AttendanceRecord>>(AttendanceNotifier.new);
// view.dart -> ConsumerWidget yang memakai
ref.watch(attendanceProvider).when(...)
PRD JAHRIS Mobile (Flutter)
Page 7 of 13
8. Kontrak API(Usulan untukBackend Next.js)
Endpoint di bawah adalah usulan dan perlu disesuaikan dengan route Next.js yang sudah
ada. Semua endpoint memakai Authorization: Bearer <token> , tenant ditentukan dari
token, dan respons berformat { data, meta, error } .
Kebutuhan sisi backend: pagination dan filter pada semua list, validasi radius lokasi di
server (jangan hanya di klien), refresh token, rate limit login, dan versi API
( /api/mobile/v1 ).
Modul Endpoint
Auth POST /auth/login , POST /auth/refresh , POST
/auth/logout , POST /auth/forgot-password ,
GET /me
Dashboard GET /dashboard/summary
Kehadiran GET /attendance , POST /attendance/check-in ,
POST /attendance/check-out , GET/PUT
/attendance/config
Cuti GET/POST /leaves , GET /leaves/balance , PATCH
/leaves/:id/approve , PATCH
/leaves/:id/reject
Tugas GET/POST /tasks , GET/PATCH /tasks/:id
Reimburse GET/POST /reimbursements , PATCH
/reimbursements/:id/approve , upload lampiran
Payroll GET /payroll/summary , GET /payroll/slips ,
GET/POST/PUT /payroll/components
Karyawan GET/POST /employees , GET/PUT/DELETE
/employees/:id , GET /employees/export , POST
/employees/import , GET/POST /departments
Cabang GET/POST /branches , PUT/DELETE
/branches/:id
Notifikasi POST /devices (daftar token FCM), GET
/notifications
PRD JAHRIS Mobile (Flutter)
Page 8 of 13
9. Kebutuhan Non-Fungsional
Keamanan: token di secure storage, HTTPS saja, validasi lokasi di server, RBAC di
server, data sensitif (gaji) tidak masuk log, opsi kunci biometrik.
Performa: cold start kurang dari 3 detik, daftar dengan pagination dan lazy loading,
cache baca ringan.
Platform: Android 8+ dan iOS 14+.
Aksesibilitas: ukuran tap minimal 48dp, kontras teks memadai, mendukung ukuran font
sistem.
Bahasa: Bahasa Indonesia (default), struktur siap untuk multi-bahasa.
Penanganan error: pesan jelas untuk offline, lokasi nonaktif, dan sesi habis.
10. Design System
Elemen Ketentuan
Gaya Dark navy dengan kartu glass (blur halus, border
tipis), mengikuti web; mode terang tersedia
Warna utama Biru primer (tombol utama), navy gelap untuk latar
Warna status Biru (karyawan), hijau (aktif/dibayarkan/Check In),
oranye (pending), ungu (total/kelola)
Tipografi Sans-serif bersih, judul tebal, label kecil untuk
keterangan
Komponen Header dengan logo JAXER, toggle tema,
hamburger; bottom nav melayang 5 item (Home,
Cuti, Kehadiran, Tugas, Reimburse); kartu statistik;
tombol outline berwarna; daftar kartu pengganti
tabel
Perbaikan dari web Tabel lebar diganti kartu; aksi sekunder dipindah ke
bottom sheet; tombol utama tetap terlihat
PRD JAHRIS Mobile (Flutter)
Page 9 of 13
PRD JAHRIS Mobile (Flutter)
11. Prompt untuk Google Stitch
11.1 Prompt Master (tempel pertama)
Design a mobile app (iPhone 13 size, 390x844) called JAHRIS, an HR Management
System for Indonesian companies by Jaxer Grup Indonesia. Language:
Indonesian.
Style: dark navy background (#0B1220 to #0F1B3D), glassmorphism cards with
subtle blur, thin 1px translucent borders and rounded corners (20px). Primary
color vivid blue (#2563EB). Status accents: green (#10B981) for
active/paid/check-in, orange (#F59E0B) for pending, purple (#8B5CF6) for
totals, blue for employees. Clean modern sans-serif font, bold headings,
small muted captions. Keep it simple, elegant and professional; no neon glow.
Global components: top header with the JAXER logo on the left, a theme toggle
(sun icon) and a blue circular hamburger button on the right. Floating glass
bottom navigation bar with 5 items: Home, Cuti, Kehadiran, Tugas, Reimburse
(active item shown as a blue pill with icon and label).
Follow this style for all screens I request next.
11.2 Prompt per layar
Login
Login screen. Centered glass card on a dark navy background. Logo mark at
top, title 'Selamat Datang', subtitle 'Satu akses untuk semua aktivitas
kerja'. Fields: 'Email Address' (placeholder nama@domain.com, mail icon) and
'Password' (lock icon, show/hide eye). Checkbox 'Ingat saya', link 'Lupa
password?'. Full-width blue button 'Masuk ke Dashboard' with arrow. Footer:
JAXER logo and '©2026 Jahris v2.0.17 • Jaxer Grup Indonesia.'
Dashboard Admin
Admin dashboard. Greeting 'Selamat datang kembali, Admin JGI' (name in blue)
and a short description. Vertical stack of colorful rounded stat cards with
icon at the right: blue 'Total Karyawan 30 - Karyawan di tenant Anda', green
'Karyawan Aktif 22 - 8 tidak aktif', purple 'Total Departemen 5', orange card
for pending approvals (cuti/reimburse). Below: 'Pengajuan Terbaru' list.
Floating bottom nav with Home active.
Page 10 of 13
PRD JAHRIS Mobile (Flutter)
Kehadiran
Attendance screen. Glass card with date 'Selasa, 20 Oktober 2026', large live
clock '09.05.28', and chips 'Default tenant 08:15 - 17:15'. Large green full￾width button 'Check In' with login icon. Orange helper text 'Lokasi belum
diizinkan. Klik Check In/Out untuk memberikan izin lokasi.' Secondary
buttons: 'Konfigurasi Kehadiran' (gear), 'Filter' (outline), 'Export Excel'
(green outline). Below: 'Riwayat Kehadiran' as a list of cards (employee
name, date, check-in/out time, status chip Tepat Waktu / Terlambat). Bottom
nav with Kehadiran active.
Karyawan
Employee list screen for admin. Search bar and 'Filter' button. Primary blue
button '+ Tambah'. A 'Aksi' button opening a bottom sheet with: Kelola
Departemen, Download Semua PDF, Export Excel, Import. List of employee cards:
avatar, name, NIK, department, branch, status chip Aktif/Tidak Aktif.
Pagination info 'Menampilkan 10 dari 30 data'.
Cabang
Branch list screen. Blue button '+ Tambah' and 'Filter'. List of glass cards:
branch name (Batam, Medan, Pusat), code chip (BATAM, MEDAN, PUSAT), radius
(100 m, 100 m, 50 m), and a small map thumbnail. Footer: 'Menampilkan 3 dari
3 data - Halaman 1 dari 1'. Add-branch form: name, code, address, map picker
with radius slider.
Payroll
Payroll screen. Three large cards: green 'Gaji Dibayarkan Rp 0 - Tahun 2026'
with check icon, orange 'Gaji Pending Rp 0 - Tahun 2026' with clock icon,
purple 'Total Gaji Rp 0 - Tahun 2026'. Button 'Kelola Komponen Payroll'
(gear). Below: list of payroll periods with status chips. Bottom nav.
Cuti, Tugas, Reimburse (karyawan)
Three screens in the same style. 1) Cuti: leave balance card, list of
requests with status chips (Menunggu, Disetujui, Ditolak), floating button
'Ajukan Cuti'. 2) Tugas: segmented tabs (Semua, Berjalan, Selesai), task
cards with title, due date, priority and assignee. 3) Reimburse: summary card
of total submitted, list of claims with amount in Rupiah and status, button
'Ajukan Reimburse' opening a form with category, amount, date, and receipt
photo upload.
Page 11 of 13
Menu (hamburger)
Side drawer / bottom sheet menu: user profile header (avatar, name, role,
tenant), items: Karyawan, Cabang, Payroll, Pengaturan Kehadiran, Notifikasi,
Mode Terang/Gelap, Ganti Tenant, Keluar (red).
Tips: hasilkan layar satu per satu, simpan sebagai satu proyek agar gaya konsisten, lalu
ekspor ke Figma atau ambil kodenya sebagai acuan komponen Flutter.
12. Roadmap
13. Risiko dan PertanyaanTerbuka
Apakah semua endpoint di atas sudah ada di Next.js, atau perlu dibuat khusus mobile
( /api/mobile/v1 )?
Metode auth saat ini (cookie/session atau JWT)? Mobile idealnya memakai token
Bearer.
Detail field untuk Cuti, Tugas, dan Reimburse perlu dikonfirmasi dari web.
Kebijakan anti-fake GPS dan verifikasi selfie saat absen (apakah diperlukan?).
Ekspor/Import file besar: dijalankan di server dan diunduh lewat tautan sementara.
Distribusi: publik di store atau lewat MDM/internal per tenant.
Apakah tema terang perlu dirilis bersamaan dengan tema gelap di v1.
Fase Cakupan Estimasi
0 Finalisasi PRD, desain Stitch, kontrak API 1 minggu
1 Fondasi: tema, router, Dio, auth, dashboard 2 minggu
2 Kehadiran (GPS, riwayat) dan Cabang 2 minggu
3 Cuti, Tugas, Reimburse 3 minggu
4 Payroll, Karyawan, ekspor/impor 2 minggu
5 Push notification, QA, UAT, rilis Play Store dan App
Store
2 minggu
PRD JAHRIS Mobile (Flutter)
Page 12 of 13
PRD JAHRIS Mobile (Flutter)
14. Kriteria Penerimaan v1
Semua layar pada bagian 4 berfungsi sesuai role.
Check In/Out menolak lokasi di luar radius cabang (divalidasi server).
Tidak ada tabel yang terpotong horizontal di layar 360px.
Struktur setiap modul mengikuti pola service.dart , view.dart , model.dart ,
provider.dart .
Seluruh state dikelola dengan Riverpod; tidak ada logika bisnis di view.dart .
Page 13 of 13
