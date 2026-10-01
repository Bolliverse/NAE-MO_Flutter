import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/manual_routine_candidates.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_definition.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_rule.dart';
import 'package:nae_mo/features/routine/domain/usecases/manual_routine_candidates.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

void main() {
  final date = DateTime(2026, 10, 1);
  final candidate = ManualRoutineCandidate(
    RoutineDefinition(
      rule: RoutineRule(
        id: 'walk',
        startDate: date,
        frequency: RoutineFrequency.daily,
        creationMode: RoutineCreationMode.manual,
      ),
      title: '산책하기',
      kind: TaskKind.todo,
    ),
    date,
  );

  testWidgets('expanded candidate is separate and confirmable', (tester) async {
    String? confirmed;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 220,
          child: ManualRoutineCandidates(
            candidates: [candidate],
            pendingIds: const {},
            isCompact: false,
            onConfirm: (id) => confirmed = id,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ));

    expect(find.text('수동으로 추가'), findsOneWidget);
    expect(find.text('산책하기'), findsOneWidget);
    await tester.tap(find.byKey(const Key('manualRoutineAdd-walk')));
    expect(confirmed, 'walk');
  });

  testWidgets('pending button is disabled and compact pane shows a count',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 70,
          height: 220,
          child: ManualRoutineCandidates(
            candidates: [candidate],
            pendingIds: const {'walk'},
            isCompact: true,
            onConfirm: (_) => calls++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ));

    expect(find.byKey(const Key('manualRoutineCompactCount')), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.byKey(const Key('manualRoutineAdd-walk')), findsNothing);
    expect(calls, 0);
  });
}
