import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jahris_mobile/modules/branch/model.dart';
import 'package:jahris_mobile/modules/branch/provider.dart';
import 'package:jahris_mobile/modules/branch/view.dart';
import 'package:jahris_mobile/modules/auth/model.dart';
import 'package:jahris_mobile/modules/auth/provider.dart';
import 'package:jahris_mobile/modules/notification/model.dart';
import 'package:jahris_mobile/modules/notification/provider.dart';
import 'package:jahris_mobile/core/theme/app_colors.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('Jadwal shift tampil pada viewport 390x844', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_FixtureAuthController.new),
          notificationProvider.overrideWith(_FixtureNotificationController.new),
          shiftScheduleProvider.overrideWith(
            _FixtureShiftScheduleController.new,
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true).copyWith(
            scaffoldBackgroundColor: AppColors.darkBackground,
            dividerColor: Colors.white.withValues(alpha: 0.08),
          ),
          home: const ShiftScheduleView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jadwal Shift'), findsOneWidget);
    expect(find.text('Minggu ini'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(ShiftScheduleView),
      matchesGoldenFile('goldens/shift_schedule_390x844.png'),
    );
    await tester.scrollUntilVisible(
      find.text('Ajukan Tukar Shift'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ajukan Tukar Shift'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FixtureAuthController extends AuthController {
  @override
  AuthState build() => AuthState.authenticated(
    const AuthUser(
      id: 'employee-1',
      name: 'Ahmad',
      email: 'ahmad@jahris.id',
      role: 'Karyawan',
      tenantName: 'PT Amino Suka Jaya',
      branchId: 'branch-1',
      branchName: 'Kantor Pusat',
    ),
  );
}

class _FixtureNotificationController extends NotificationController {
  @override
  Future<NotificationState> build() async => const NotificationState(
    items: [],
    page: 1,
    total: 0,
    hasMore: false,
    deviceRegistered: false,
  );
}

class _FixtureShiftScheduleController extends ShiftScheduleController {
  @override
  Future<ShiftScheduleState> build() async {
    final selected = DateTime(2026, 11, 4);
    return ShiftScheduleState(
      branch: const Branch(
        id: 'branch-1',
        name: 'Kantor Pusat',
        code: 'PUSAT',
        address: 'Jakarta Pusat',
        latitude: -6.17,
        longitude: 106.82,
        radiusMeters: 100,
        scheduleType: 'SHIFT',
        customWorkingHoursEnabled: true,
        workingSchedules: [
          WorkingSchedule(
            id: 'mon',
            branchId: 'branch-1',
            dayOfWeek: 'MONDAY',
            isWorkDay: true,
            startTime: '08:15',
            endTime: '17:15',
          ),
          WorkingSchedule(
            id: 'tue',
            branchId: 'branch-1',
            dayOfWeek: 'TUESDAY',
            isWorkDay: true,
            startTime: '13:00',
            endTime: '22:00',
          ),
          WorkingSchedule(
            id: 'wed',
            branchId: 'branch-1',
            dayOfWeek: 'WEDNESDAY',
            isWorkDay: true,
            startTime: '08:15',
            endTime: '17:15',
          ),
          WorkingSchedule(
            id: 'thu',
            branchId: 'branch-1',
            dayOfWeek: 'THURSDAY',
            isWorkDay: true,
            startTime: '08:15',
            endTime: '17:15',
          ),
          WorkingSchedule(
            id: 'fri',
            branchId: 'branch-1',
            dayOfWeek: 'FRIDAY',
            isWorkDay: true,
            startTime: '08:15',
            endTime: '17:15',
          ),
          WorkingSchedule(
            id: 'sat',
            branchId: 'branch-1',
            dayOfWeek: 'SATURDAY',
            isWorkDay: false,
          ),
          WorkingSchedule(
            id: 'sun',
            branchId: 'branch-1',
            dayOfWeek: 'SUNDAY',
            isWorkDay: false,
          ),
        ],
      ),
      weekStart: DateTime(2026, 11, 2),
      selectedDate: selected,
    );
  }
}
