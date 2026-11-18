# JAHRIS Mobile (Flutter)

## Stack
- Flutter (stable), Dart null-safety
- State management: flutter_riverpod (Notifier / AsyncNotifier)
- HTTP: dio, routing: go_router, token: flutter_secure_storage
- Backend: Next.js (REST API, Bearer token)

## Struktur wajib
lib/core/{config,l10n,network,router,storage,theme,utils,widgets}
lib/modules/<nama_modul>/ berisi TEPAT 4 file:
- model.dart     : entitas + fromJson/toJson
- service.dart   : panggilan API (Dio), tanpa state
- provider.dart  : Riverpod provider/notifier, memanggil service
- view.dart      : widget UI saja, memakai ConsumerWidget, tanpa logika bisnis
Modul: auth, dashboard, attendance, leave, task, reimburse, payroll, employee, branch, notification, profile.

## Aturan
- view.dart tidak boleh memanggil Dio langsung; selalu lewat provider.
- Modul tidak boleh import view.dart modul lain.
- Semua warna, radius, dan font diambil dari core/theme (jangan hardcode di view).
- Teks UI dwibahasa (Indonesia bawaan, Inggris opsional) lewat lib/core/l10n/app_id.arb & app_en.arb; di view pakai `context.l10n.<key>`, jalankan `flutter gen-l10n` setelah mengubah .arb. Migrasi bertahap: halaman yang belum dimigrasi masih teks Indonesia hardcode. Format Rupiah dan tanggal pakai intl (locale id_ID).
- Semua list wajib punya state loading, empty, dan error.
- Jalankan `flutter analyze` dan perbaiki semua warning sebelum selesai.
- Berikan file lengkap, siap pakai, bukan potongan.

## Desain
Sumber desain: Google Stitch (lewat MCP). Ikuti layout, warna, dan komponen dari Stitch.
Tema: dark navy + kartu glass, biru primer, aksen hijau/oranye/ungu. Tersedia mode terang.
Bottom nav melayang 5 item: Home, Cuti, Kehadiran, Tugas, Reimburse.