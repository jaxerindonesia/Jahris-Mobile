import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jahris_mobile/modules/attendance/model.dart';
import 'package:jahris_mobile/modules/attendance/service.dart';

void main() {
  test('timestamp UTC kehadiran dikonversi ke waktu lokal perangkat', () {
    const rawCheckIn = '2026-10-22T08:00:00.000Z';
    final record = AttendanceRecord.fromJson(const {
      'id': 'attendance-1',
      'attendanceDay': '2026-10-22T00:00:00.000Z',
      'checkIn': rawCheckIn,
      'status': 'present',
    });

    expect(record.checkIn, DateTime.parse(rawCheckIn).toLocal());
    expect(record.checkIn?.isUtc, isFalse);
  });

  test('check-out memakai endpoint dan membaca data.attendance', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev.jahris.id/api'));
    late RequestOptions captured;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: const {
                'data': {
                  'attendance': {
                    'id': 'attendance-1',
                    'attendanceDay': '2026-10-22T00:00:00.000Z',
                    'checkIn': '2026-10-22T08:00:00.000Z',
                    'checkOut': '2026-10-22T09:15:00.000Z',
                    'status': 'present',
                  },
                },
              },
            ),
          );
        },
      ),
    );

    final record = await ApiAttendanceService(dio).check(
      isIn: false,
      latitude: -6.1754,
      longitude: 106.8272,
      accuracy: 15,
      faceVerificationToken: 'verification-token',
      employeeId: 'surya-id',
      faceCaptureBase64: 'data:image/jpeg;base64,frame-base64',
    );

    expect(captured.path, '/attendances/check-out');
    expect(captured.data, containsPair('userId', 'surya-id'));
    expect(
      captured.data,
      containsPair('checkOutLocation', containsPair('latitude', -6.1754)),
    );
    expect(
      captured.data,
      containsPair('checkOutLocation', containsPair('accuracy', 15.0)),
    );
    expect(
      captured.data,
      containsPair('faceCaptureBase64', 'data:image/jpeg;base64,frame-base64'),
    );
    expect(
      captured.data,
      containsPair('faceVerificationToken', 'verification-token'),
    );
    expect(record.id, 'attendance-1');
    expect(
      record.checkOut,
      DateTime.parse('2026-10-22T09:15:00.000Z').toLocal(),
    );
  });
}
