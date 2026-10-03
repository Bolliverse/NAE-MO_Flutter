import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nae_mo/features/routine/domain/usecases/manual_routine_candidates.dart';

/// Keeps virtual candidates visually separate from materialized day items.
class ManualRoutineCandidates extends StatelessWidget {
  const ManualRoutineCandidates({
    super.key,
    required this.candidates,
    required this.pendingIds,
    required this.isCompact,
    required this.onConfirm,
    required this.child,
  });

  final List<ManualRoutineCandidate> candidates;
  final Set<String> pendingIds;
  final bool isCompact;
  final ValueChanged<String> onConfirm;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) return child;
    if (isCompact) {
      return Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 4,
            right: 4,
            bottom: 8,
            child: IgnorePointer(
              child: Container(
                key: const Key('manualRoutineCompactCount'),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF9B9B9B)),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '+${candidates.length}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          height: math.min(150, 34 + candidates.length * 44).toDouble(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 7, 10, 4),
                child: Text('수동으로 추가',
                    style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
              ),
              Expanded(
                // A bounded list builds only the visible candidate rows.
                // https://api.flutter.dev/flutter/widgets/ListView-class.html
                child: ListView.builder(
                  primary: false,
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    final pending = pendingIds.contains(candidate.routineId);
                    return SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              candidate.definition.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            key: Key('manualRoutineAdd-${candidate.routineId}'),
                            onPressed: pending
                                ? null
                                : () => onConfirm(candidate.routineId),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF222222),
                            ),
                            child: Text(pending ? '추가 중' : '추가'),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E2E2)),
        Expanded(child: child),
      ],
    );
  }
}
