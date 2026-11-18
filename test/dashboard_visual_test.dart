import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jahris_mobile/core/theme/app_colors.dart';
import 'package:jahris_mobile/modules/auth/model.dart';
import 'package:jahris_mobile/modules/auth/provider.dart';
import 'package:jahris_mobile/modules/dashboard/model.dart';
import 'package:jahris_mobile/modules/dashboard/provider.dart';
import 'package:jahris_mobile/modules/dashboard/view.dart';
import 'package:jahris_mobile/modules/notification/model.dart';
import 'package:jahris_mobile/modules/notification/provider.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('Dashboard dark mengikuti warna referensi Stitch pada 390x844', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_DashboardAuthController.new),
          notificationProvider.overrideWith(
            _DashboardNotificationController.new,
          ),
          dashboardProvider.overrideWith(_DashboardFixtureController.new),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true).copyWith(
            scaffoldBackgroundColor: AppColors.darkBackground,
            dividerColor: Colors.white.withValues(alpha: 0.08),
          ),
          home: const DashboardView(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Halo, Ridwan 👋'), findsOneWidget);
    expect(find.text('Libur berikutnya: Hari Natal'), findsOneWidget);
    expect(find.text('Pengajuan Saya'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(DashboardView),
      matchesGoldenFile('goldens/dashboard_dark_390x844.png'),
    );

    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();
    expect(find.text('Semua Layanan'), findsOneWidget);
    expect(find.text('Riwayat Absen'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashboard_services_sheet_dark_390x844.png'),
    );
  });
}

class _DashboardAuthController extends AuthController {
  @override
  AuthState build() => AuthState.authenticated(
    const AuthUser(
      id: 'employee-1',
      name: 'Ridwan Saputra',
      email: 'ridwan@jahris.id',
      role: 'Karyawan',
      tenantName: 'PT Amino Suka Jaya',
      branchId: 'branch-1',
      branchName: 'Kantor Pusat',
    ),
  );
}

class _DashboardNotificationController extends NotificationController {
  @override
  Future<NotificationState> build() async => const NotificationState(
    items: [],
    page: 1,
    total: 0,
    hasMore: false,
    deviceRegistered: false,
  );
}

class _DashboardFixtureController extends DashboardController {
  @override
  Future<DashboardSummary> build() async => DashboardSummary(
    stats: const [],
    recentSubmissions: [
      RecentSubmission(
        id: 'submission-1',
        employeeName: 'Ridwan Saputra',
        type: 'Cuti Tahunan',
        status: 'Menunggu',
        submittedAt: DateTime(2026, 11, 3),
        detail: '3–5 Nov 2026',
      ),
      RecentSubmission(
        id: 'submission-2',
        employeeName: 'Ridwan Saputra',
        type: 'Reimburse Transport',
        status: 'Disetujui',
        submittedAt: DateTime(2026, 11, 2),
        detail: 'Rp 150.000',
      ),
    ],
  );
}
