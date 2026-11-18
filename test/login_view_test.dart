import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jahris_mobile/core/theme/login_theme.dart';
import 'package:jahris_mobile/modules/auth/model.dart';
import 'package:jahris_mobile/modules/auth/provider.dart';
import 'package:jahris_mobile/modules/auth/view.dart';

void main() {
  for (final dark in [true, false]) {
    testWidgets('Login ${dark ? 'dark' : 'light'}: drag, input, keyboard', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(_LoginAuth.new)],
          child: MaterialApp(
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: const LoginView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final panel = find.byKey(const ValueKey('login-sheet'));
      final originalTop = tester.getTopLeft(panel).dy;
      expect(find.text('Selamat datang di Jahris'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final decoration =
          tester.widget<Container>(panel).decoration! as BoxDecoration;
      expect(
        (decoration.gradient! as LinearGradient).colors,
        dark ? LoginTheme.darkPanel : LoginTheme.lightPanel,
      );
      await expectLater(
        find.byType(LoginView),
        matchesGoldenFile(
          'goldens/login_${dark ? 'dark' : 'light'}_390x844.png',
        ),
      );

      final toggle = find.byKey(const ValueKey('login-sheet-toggle'));
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(panel).dy, lessThan(originalTop - 150));
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(panel).dy, closeTo(originalTop, 2));

      await tester.dragFrom(
        Offset(195, originalTop + 18),
        const Offset(0, -260),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(panel).dy, lessThan(originalTop - 150));
      await tester.dragFrom(
        tester.getTopLeft(panel) + const Offset(195, 18),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(panel).dy, closeTo(originalTop, 2));

      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(panel).dy, lessThan(originalTop - 150));
      await tester.enterText(find.byType(TextField).first, 'preview@jahris.id');
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Password123');
      await tester.ensureVisible(find.text('Masuk ke Jahris'));
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.text('Masuk ke Jahris')).dy,
        lessThan(524),
      );
      expect(tester.takeException(), isNull);
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(LoginView)),
      );
      expect(scope.read(loginFormProvider).email, 'preview@jahris.id');
      expect(scope.read(loginFormProvider).password, 'Password123');

      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(panel).dy, closeTo(originalTop, 2));
      expect(tester.testTextInput.isVisible, isFalse);
      expect(scope.read(loginFormProvider).email, 'preview@jahris.id');
      expect(scope.read(loginFormProvider).password, 'Password123');
    });
  }
}

class _LoginAuth extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();
}
