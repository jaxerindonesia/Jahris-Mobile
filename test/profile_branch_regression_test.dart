import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jahris_mobile/modules/auth/model.dart';
import 'package:jahris_mobile/modules/attendance/service.dart';
import 'package:jahris_mobile/modules/branch/model.dart';
import 'package:jahris_mobile/modules/branch/service.dart';
import 'package:jahris_mobile/modules/leave/service.dart';
import 'package:jahris_mobile/modules/profile/service.dart';
import 'package:jahris_mobile/modules/reimburse/service.dart';

void main() {
  test('profil API membaca pengguna aktif dari envelope data.user', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev.jahris.id/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/session') {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: const {
                  'data': {
                    'user': {
                      'id': 'surya-id',
                      'name': 'Surya',
                      'email': 'surya@jahris.id',
                      'phone': null,
                      'role': 'Karyawan',
                      'tenantName': 'JAHRIS',
                    },
                  },
                },
              ),
            );
            return;
          }
          if (options.path == '/users/surya-id') {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: const {
                  'data': {
                    'id': 'surya-id',
                    'name': 'Surya dari Detail',
                    'phone': '08123456789',
                    'nik': 'EMP-001',
                    'position': 'Developer',
                    'gender': 'Laki-laki',
                    'birthPlace': 'Jakarta',
                    'salary': 7500000,
                    'department': {'id': 'dept-it', 'name': 'IT'},
                    'branch': {'id': 'branch-jakpus', 'name': 'Jakpus'},
                  },
                },
              ),
            );
            return;
          }
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<void>(
                requestOptions: options,
                statusCode: 404,
              ),
            ),
          );
        },
      ),
    );

    final profile = await ApiProfileService(dio).getProfile();

    expect(profile.id, 'surya-id');
    expect(profile.name, 'Surya');
    expect(profile.email, 'surya@jahris.id');
    expect(profile.phone, '08123456789');
    expect(profile.position, 'Developer');
    expect(profile.nik, 'EMP-001');
    expect(profile.department, 'IT');
    expect(profile.branch, 'Jakpus');
    expect(profile.gender, 'Laki-laki');
    expect(profile.birthPlace, 'Jakarta');
    expect(profile.salary, 7500000);
  });

  test('profil API menolak detail milik akun lain', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev.jahris.id/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final data = options.path == '/auth/session'
              ? const <String, dynamic>{
                  'data': {
                    'user': {
                      'id': 'surya-id',
                      'name': 'Surya',
                      'email': 'surya@jahris.id',
                    },
                  },
                }
              : const <String, dynamic>{
                  'data': {
                    'id': 'akun-lain',
                    'name': 'Akun Lain',
                    'email': 'lain@jahris.id',
                  },
                };
          handler.resolve(
            Response<Map<String, dynamic>>(requestOptions: options, data: data),
          );
        },
      ),
    );

    final profile = await ApiProfileService(dio).getProfile();

    expect(profile.id, 'surya-id');
    expect(profile.name, 'Surya');
    expect(profile.email, 'surya@jahris.id');
  });

  test('profil API memakai daftar users saat endpoint detail gagal', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev.jahris.id/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/session') {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: const {
                  'data': {
                    'user': {
                      'id': 'fams-id',
                      'name': 'Fams',
                      'email': 'fama11@gmail.com',
                      'role': 'Karyawan',
                    },
                  },
                },
              ),
            );
            return;
          }
          if (options.path == '/users/fams-id') {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<void>(
                  requestOptions: options,
                  statusCode: 404,
                ),
              ),
            );
            return;
          }
          if (options.path == '/users') {
            expect(options.queryParameters['search'], 'fama11@gmail.com');
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: const {
                  'data': [
                    {
                      'id': 'fams-id',
                      'name': 'Fams',
                      'email': 'fama11@gmail.com',
                      'phone': '085254554',
                      'nik': '3215426535465',
                      'position': 'IT',
                      'gender': 'Laki-laki',
                      'birthPlace': 'Bengkulu',
                      'department': {'name': 'IT'},
                      'branch': {'name': 'Jakpus'},
                      'salary': 1500000,
                    },
                  ],
                  'total': 1,
                },
              ),
            );
            return;
          }
          handler.reject(DioException(requestOptions: options));
        },
      ),
    );

    final profile = await ApiProfileService(dio).getProfile();

    expect(profile.name, 'Fams');
    expect(profile.email, 'fama11@gmail.com');
    expect(profile.phone, '085254554');
    expect(profile.nik, '3215426535465');
    expect(profile.position, 'IT');
    expect(profile.department, 'IT');
    expect(profile.branch, 'Jakpus');
    expect(profile.gender, 'Laki-laki');
    expect(profile.birthPlace, 'Bengkulu');
    expect(profile.salary, 1500000);
  });

  test('profil mock mengikuti pengguna yang sedang login', () async {
    const user = AuthUser(
      id: 'employee-profile-regression',
      name: 'Karyawan Uji',
      email: 'karyawan.uji@jahris.id',
      role: 'Karyawan',
      tenantName: 'Jaxer Grup Indonesia',
    );

    final profile = await MockProfileService(user).getProfile();

    expect(profile.id, user.id);
    expect(profile.name, user.name);
    expect(profile.email, user.email);
    expect(profile.role, user.role);
  });

  test('pengguna auth membaca koordinat cabang dari detail web', () {
    final user = AuthUser.fromJson(const {
      'id': 'surya-id',
      'name': 'Surya',
      'email': 'surya@jahris.id',
      'branch': {
        'id': 'branch-batam',
        'name': 'Batam',
        'latitude': '1.1301',
        'longitude': 104.0529,
        'attendanceRadiusMeters': 125,
      },
    });

    expect(user.branchName, 'Batam');
    expect(user.branchId, 'branch-batam');
    expect(user.branchLatitude, 1.1301);
    expect(user.branchLongitude, 104.0529);
    expect(user.attendanceRadiusMeters, 125);
  });

  test('pengguna auth membaca cabang dari relasi employee', () {
    final user = AuthUser.fromJson(const {
      'id': 'surya-id',
      'name': 'Surya',
      'employee': {
        'branchId': 'branch-jakpus',
        'branch': {
          'id': 'branch-jakpus',
          'name': 'Jakpus',
          'latitude': '-6.1754',
          'longitude': '106.8272',
          'attendanceRadiusMeters': '100',
        },
      },
    });

    expect(user.branchId, 'branch-jakpus');
    expect(user.branchName, 'Jakpus');
    expect(user.branchLatitude, -6.1754);
    expect(user.branchLongitude, 106.8272);
    expect(user.attendanceRadiusMeters, 100);
  });

  test('API cabang mengirim tenant dan membaca koordinat lokasi', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev.jahris.id/api'));
    late Map<String, dynamic> query;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          query = Map<String, dynamic>.from(options.queryParameters);
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: const {
                'data': {
                  'branches': [
                    {
                      'id': 'branch-jakpus',
                      'name': 'Jakpus',
                      'code': 'JAKPUS',
                      'location': {
                        'latitude': '-6.1754',
                        'longitude': 106.8272,
                        'radius': 100,
                      },
                      'isActive': true,
                    },
                  ],
                },
              },
            ),
          );
        },
      ),
    );

    final page = await ApiBranchService(dio)
        .list(limit: 100, tenantId: 'tenant-jaxer');

    expect(query['tenantId'], 'tenant-jaxer');
    expect(page.items.single.name, 'Jakpus');
    expect(page.items.single.latitude, -6.1754);
    expect(page.items.single.longitude, 106.8272);
    expect(page.items.single.radiusMeters, 100);
  });

  test('detail API cabang membaca envelope data.branch', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev.jahris.id/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: const {
                'data': {
                  'branch': {
                    'id': 'branch-jakpus',
                    'name': 'Jakpus',
                    'code': 'JAKPUS',
                    'latitude': -6.1754,
                    'longitude': 106.8272,
                    'attendanceRadiusMeters': 100,
                  },
                },
              },
            ),
          );
        },
      ),
    );

    final branch = await ApiBranchService(dio).detail('branch-jakpus');

    expect(branch.name, 'Jakpus');
    expect(branch.latitude, -6.1754);
    expect(branch.longitude, 106.8272);
  });

  test('cabang mock baru tersedia pada instance service berikutnya', () async {
    final firstService = MockBranchService();
    const code = 'REGRESSION-BRANCH';
    final created = await firstService.save(
      const Branch(
        id: '',
        name: 'Cabang Regresi',
        code: code,
        address: 'Alamat pengujian',
        latitude: -6.2,
        longitude: 106.8,
        radiusMeters: 100,
      ),
    );

    final page = await MockBranchService().list(query: code);

    expect(page.items.map((item) => item.id), contains(created.id));
    await firstService.delete(created.id);
  });

  test(
    'transaksi mock memakai nama pengguna aktif, bukan nama admin',
    () async {
      const employeeName = 'Karyawan Uji';
      final attendance = await MockAttendanceService(userName: employeeName)
          .check(
            isIn: true,
            latitude: 1.1301,
            longitude: 104.0529,
            accuracy: 15,
            faceVerificationToken: 'mock-token',
            employeeId: 'mock-employee',
            faceCaptureBase64: 'data:image/jpeg;base64,mock-frame',
          );
      final leave = await MockLeaveService(userName: employeeName).create(
        type: 'Cuti Tahunan',
        startDate: DateTime(2026, 10, 22),
        endDate: DateTime(2026, 10, 22),
        reason: 'Pengujian regresi',
      );
      final reimbursement = await MockReimburseService(userName: employeeName)
          .create(
            category: 'Transportasi',
            amount: 100000,
            date: DateTime(2026, 10, 21),
            description: 'Pengujian regresi',
            receiptPath: 'bukti.jpg',
          );

      expect(attendance.employeeName, employeeName);
      expect(leave.employeeName, employeeName);
      expect(reimbursement.employeeName, employeeName);
    },
  );
}
