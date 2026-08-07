import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/expandable_menu_fab.dart';

void main() {
  testWidgets('shows one main button until the menu is opened', (tester) async {
    await _pump(tester, onSelected: (_) {});

    expect(find.byKey(const Key('calendarGlobalMenuButton')), findsOneWidget);
    expect(find.byKey(const Key('globalAddAction')), findsNothing);

    await tester.tap(find.byKey(const Key('calendarGlobalMenuButton')));
    await tester.pumpAndSettle();

    expect(find.text('새 항목 추가'), findsOneWidget);
    expect(find.text('루틴 관리'), findsOneWidget);
    expect(find.text('카테고리 관리'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });

  testWidgets('selects one global action and closes the menu', (tester) async {
    DailyGlobalAction? selected;
    await _pump(tester, onSelected: (action) => selected = action);

    await tester.tap(find.byKey(const Key('calendarGlobalMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('globalAddAction')));
    await tester.pumpAndSettle();

    expect(selected, DailyGlobalAction.add);
    expect(find.byKey(const Key('globalAddAction')), findsNothing);
  });

  testWidgets('main button and outside tap both close an open menu',
      (tester) async {
    await _pump(tester, onSelected: (_) {});

    await tester.tap(find.byKey(const Key('calendarGlobalMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendarGlobalMenuButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('globalAddAction')), findsNothing);

    await tester.tap(find.byKey(const Key('calendarGlobalMenuButton')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(16, 16));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('globalAddAction')), findsNothing);
  });

  testWidgets('exposes menu state and action labels to assistive technology',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, onSelected: (_) {});

    expect(
      tester.getSemantics(
        find.byKey(const Key('calendarGlobalMenuButton')),
      ),
      matchesSemantics(
        label: '메뉴 열기',
        isButton: true,
        hasTapAction: true,
        children: const <Matcher>[],
      ),
    );

    await tester.tap(find.byKey(const Key('calendarGlobalMenuButton')));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byKey(const Key('globalSettingsAction'))),
      matchesSemantics(
        label: '설정',
        isButton: true,
        hasTapAction: true,
        children: const <Matcher>[],
      ),
    );
    semantics.dispose();
  });

  testWidgets('fits a mobile viewport with large text', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await _pump(tester, onSelected: (_) {});
    await tester.tap(find.byKey(const Key('calendarGlobalMenuButton')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('카테고리 관리'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required ValueChanged<DailyGlobalAction> onSelected,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: const SizedBox.expand(),
        floatingActionButton: ExpandableMenuFab(onSelected: onSelected),
      ),
    ),
  );
}
