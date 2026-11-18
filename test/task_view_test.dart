import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jahris_mobile/core/theme/task_theme.dart';
import 'package:jahris_mobile/modules/auth/model.dart';
import 'package:jahris_mobile/modules/auth/provider.dart';
import 'package:jahris_mobile/modules/notification/model.dart';
import 'package:jahris_mobile/modules/notification/provider.dart';
import 'package:jahris_mobile/modules/task/provider.dart';
import 'package:jahris_mobile/modules/task/service.dart';
import 'package:jahris_mobile/modules/task/view.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  for (final dark in [true, false]) {
    testWidgets('Detail tugas ${dark ? 'dark' : 'light'} mengikuti referensi', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [taskServiceProvider.overrideWithValue(MockTaskService())],
          child: MaterialApp(
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: const TaskDetailView(id: 'task-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Detail Tugas'), findsOneWidget);
      expect(find.text('Dikerjakan'), findsOneWidget);
      expect(find.text('Komentar (1)'), findsNothing);
      final progress = find.byKey(const ValueKey('task-subtask-progress'));
      expect(tester.widget<LinearProgressIndicator>(progress).value, 0.5);

      await tester.ensureVisible(find.byKey(const ValueKey('task-subtask-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-subtask-0')));
      await tester.pumpAndSettle();
      expect(find.text('1 dari 4'), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(progress).value, 0.25);
      await tester.ensureVisible(find.byKey(const ValueKey('task-subtask-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-subtask-2')));
      await tester.pumpAndSettle();
      expect(find.text('2 dari 4'), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(progress).value, 0.5);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Menu tugas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Komentar (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Struktur halaman sudah diperiksa.'), findsOneWidget);
      Navigator.of(tester.element(find.text('Komentar (1)'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Komentar (1)'), findsNothing);

      for (final width in [309.0, 495.0]) {
        tester.view.physicalSize = Size(width, 844);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('Tandai Selesai'));
      await tester.pumpAndSettle();
      expect(find.text('Tugas Selesai'), findsOneWidget);
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(TaskDetailView)),
      );
      expect(scope.read(taskProvider).value!.completedCount, 4);
      expect(tester.takeException(), isNull);
    });
  }

  for (final dark in [true, false]) {
    testWidgets(
      'Tanggal tugas ${dark ? 'dark' : 'light'}: reminder dan filter',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final service = MockTaskService();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(_AuthFixture.new),
              notificationProvider.overrideWith(_NotificationsFixture.new),
              taskServiceProvider.overrideWithValue(service),
            ],
            child: MaterialApp(
              theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              home: const TaskView(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final days = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith('task-day-'),
        );
        final reminders = find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'task-reminder-',
              ),
        );
        expect(days, findsNWidgets(7));
        expect(reminders, findsNWidgets(4));
        for (final day in days.evaluate()) {
          final box = day.widget as Container;
          expect(
            tester.getSize(find.byWidget(box)).height,
            TaskTheme.dayHeight,
          );
        }
        expect(find.text('3 dari 7 tugas selesai'), findsOneWidget);
        expect(find.text('43%'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Selesai (3)'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Tandai belum selesai'), findsNWidgets(3));
        expect(find.byTooltip('Tandai selesai'), findsNothing);
        expect(reminders, findsNWidgets(4));
        expect(find.text('3 dari 7 tugas selesai'), findsOneWidget);
        expect(find.text('Belum (4)'), findsOneWidget);

        await tester.tap(find.text('Belum (4)'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Tandai selesai').first);
        await tester.pumpAndSettle();
        expect(find.text('4 dari 7 tugas selesai'), findsOneWidget);
        expect(find.byTooltip('Tandai selesai'), findsNWidgets(3));
        expect(find.byTooltip('Tandai belum selesai'), findsNothing);
        expect(reminders, findsNWidgets(3));
        expect(tester.takeException(), isNull);

        tester.view.physicalSize = const Size(309, 772);
        await tester.pumpAndSettle();
        expect(days, findsNWidgets(7));
        expect(tester.takeException(), isNull);
        tester.view.physicalSize = const Size(495, 919);
        await tester.pumpAndSettle();
        expect(days, findsNWidgets(7));
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _AuthFixture extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _NotificationsFixture extends NotificationController {
  @override
  Future<NotificationState> build() async => const NotificationState(
    items: [],
    page: 1,
    total: 0,
    hasMore: false,
    deviceRegistered: false,
  );
}
