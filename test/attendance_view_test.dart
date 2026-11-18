import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:jahris_mobile/modules/attendance/model.dart';
import 'package:jahris_mobile/modules/attendance/provider.dart';
import 'package:jahris_mobile/modules/attendance/service.dart';
import 'package:jahris_mobile/modules/attendance/view.dart';
import 'package:jahris_mobile/modules/auth/model.dart';
import 'package:jahris_mobile/modules/auth/provider.dart';
import 'package:jahris_mobile/modules/notification/model.dart';
import 'package:jahris_mobile/modules/notification/provider.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  for (final dark in [true, false]) {
    testWidgets(
      'Kehadiran ${dark ? 'dark' : 'light'}: bulan, ringkasan, riwayat',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(_Auth.new),
              notificationProvider.overrideWith(_Notifications.new),
              attendanceServiceProvider.overrideWithValue(_AttendanceService()),
              attendanceProvider.overrideWith(_Attendance.new),
            ],
            child: MaterialApp(
              theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              home: const AttendanceView(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Sedang Bekerja'), findsOneWidget);
        expect(find.text('08:05'), findsOneWidget);
        expect(find.text('4j 07m'), findsOneWidget);
        expect(find.text('67%'), findsOneWidget);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byKey(const ValueKey('attendance-rate')),
              )
              .value,
          closeTo(2 / 3, 0.001),
        );
        expect(find.text('Izin Sakit'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Lihat semua'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lihat semua'));
        await tester.pumpAndSettle();
        expect(find.text('Riwayat Kehadiran'), findsOneWidget);
        Navigator.of(tester.element(find.text('Riwayat Kehadiran'))).pop();
        await tester.pumpAndSettle();

        final now = DateTime.now();
        final previous = DateTime(now.year, now.month - 1);
        await tester.tap(find.byTooltip('Pilih bulan kehadiran'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(DateFormat('MMMM yyyy', 'id_ID').format(previous)),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Ringkasan ${DateFormat('MMMM', 'id_ID').format(previous)}',
          ),
          findsOneWidget,
        );
        expect(find.text('Kantor Lama', skipOffstage: false), findsNothing);
        expect(find.text('9j 00m · Kantor Lama'), findsOneWidget);
        expect(find.text('Izin Sakit'), findsNothing);
        expect(find.text('100%'), findsOneWidget);

        for (final width in [250.0, 495.0]) {
          tester.view.physicalSize = Size(width, 844);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        final emptyMonth = DateTime(now.year, now.month - 2);
        await tester.tap(find.byTooltip('Pilih bulan kehadiran'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(DateFormat('MMMM yyyy', 'id_ID').format(emptyMonth)),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Belum ada riwayat kehadiran pada bulan ini.'),
          findsOneWidget,
        );
        expect(find.text('0%'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Auth extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _Notifications extends NotificationController {
  @override
  Future<NotificationState> build() async => const NotificationState(
    items: [],
    page: 1,
    total: 0,
    hasMore: false,
    deviceRegistered: false,
  );
}

class _Attendance extends AttendanceController {
  @override
  Future<AttendanceState> build() async {
    final now = DateTime.now();
    final page = await ref.watch(attendanceServiceProvider).list(limit: 50);
    return AttendanceState(
      records: page.items,
      config: const AttendanceConfig(
        startHour: '08:15',
        endHour: '17:15',
        toleranceMinutes: 15,
        branchName: 'Kantor Pusat',
        latitude: 0,
        longitude: 0,
        radiusMeters: 100,
      ),
      now: DateTime(now.year, now.month, now.day, 12, 12),
      checkIn: DateTime(now.year, now.month, now.day, 8, 5),
      locationStatus: LocationAccessStatus.belum,
      page: 1,
      total: page.total,
      hasMore: false,
    );
  }
}

class _AttendanceService extends MockAttendanceService {
  @override
  Future<AttendancePage> list({
    int page = 1,
    int limit = 10,
    DateTime? from,
    DateTime? to,
    String? userId,
  }) async {
    final now = DateTime.now();
    final records =
        [
              AttendanceRecord(
                id: '1',
                employeeName: 'Ahmad',
                date: DateTime(now.year, now.month, 3),
                status: 'Tepat Waktu',
                checkIn: DateTime(now.year, now.month, 3, 7, 58),
                checkOut: DateTime(now.year, now.month, 3, 17, 21),
                branchName: 'Kantor Pusat',
              ),
              AttendanceRecord(
                id: '2',
                employeeName: 'Ahmad',
                date: DateTime(now.year, now.month, 2),
                status: 'Terlambat',
                checkIn: DateTime(now.year, now.month, 2, 8, 24),
                checkOut: DateTime(now.year, now.month, 2, 17, 30),
                branchName: 'Kantor Pusat',
              ),
              AttendanceRecord(
                id: '3',
                employeeName: 'Ahmad',
                date: DateTime(now.year, now.month, 1),
                status: 'Izin Sakit',
                branchName: 'Disetujui oleh Rina P.',
              ),
              AttendanceRecord(
                id: 'old',
                employeeName: 'Ahmad',
                date: DateTime(now.year, now.month - 1, 1),
                status: 'Tepat Waktu',
                checkIn: DateTime(now.year, now.month - 1, 1, 8),
                checkOut: DateTime(now.year, now.month - 1, 1, 17),
                branchName: 'Kantor Lama',
              ),
            ]
            .where(
              (item) =>
                  (from == null || !item.date.isBefore(from)) &&
                  (to == null ||
                      item.date.isBefore(to.add(const Duration(days: 1)))),
            )
            .toList();
    return AttendancePage(
      items: records,
      page: 1,
      total: records.length,
      hasMore: false,
    );
  }
}
