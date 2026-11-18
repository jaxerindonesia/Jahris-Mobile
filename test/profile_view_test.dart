import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jahris_mobile/core/theme/theme_provider.dart';
import 'package:jahris_mobile/modules/auth/model.dart';
import 'package:jahris_mobile/modules/auth/provider.dart';
import 'package:jahris_mobile/modules/notification/model.dart';
import 'package:jahris_mobile/modules/notification/provider.dart';
import 'package:jahris_mobile/modules/profile/model.dart';
import 'package:jahris_mobile/modules/profile/provider.dart';
import 'package:jahris_mobile/modules/profile/view.dart';

void main() {
  for (final dark in [true, false]) {
    testWidgets(
      'Profil ${dark ? 'dark' : 'light'}: layout, edit, tema, keluar',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(_AuthFixture.new),
              notificationProvider.overrideWith(_NotificationFixture.new),
              profileProvider.overrideWith(_ProfileFixture.new),
              profileStatisticsProvider.overrideWithValue(
                const ProfileStatistics(
                  remainingLeave: '9 hari',
                  workDays: '18',
                  overtime: '6j 30m',
                ),
              ),
              themeModeProvider.overrideWith(
                dark ? ThemeModeNotifier.new : _LightTheme.new,
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) => MaterialApp(
                theme: ThemeData.light(useMaterial3: true),
                darkTheme: ThemeData.dark(useMaterial3: true),
                themeMode: ref.watch(themeModeProvider),
                home: const ProfileView(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('AY'), findsOneWidget);
        expect(find.text('Ahmad Yusuf'), findsOneWidget);
        expect(find.text('9 hari'), findsOneWidget);
        expect(find.text('18'), findsOneWidget);
        expect(find.text('6j 30m'), findsOneWidget);
        expect(
          tester.getCenter(find.text('Dokumen Saya')).dy,
          closeTo(tester.getCenter(find.text('3 file')).dy, 2),
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Ubah profil dari avatar'));
        await tester.pumpAndSettle();
        expect(find.text('Ubah Profil'), findsOneWidget);
        expect(
          find.widgetWithText(TextFormField, 'Ahmad Yusuf'),
          findsOneWidget,
        );
        Navigator.of(tester.element(find.text('Ubah Profil'))).pop();
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byType(Switch).last);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch).last);
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.text('Tema Gelap'))).brightness,
          dark ? Brightness.light : Brightness.dark,
        );
        expect(tester.takeException(), isNull);

        for (final width in [247.0, 390.0, 495.0]) {
          tester.view.physicalSize = Size(width, 844);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.scrollUntilVisible(find.text('Keluar'), 200);
        await tester.pumpAndSettle();
        expect(find.text('Bantuan'), findsOneWidget);
        expect(find.text('Tentang Aplikasi'), findsOneWidget);
        await tester.tap(find.text('Keluar'));
        await tester.pumpAndSettle();
        expect(find.text('Keluar dari Jahris?'), findsOneWidget);
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
        expect(find.text('Keluar dari Jahris?'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _LightTheme extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.light;
}

class _AuthFixture extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _ProfileFixture extends ProfileController {
  @override
  Future<ProfileState> build() async => const ProfileState(
    profile: UserProfile(
      id: 'profile-1',
      name: 'Ahmad Yusuf',
      email: 'ahmad@jahris.id',
      phone: '08123456789',
      role: 'Karyawan',
      position: 'UI/UX Designer',
      department: 'Divisi Produk',
      nik: '2024-0187',
      tenant: TenantOption(id: 'jgi', name: 'Jahris', code: 'JGI'),
      tenants: [],
    ),
  );
}

class _NotificationFixture extends NotificationController {
  @override
  Future<NotificationState> build() async => const NotificationState(
    items: [],
    page: 1,
    total: 0,
    hasMore: false,
    deviceRegistered: false,
  );
}
