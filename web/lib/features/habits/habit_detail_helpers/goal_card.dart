import 'package:flutter/material.dart';

import '../../../models/habit_models.dart';

class HabitGoalCard extends StatelessWidget {
  HabitGoalCard({
    required this.progress,
    required this.goal,
    required this.unitLabel,
    required this.habitType,
  });

  final int progress;
  final int? goal;
  final String unitLabel;
  final HabitType habitType;

  @override
  Widget build(BuildContext context) {
    final labelUnit = unitLabel.trim().isEmpty ? '' : ' $unitLabel';
    final target = goal ?? 0;
    final fraction = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
    final percentText = target > 0 ? '${(fraction * 100).round()}%' : '—';
    final goalText = target > 0
        ? '$progress / $target$labelUnit'
        : '$progress$labelUnit logged';

    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 10,
      shadowColor: scheme.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer.withOpacity(0.45),
              scheme.primaryContainer.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: scheme.primary.withOpacity(0.2)),
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            _ProgressRing(
              fraction: target > 0 ? fraction : null,
              percentText: percentText,
              primary: scheme.primary,
              onPrimary: scheme.onPrimary,
              track: scheme.primary.withOpacity(0.12),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.flag,
                          size: 18,
                          color: scheme.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Goal',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Spacer(),
                      Text(
                        habitType.name,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(goalText, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.fraction,
    required this.percentText,
    required this.primary,
    required this.onPrimary,
    required this.track,
  });

  final double? fraction;
  final String percentText;
  final Color primary;
  final Color onPrimary;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      width: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: fraction,
            strokeWidth: 8,
            backgroundColor: track,
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.75),
            ),
            child: Text(
              percentText,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
