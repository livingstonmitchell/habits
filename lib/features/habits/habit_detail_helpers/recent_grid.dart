import 'package:flutter/material.dart';

import '../../../utils/streak_utils.dart';
import 'helpers.dart';

class HabitRecentGrid extends StatelessWidget {
  HabitRecentGrid({
    required this.completedKeys,
    required this.days,
    required this.title,
    this.compact = false,
    this.highlight = false,
  });

  final Set<String> completedKeys;
  final int days;
  final String title;
  final bool compact;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    int completedCount = 0;
    final cells = List.generate(days, (index) {
      final day = today.subtract(Duration(days: days - 1 - index));
      final key = dateKey(day);
      final done = completedKeys.contains(key);
      if (done) completedCount++;
      return _DayDot(date: day, done: done, compact: compact);
    });

    if (highlight && days == 7) {
      return _WeekStrip(
        title: title,
        completedCount: completedCount,
        days: days,
        cells: List.generate(days, (index) {
          final day = today.subtract(Duration(days: days - 1 - index));
          final key = dateKey(day);
          final done = completedKeys.contains(key);
          final isToday = DateUtils.isSameDay(day, today);
          return _WeekTile(date: day, done: done, isToday: isToday);
        }),
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (highlight)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$completedCount/$days done',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(spacing: compact ? 6 : 12, runSpacing: 8, children: cells),
      ],
    );

    if (!highlight) return content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F7FA), Color(0xFFF1F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: content,
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.title,
    required this.completedCount,
    required this.days,
    required this.cells,
  });

  final String title;
  final int completedCount;
  final int days;
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chipColor = scheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.primaryContainer.withOpacity(0.26),
        border: Border.all(color: scheme.primary.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chipColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: chipColor.withOpacity(0.4)),
                ),
                child: Text(
                  '$completedCount/$days done',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: cells
                .map(
                  (w) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: w,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WeekTile extends StatelessWidget {
  const _WeekTile({
    required this.date,
    required this.done,
    required this.isToday,
  });

  final DateTime date;
  final bool done;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseTextColor = isToday
        ? scheme.onPrimary
        : done
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final borderColor = isToday
        ? scheme.primary
        : done
        ? scheme.primary
        : scheme.outline;
    final background = isToday
        ? scheme.primary
        : done
        ? scheme.primaryContainer.withOpacity(0.35)
        : scheme.surface;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: baseTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            weekdayLabel(date),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: baseTextColor.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  _DayDot({required this.date, required this.done, required this.compact});

  final DateTime date;
  final bool done;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(dateOnly(DateTime.now()), date);
    final size = compact ? 22.0 : 40.0;
    final scheme = Theme.of(context).colorScheme;
    final baseColor = dayColor(date);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 180),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? baseColor : scheme.surfaceVariant,
            border: isToday
                ? Border.all(
                    color: done ? baseColor : scheme.secondary,
                    width: 2,
                  )
                : null,
            boxShadow: done
                ? [
                    BoxShadow(
                      color: baseColor.withOpacity(0.35),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: done ? Icon(Icons.check, size: 18, color: Colors.white) : null,
        ),
        if (!compact) ...[
          SizedBox(height: 4),
          Text(weekdayLabel(date), style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
