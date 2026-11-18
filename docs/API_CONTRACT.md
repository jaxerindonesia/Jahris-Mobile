# Kontrak API JAHRIS Mobile

Basis URL produksi: `https://dev.jahris.id/api`

Path endpoint pada kode Flutter dipusatkan di
`lib/core/network/api_endpoints.dart`. Implementasi request dan parsing tetap
berada di `service.dart` masing-masing modul agar batas arsitektur tidak berubah.

Dokumen ini mencatat endpoint yang telah diverifikasi terhadap aplikasi web pada 21 Oktober 2026. Respons daftar umumnya berbentuk `{ message, data, total, page, limit }` dan aplikasi melakukan parsing nullable/toleran.

## Autentikasi

- `POST /auth/login` — JSON: `email`, `password`, `remember_me`
- `GET /auth/session` — sesi cookie dan profil pengguna aktif
- `POST /auth/logout`
- `POST /auth/change_password` — JSON: `userId`, `currentPassword`, `newPassword`

Cookie sesi disimpan terenkripsi melalui `flutter_secure_storage`. Fallback NextAuth CSRF/credentials tetap tersedia hanya bila endpoint login utama menjawab 404/405.

## Master data

- `GET /users?page=&limit=&search=&status=&departmentId=&branchId=&tenantId=`
- `GET /users/:id`
- `POST /users`, `PUT /users/:id`, `DELETE /users/:id`
- `POST /users/import` — JSON `{ rows: [...] }`; spreadsheet diparsing di sisi klien web
- `GET /branches?page=&limit=&search=`
- `POST /branches`, `PUT /branches/:id`, `DELETE /branches/:id`
- `GET /roles`
- `GET /departments`

Koordinat dan radius absensi berasal dari cabang karyawan: `latitude`, `longitude`, dan `attendanceRadiusMeters`. `attendance-config` tidak memuat lokasi kantor.

## Kehadiran dan wajah

- `GET /attendances` — daftar admin
- `GET /attendances/user/:userId` — daftar karyawan
- `POST /attendances/check-in`
- `POST /attendances/check-out`
- `GET /attendance-config`, `PUT /attendance-config`
- `GET /face-recognition/verify` — pemanasan layanan
- `POST /face-recognition/verify` — JSON `frames` dan `mode`

Payload check-in/out menggunakan `userId`, objek `checkInLocation`/`checkOutLocation`, `faceCaptureBase64`, dan `faceVerificationToken`. Sebelum check-in/out, mobile mengirim tepat empat frame ke `POST /face-recognition/verify` dengan mode `check-in` atau `check-out`, lalu memakai token hasil verifikasi yang berlaku dua menit.

Belum tersedia endpoint server untuk enrollment wajah dan persetujuan biometrik. Web saat ini menulis `faceDescriptor` melalui `PUT /users/:id`; pola itu sengaja tidak ditiru karena persyaratan mobile melarang pembuatan/perbandingan descriptor di perangkat. Backend perlu menyediakan endpoint enrollment multipart dan consent yang memproses biometrik sepenuhnya di server.

## Pengajuan dan operasional

- `GET /submissions`, CRUD `/submissions/:id`, `GET /submission-types`
- `GET /leave-configs`
- `GET /reimbursements`, CRUD `/reimbursements/:id`
- `GET /overtimes`, `POST /overtimes/request`, CRUD `/overtimes/:id`
- `POST /overtimes/check-in`, `POST /overtimes/check-out`
- `GET /overtime-config`, `PUT /overtime-config`
- `GET /pettycash`, CRUD `/pettycash/:id`, `POST /pettycash/:id/usage`
- `GET /performances`, CRUD `/performances/:id`, `GET /performances/preview`

## Dashboard, tugas, dan payroll

- `GET /dashboard`
- `GET /task-managements/departments`
- `GET /task-managements/lists?departmentId=`
- CRUD `/task-managements/lists`, `/task-managements/categories`, `/task-managements/tasks/:id`
- `GET /payrolls`, `GET /payrolls/:id`, `GET /payrolls/summary`, `GET /payrolls/calculation-summary`
- `GET /payroll-component-config`

Export Excel/PDF pada web dibuat di browser dari data daftar; tidak ditemukan endpoint export server. Mobile juga membentuk file dari data API, bukan memanggil endpoint fiktif.

## Celah backend

- Enrollment wajah server-side dan penyimpanan consent biometrik belum tersedia.
- Field `mustChangePassword` tidak ditemukan pada respons sesi web.
- Endpoint notifikasi khusus belum ditemukan.
- Import karyawan harus mengirim `rows` hasil parsing, bukan file multipart.
