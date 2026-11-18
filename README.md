# JAHRIS Mobile

Aplikasi HR Management Flutter untuk PT Jaxer Grup Indonesia. Seluruh modul
mobile tersedia: autentikasi, dashboard, kehadiran, cuti, tugas, reimburse,
payroll, karyawan, cabang, notifikasi, dan profil. Aplikasi memakai tema Stitch
dark/light, Dio dengan sesi cookie persisten di secure storage, dan guard
navigasi.

## Menjalankan aplikasi

API web aktif secara default:

```sh
flutter run --dart-define=API_BASE_URL=https://dev.jahris.id/api
```

Untuk Flutter Web lokal, browser memerlukan proxy karena API produksi tidak
mengizinkan cookie lintas origin dari `localhost`. Jalankan proxy di terminal
pertama, lalu Flutter di terminal kedua:

```sh
dart run tool/dev_api_proxy.dart
flutter run -d chrome
```

Proxy hanya mendengarkan `127.0.0.1:3000` dan meneruskan path `/dev-api` ke
`https://dev.jahris.id/api`. Jangan gunakan proxy development ini di produksi.

## Lokasi kode API

- Base URL dan flag mock: `lib/core/config/env.dart`
- Daftar path endpoint terpusat: `lib/core/network/api_endpoints.dart`
- Dio, cookie sesi, timeout, 401, dan error Cloudflare:
  `lib/core/network/dio_client.dart`
- Parsing envelope dan pagination: `lib/core/network/api_response.dart`
- Login, session, logout: `lib/modules/auth/service.dart`
- Karyawan: `lib/modules/employee/service.dart`
- Cabang dan koordinat: `lib/modules/branch/service.dart`
- Kehadiran/check-in/check-out: `lib/modules/attendance/service.dart`
- Verifikasi wajah: `lib/modules/face/service.dart`
- Modul lain mengikuti pola `lib/modules/<modul>/service.dart`

Daftar endpoint dan payload yang telah dicocokkan dengan web tersedia di
[`docs/API_CONTRACT.md`](docs/API_CONTRACT.md). Password akun tidak ditulis ke
source code atau log aplikasi.

Untuk memakai mode mock tanpa jaringan:

```sh
flutter run --dart-define=USE_MOCK=true
```

Pada mode mock, akun yang dibuat melalui menu Tambah Karyawan dapat dipakai
untuk login dengan password manual yang diisi admin.

## Verifikasi

```sh
flutter analyze
flutter test
```

Arsitektur dan batas modul mengikuti [AGENTS.md](AGENTS.md), sedangkan kebutuhan
produk mengikuti [docs/PRD.md](docs/PRD.md).
Inventaris desain tersedia di
[docs/STITCH_INVENTORY.md](docs/STITCH_INVENTORY.md).
