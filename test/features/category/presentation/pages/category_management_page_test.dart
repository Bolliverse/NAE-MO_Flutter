import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart' as result;
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/category/domain/usecases/create_category_use_case.dart';
import 'package:nae_mo/features/category/presentation/pages/category_management_page.dart';

void main() {
  testWidgets('loads and stably sorts category rows', (tester) async {
    await _pumpPage(
      tester,
      loader: () async => result.success(const [
        Category(id: 'later', name: '건강', color: 0xFFFFA629, sortOrder: 2),
        Category(id: 'b', name: '연구', color: 0xFF67C1DE, sortOrder: 0),
        Category(id: 'a', name: '개인', color: 0xFF9BDD55, sortOrder: 0),
      ]),
    );

    expect(find.byKey(const Key('categoryRow-a')), findsOneWidget);
    expect(find.byKey(const Key('categoryRow-b')), findsOneWidget);
    expect(find.byKey(const Key('categoryRow-later')), findsOneWidget);
    expect(
      _verticalCenter(tester, find.byKey(const Key('categoryRow-a'))),
      lessThan(_verticalCenter(tester, find.byKey(const Key('categoryRow-b')))),
    );
    expect(
      _verticalCenter(tester, find.byKey(const Key('categoryRow-b'))),
      lessThan(
        _verticalCenter(tester, find.byKey(const Key('categoryRow-later'))),
      ),
    );
  });

  testWidgets('shows loading, empty, failure, and retry states',
      (tester) async {
    final firstLoad = Completer<result.Result<List<Category>>>();
    var calls = 0;

    await _pumpPage(
      tester,
      settle: false,
      loader: () {
        calls++;
        if (calls == 1) return firstLoad.future;
        return Future.value(result.success(const <Category>[]));
      },
    );
    await tester.pump();

    expect(find.byKey(const Key('categoryListLoading')), findsOneWidget);

    firstLoad.complete(
      result.fail(const CacheFailure('category read failed')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('categoryListError')), findsOneWidget);
    expect(find.text('카테고리를 불러오지 못했습니다.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('categoryListRetryButton')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byKey(const Key('categoryEmptyState')), findsOneWidget);
    expect(find.text('아직 카테고리가 없습니다.'), findsOneWidget);
  });

  testWidgets('trims the name, sends the selected color, and appends success',
      (tester) async {
    CreateCategoryParams? submitted;

    await _pumpPage(
      tester,
      loader: () async => result.success(const <Category>[]),
      creator: (params) async {
        submitted = params;
        return result.success(
          Category(
            id: 'travel',
            name: params.name,
            color: params.color,
            sortOrder: 0,
          ),
        );
      },
    );

    await tester.tap(find.byKey(const Key('categoryAddButton')));
    await tester.pumpAndSettle();

    final createButton = find.byKey(const Key('categoryCreateButton'));
    expect(tester.widget<TextButton>(createButton).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('categoryNameField')),
      '  여행  ',
    );
    await tester.tap(find.byKey(const Key('categoryColorOption-4')));
    await tester.pump();
    expect(tester.widget<TextButton>(createButton).onPressed, isNotNull);

    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(submitted?.name, '여행');
    expect(submitted?.color, 0xFFFFA629);
    expect(find.byKey(const Key('categoryCreateSheet')), findsNothing);
    expect(find.byKey(const Key('categoryRow-travel')), findsOneWidget);
    expect(find.text('여행'), findsOneWidget);
  });

  testWidgets('blocks duplicate submits while creation is pending',
      (tester) async {
    final completer = Completer<result.Result<Category>>();
    var calls = 0;

    await _pumpPage(
      tester,
      loader: () async => result.success(const <Category>[]),
      creator: (params) {
        calls++;
        return completer.future;
      },
    );
    await _openCreateSheet(tester, name: '업무');

    final createButton = find.byKey(const Key('categoryCreateButton'));
    await tester.tap(createButton);
    await tester.pump();
    await tester.tap(createButton, warnIfMissed: false);
    await tester.pump();

    expect(calls, 1);
    expect(find.byKey(const Key('categoryCreateProgress')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('categoryCreateCancelButton')),
          )
          .onPressed,
      isNull,
    );

    completer.complete(
      result.success(
        const Category(
          id: 'work',
          name: '업무',
          color: 0xFF67C1DE,
          sortOrder: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('categoryRow-work')), findsOneWidget);
  });

  testWidgets('keeps input and retries after creation failure', (tester) async {
    var calls = 0;

    await _pumpPage(
      tester,
      loader: () async => result.success(const <Category>[]),
      creator: (params) async {
        calls++;
        if (calls == 1) {
          return result.fail(const CacheFailure('category create failed'));
        }
        return result.success(
          Category(
            id: 'study',
            name: params.name,
            color: params.color,
            sortOrder: 0,
          ),
        );
      },
    );
    await _openCreateSheet(tester, name: '학습');

    await tester.tap(find.byKey(const Key('categoryCreateButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('categoryCreateError')), findsOneWidget);
    expect(find.text('학습'), findsOneWidget);

    await tester.tap(find.byKey(const Key('categoryCreateButton')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byKey(const Key('categoryRow-study')), findsOneWidget);
  });

  testWidgets('closes with header or system back and fits accessible mobile',
      (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    var closes = 0;
    await _pumpPage(
      tester,
      onClose: () => closes++,
      loader: () async => result.success(const [
        Category(id: 'work', name: '업무', color: 0xFF67C1DE, sortOrder: 0),
      ]),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('categoryCloseButton')));
    expect(closes, 1);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(closes, 2);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required CategoryLoader loader,
  CategoryCreator? creator,
  VoidCallback? onClose,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: CategoryManagementPage(
          onClose: onClose ?? () {},
          loader: loader,
          creator: creator ??
              (params) async => result.success(
                    Category(
                      id: 'created',
                      name: params.name,
                      color: params.color,
                      sortOrder: 0,
                    ),
                  ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Future<void> _openCreateSheet(
  WidgetTester tester, {
  required String name,
}) async {
  await tester.tap(find.byKey(const Key('categoryAddButton')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('categoryNameField')), name);
  await tester.pump();
}

double _verticalCenter(WidgetTester tester, Finder finder) =>
    tester.getCenter(finder).dy;
