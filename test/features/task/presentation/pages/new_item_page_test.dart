import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart' as result;
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/task/presentation/pages/new_item_page.dart';
import 'package:nae_mo/features/task/presentation/widgets/new_item_category_input.dart';

void main() {
  test('category state sorts categories and resolves the selected id', () {
    final state = NewItemCategoryState.loaded(const [
      Category(id: 'b', name: 'B', color: 0xFF76C4DE, sortOrder: 2),
      Category(id: 'c', name: 'C', color: 0xFFFFD64F, sortOrder: 1),
      Category(id: 'a', name: 'A', color: 0xFFA4E85B, sortOrder: 2),
    ]);

    expect(state.categories.map((category) => category.id), ['c', 'a', 'b']);
    expect(state.categoryFor('a')?.name, 'A');
    expect(state.categoryFor('missing'), isNull);
    expect(state.categoryFor(null), isNull);
  });

  testWidgets('starts as one event form with a fixed Daily date',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    expect(find.text('새 항목 추가'), findsOneWidget);
    expect(find.text('2026년 8월 3일'), findsOneWidget);
    expect(find.byKey(const Key('newItemTitleField')), findsOneWidget);
    expect(find.byKey(const Key('newItemTimedMode')), findsOneWidget);
    expect(find.byKey(const Key('newItemAllDayMode')), findsOneWidget);
    expect(find.byKey(const Key('newItemStartTimeButton')), findsOneWidget);
    expect(find.byKey(const Key('newItemEndTimeButton')), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('newItemSaveButton')))
          .onPressed,
      isNull,
    );
    expect(
      tester.getSemantics(find.byKey(const Key('newItemEventKind'))),
      matchesSemantics(
        label: '일정',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
        children: const <Matcher>[],
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('newItemTodoKind'))),
      matchesSemantics(
        label: 'Todo',
        isButton: true,
        isSelected: false,
        hasTapAction: true,
        children: const <Matcher>[],
      ),
    );
    semantics.dispose();
  });

  testWidgets('loads categories and keeps the selection across item kinds',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      categoryLoader: () async => result.success(const [
        _personalCategory,
        _workCategory,
        _healthCategory,
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('카테고리 없음'), findsOneWidget);
    await tester.tap(find.byKey(const Key('newItemCategoryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('newItemCategorySheet')), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.byKey(const Key('newItemCategory-work')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const Key('newItemCategory-personal')),
            )
            .dy,
      ),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const Key('newItemCategory-personal')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const Key('newItemCategory-health')),
            )
            .dy,
      ),
    );

    await tester.tap(find.byKey(const Key('newItemCategory-work')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newItemTodoKind')));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byKey(const Key('newItemCategoryButton'))).label,
      '카테고리, 연구',
    );
    expect(find.text('연구'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('keeps no-category available for an empty category list',
      (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('newItemCategoryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('newItemCategory-none')), findsOneWidget);
    expect(find.byKey(const Key('newItemCategory-work')), findsNothing);
    expect(find.text('카테고리 없음'), findsOneWidget);
  });

  testWidgets('shows category loading before the loader completes',
      (tester) async {
    final completer = Completer<result.Result<List<Category>>>();
    await _pump(tester, categoryLoader: () => completer.future);

    expect(
      find.byKey(const Key('newItemCategoryLoading')),
      findsOneWidget,
    );
    expect(find.text('카테고리 불러오는 중'), findsOneWidget);
    expect(find.byKey(const Key('newItemCategoryButton')), findsNothing);

    completer.complete(result.success(const []));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('newItemCategoryButton')), findsOneWidget);
  });

  testWidgets('retries a failed category load', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      categoryLoader: () async {
        calls++;
        if (calls == 1) {
          return result.fail(const CacheFailure('category read failed'));
        }
        return result.success(const [_workCategory]);
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('카테고리를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.byKey(const Key('newItemCategoryRetryButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('newItemCategoryRetryButton')));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('카테고리를 불러오지 못했습니다.'), findsNothing);
    expect(find.byKey(const Key('newItemCategoryButton')), findsOneWidget);
  });

  testWidgets('switches to Todo without clearing the shared title',
      (tester) async {
    await _pump(tester);

    await tester.enterText(
      find.byKey(const Key('newItemTitleField')),
      '리뷰 요청 보내기',
    );
    await tester.tap(find.byKey(const Key('newItemTodoKind')));
    await tester.pumpAndSettle();

    expect(find.text('리뷰 요청 보내기'), findsOneWidget);
    expect(find.byKey(const Key('newItemUntimedMode')), findsOneWidget);
    expect(find.byKey(const Key('newItemStartTimeButton')), findsNothing);
    expect(find.byKey(const Key('newItemEndTimeButton')), findsNothing);
    expect(
      tester.getSemantics(find.byKey(const Key('newItemTodoKind'))),
      matchesSemantics(
        label: 'Todo',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
        children: const <Matcher>[],
      ),
    );
  });

  testWidgets('keeps a stable accessibility label after title entry',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    await tester.enterText(
      find.byKey(const Key('newItemTitleField')),
      '리뷰 요청 보내기',
    );

    expect(
      tester.getSemantics(find.byKey(const Key('newItemTitleSemantics'))).label,
      contains('제목'),
    );
    semantics.dispose();
  });

  testWidgets('shows and clears an invalid selected time range',
      (tester) async {
    final times = <TimeOfDay>[
      const TimeOfDay(hour: 10, minute: 0),
      const TimeOfDay(hour: 9, minute: 30),
      const TimeOfDay(hour: 10, minute: 30),
    ];
    await _pump(
      tester,
      timePicker: (_, __) async => times.removeAt(0),
    );

    await tester.tap(find.byKey(const Key('newItemStartTimeButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('newItemEndTimeButton')));
    await tester.pump();

    expect(find.text('오전 10:00'), findsOneWidget);
    expect(find.text('오전 9:30'), findsOneWidget);
    expect(
      find.text('종료 시간은 시작 시간보다 늦어야 합니다.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('newItemEndTimeButton')));
    await tester.pump();

    expect(find.text('오전 10:30'), findsOneWidget);
    expect(
      find.text('종료 시간은 시작 시간보다 늦어야 합니다.'),
      findsNothing,
    );
  });

  testWidgets('restores selected times after modes hide them', (tester) async {
    final times = <TimeOfDay>[
      const TimeOfDay(hour: 9, minute: 30),
      const TimeOfDay(hour: 10, minute: 30),
    ];
    await _pump(
      tester,
      timePicker: (_, __) async => times.removeAt(0),
    );

    await tester.tap(find.byKey(const Key('newItemStartTimeButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('newItemEndTimeButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('newItemAllDayMode')));
    await tester.pump();

    expect(find.byKey(const Key('newItemStartTimeButton')), findsNothing);

    await tester.tap(find.byKey(const Key('newItemTimedMode')));
    await tester.pump();
    expect(find.text('오전 9:30'), findsOneWidget);
    expect(find.text('오전 10:30'), findsOneWidget);

    await tester.tap(find.byKey(const Key('newItemTodoKind')));
    await tester.pump();
    expect(find.byKey(const Key('newItemStartTimeButton')), findsNothing);

    await tester.tap(find.byKey(const Key('newItemTimedMode')));
    await tester.pump();
    expect(find.text('오전 9:30'), findsOneWidget);
    expect(find.text('오전 10:30'), findsOneWidget);
  });

  testWidgets('close button reports one close request', (tester) async {
    var closeCalls = 0;
    await _pump(tester, onClose: () => closeCalls++);

    await tester.tap(find.byKey(const Key('newItemCloseButton')));

    expect(closeCalls, 1);
  });

  testWidgets('system back reports the same close request', (tester) async {
    var closeCalls = 0;
    await _pump(tester, onClose: () => closeCalls++);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(closeCalls, 1);
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

    await _pump(tester);

    await tester.ensureVisible(
      find.byKey(const Key('newItemEndTimeButton')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('newItemEndTimeButton')), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onClose,
  NewItemTimePicker? timePicker,
  NewItemCategoryLoader? categoryLoader,
}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: NewItemPage(
          selectedDate: DateTime(2026, 8, 3),
          onClose: onClose ?? () {},
          timePicker: timePicker,
          categoryLoader:
              categoryLoader ?? () async => result.success(const []),
        ),
      ),
    ),
  );
}

const _workCategory = Category(
  id: 'work',
  name: '연구',
  color: 0xFF76C4DE,
  sortOrder: 0,
);

const _personalCategory = Category(
  id: 'personal',
  name: '개인',
  color: 0xFFA4E85B,
  sortOrder: 1,
);

const _healthCategory = Category(
  id: 'health',
  name: '건강',
  color: 0xFFFFD64F,
  sortOrder: 2,
);
