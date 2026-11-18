import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jahris_mobile/modules/reimburse/provider.dart';
import 'package:jahris_mobile/modules/reimburse/service.dart';
import 'package:jahris_mobile/modules/reimburse/view.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('kategori reimburse dapat digeser horizontal dengan mouse', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reimburseServiceProvider.overrideWithValue(MockReimburseService()),
        ],
        child: const MaterialApp(home: ReimburseView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajukan Reimburse').last);
    await tester.pumpAndSettle();

    final categoryList = find.byKey(const ValueKey('reimburse-category-list'));
    expect(categoryList, findsOneWidget);

    final scrollable = find.descendant(
      of: categoryList,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    final beforeDrag = position.pixels;
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    final dragStart = tester.getCenter(categoryList);
    await gesture.addPointer(location: dragStart);
    await gesture.down(dragStart);
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-190, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(position.pixels, greaterThan(beforeDrag));
  });
}
