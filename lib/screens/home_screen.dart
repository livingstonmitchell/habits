import 'package:flutter/material.dart';

import '../features/habits/habit_details_screen.dart';
import '../features/habits/habit_models.dart';
import '../routes/app_router.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  static final List<HabitDetailsArgs> _demoHabits = [
    HabitDetailsArgs(
      habitId: 'water-intake',
      title: 'Drink water',
      emoji: '💧',
      description: 'Stay hydrated through the day.',
      habitType: HabitType.timesPerDay,
      goalValue: 8,
      unitLabel: 'cups',
    ),
    HabitDetailsArgs(
      habitId: 'daily-run',
      title: 'Run',
      emoji: '🏃‍♂️',
      description: 'Log your runs by distance.',
      habitType: HabitType.steps,
      goalValue: 5000,
      unitLabel: 'steps',
    ),
    HabitDetailsArgs(
      habitId: 'meditation',
      title: 'Meditate',
      emoji: '🧘',
      description: 'Time spent in calm focus.',
      habitType: HabitType.duration,
      goalValue: 15,
      unitLabel: 'minutes',
    ),
    HabitDetailsArgs(
      habitId: 'read-pages',
      title: 'Read',
      emoji: '📚',
      description: 'Read anything you like.',
      habitType: HabitType.completionOnly,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _demoHabits.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final habit = _demoHabits[index];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.4),
              ),
            ),
            leading: Text(habit.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(habit.title),
            subtitle: Text(_subtitleFor(habit)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(
                context,
              ).pushNamed(AppRoutes.habitDetails, arguments: habit);
            },
          );
        },
      ),
    );
  }

  static String _subtitleFor(HabitDetailsArgs habit) {
    switch (habit.habitType) {
      case HabitType.completionOnly:
        return habit.description ?? 'Complete once per day';
      case HabitType.steps:
        return 'Goal: ${habit.goalValue ?? 0} ${habit.unitLabel ?? 'steps'}';
      case HabitType.duration:
        return 'Goal: ${habit.goalValue ?? 0} ${habit.unitLabel ?? 'minutes'}';
      case HabitType.timesPerDay:
        return 'Goal: ${habit.goalValue ?? 0} ${habit.unitLabel ?? 'times'}';
    }
  }
}
