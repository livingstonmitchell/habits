// import 'package:flutter/material.dart';
// import 'package:habits_app/utils/widgets/habitcard.dart';
// import 'package:habits_app/utils/routes/app_router.dart';
// import 'package:habits_app/services/auth_service.dart';
// import 'package:habits_app/services/firestore_service.dart';
// import 'package:habits_app/utils/theme.dart';
// import 'package:habits_app/models/habit_models.dart';
// import 'package:intl/intl.dart' show DateFormat;

// class TodayHomeScreen extends StatelessWidget {
//   const TodayHomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = AuthService.instance.currentUser;
//     if (user == null) {
//       // Render a safe fallback instead of navigating from build to avoid
//       // scheduler errors when the view gets disposed on web/hot-restart.
//       return Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(height: 12),
//               TextButton(
//                 onPressed: () =>
//                     Navigator.pushReplacementNamed(context, AppRoutes.login),
//                 child: const Text('Sign in again'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final uid = user.uid;
//     final todayLabel = DateFormat('EEE, MMM d').format(DateTime.now());

//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => Navigator.pushNamed(context, AppRoutes.addHabit),
//         child: const Icon(Icons.add),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
//           child: Column(
//             children: [
//               // ✅ Dribbble-ish header: Stack + avatar overlap + greeting
//               StreamBuilder<Map<String, dynamic>?>(
//                 stream: FirestoreService.instance.watchProfile(uid),
//                 builder: (context, snap) {
//                   final profile = snap.data ?? {};
//                   final name = (profile['displayName'] ?? 'Friend').toString();

//                   return Stack(
//                     children: [
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(26),
//                           border: Border.all(color: AppColors.stroke),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 _RoundIconButton(
//                                   icon: Icons.grid_view_rounded,
//                                   onTap: () {},
//                                 ),
//                                 const Spacer(),
//                                 _RoundIconButton(
//                                   icon: Icons.calendar_month_rounded,
//                                   onTap: () {},
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 14),
//                             Text("Hello, $name", style: AppText.h1),
//                             const SizedBox(height: 6),
//                             Text("Today • $todayLabel", style: AppText.muted),
//                             const SizedBox(height: 14),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 14,
//                                 vertical: 12,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: AppColors.bg,
//                                 borderRadius: BorderRadius.circular(18),
//                                 border: Border.all(color: AppColors.stroke),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Container(
//                                     height: 38,
//                                     width: 38,
//                                     decoration: BoxDecoration(
//                                       color: AppColors.primarySoft,
//                                       borderRadius: BorderRadius.circular(14),
//                                     ),
//                                     child: const Icon(
//                                       Icons.notifications_none_rounded,
//                                       color: AppColors.primary,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: Text(
//                                       "Quick tip: Tap + to add a habit, then check in daily.",
//                                       style: AppText.muted,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Positioned(
//                         right: 18,
//                         top: 62,
//                         child: CircleAvatar(
//                           radius: 26,
//                           backgroundColor: Colors.white,
//                           child: CircleAvatar(
//                             radius: 23,
//                             backgroundColor: AppColors.primarySoft,
//                             child: Text(
//                               name.isNotEmpty
//                                   ? name.substring(0, 1).toUpperCase()
//                                   : "U",
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w900,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),

//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   Text("Your habits", style: AppText.h2),
//                   const Spacer(),
//                   TextButton(
//                     onPressed: () =>
//                         Navigator.pushNamed(context, AppRoutes.addHabit),
//                     child: const Text("Add"),
//                   ),
//                 ],
//               ),

//               StreamBuilder<List<Map<String, dynamic>>>(
//                 stream: FirestoreService.instance.watchHabits(uid),
//                 builder: (context, snap) {
//                   if (snap.connectionState == ConnectionState.waiting) {
//                     return const Padding(
//                       padding: EdgeInsets.only(top: 20),
//                       child: Center(child: CircularProgressIndicator()),
//                     );
//                   }

//                   final habits = (snap.data ?? [])
//                       .where((h) => (h['isActive'] ?? true) == true)
//                       .toList();

//                   if (habits.isEmpty) {
//                     return Padding(
//                       padding: const EdgeInsets.only(top: 14),
//                       child: Card(
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.lightbulb_outline),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: Text(
//                                   "No active habits. Tap + to add one.",
//                                   style: AppText.muted,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   }

//                   return Column(
//                     children: habits.map((h) {
//                       final habitId = h['id'] as String;
//                       final title = (h['title'] ?? '').toString();
//                       final emoji = (h['emoji'] ?? '✨').toString();
//                       final color = (h['color'] is int)
//                           ? (h['color'] as int)
//                           : AppColors.primary.value;

//                       return StreamBuilder<bool>(
//                         stream: FirestoreService.instance.watchCompletedToday(
//                           uid,
//                           habitId,
//                         ),
//                         builder: (context, doneSnap) {
//                           final done = doneSnap.data ?? false;

//                           return Padding(
//                             padding: const EdgeInsets.only(bottom: 10),
//                             child: HabitCard(
//                               title: title,
//                               subtitle: (h['frequency'] ?? 'daily').toString(),
//                               emoji: emoji,
//                               color: color,
//                               checkedToday: done,
//                               onOpen: () => Navigator.pushNamed(
//                                 context,
//                                 AppRoutes.habitDetails,
//                                 arguments: HabitDetailsArgs(
//                                   habitId: habitId,
//                                   title: title.isEmpty ? 'Habit' : title,
//                                   emoji: emoji,
//                                   habitType: HabitType.completionOnly,
//                                   goalValue: h['targetPerDay'] is int
//                                       ? h['targetPerDay'] as int
//                                       : int.tryParse('${h['targetPerDay']}'),
//                                 ),
//                               ),
//                               onToggle: () => FirestoreService.instance
//                                   .toggleToday(uid, habitId),
//                               habit: null,
//                             ),
//                           );
//                         },
//                       );
//                     }).toList(),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _RoundIconButton extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onTap;

//   const _RoundIconButton({required this.icon, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(999),
//       child: Container(
//         height: 42,
//         width: 42,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(999),
//           border: Border.all(color: AppColors.stroke),
//         ),
//         child: Icon(icon, size: 20),
//       ),
//     );
//   }
// }

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:habits_app/utils/widgets/habitcard.dart';
import 'package:habits_app/utils/routes/app_router.dart';
import 'package:habits_app/services/auth_service.dart';
import 'package:habits_app/services/firestore_service.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:habits_app/models/habit_models.dart';
import 'package:intl/intl.dart';

class TodayHomeScreen extends StatelessWidget {
  const TodayHomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) return const _AuthFallback();

    final uid = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Ultra-light blue/grey
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          heroTag: 'home-fab',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.addHabit),
          // label: const Text(""),
          child:  Icon(Icons.add_rounded),
          backgroundColor: AppColors.primary,
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- Fancy App Bar ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RoundIconButton(
                      icon: Icons.widgets_outlined,
                      onTap: () {},
                    ),
                    StreamBuilder<Map<String, dynamic>?>(
                      stream: FirestoreService.instance.watchProfile(uid),
                      builder: (context, snap) {
                        final name = snap.data?['displayName'] ?? 'User';
                        return _ProfileAvatar(name: name);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // --- Header Card with Progress ---
            SliverToBoxAdapter(
              child: _HeaderStatsCard(uid: uid, greeting: _getGreeting()),
            ),

            // --- Horizontal Calendar ---
            SliverToBoxAdapter(child: _HorizontalCalendar()),

            // --- Habits List ---
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      "Today's Tasks",
                      style: AppText.h2.copyWith(fontSize: 20),
                    ),
                    const Spacer(),
                    TextButton(onPressed: () {}, child: const Text("See all")),
                  ],
                ),
              ),
            ),

            _HabitsStreamList(uid: uid),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// --- Sub-widgets for a cleaner structure ---

class _HeaderStatsCard extends StatelessWidget {
  final String uid;
  final String greeting;
  const _HeaderStatsCard({required this.uid, required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  "You're doing\ngreat today!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Circular Progress Widget
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: 0.7, // Connect this to your real logic
                  backgroundColor: Colors.white.withOpacity(0.2),
                  color: Colors.white,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              const Text(
                "70%",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HorizontalCalendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 3));
          final isToday = index == 3;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            decoration: BoxDecoration(
              color: isToday ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: isToday ? Border.all(color: AppColors.stroke) : null,
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('E').format(date),
                  style: TextStyle(
                    color: isToday ? AppColors.primary : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    color: isToday ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HabitsStreamList extends StatelessWidget {
  final String uid;
  const _HabitsStreamList({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.instance.watchHabits(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final habits = (snap.data ?? [])
            .where((h) => (h['isActive'] ?? true) == true)
            .toList();

        if (habits.isEmpty) {
          return const SliverToBoxAdapter(child: _EmptyState());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final h = habits[index];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _FancyHabitCard(uid: uid, h: h),
            );
          }, childCount: habits.length),
        );
      },
    );
  }
}

class _FancyHabitCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> h;
  const _FancyHabitCard({required this.uid, required this.h});

  @override
  Widget build(BuildContext context) {
    final habitId = h['id'] as String;
    return StreamBuilder<bool>(
      stream: FirestoreService.instance.watchCompletedToday(uid, habitId),
      builder: (context, doneSnap) {
        final done = doneSnap.data ?? false;
        return HabitCard(
          title: h['title'] ?? '',
          subtitle: (h['frequency'] ?? 'daily').toString(),
          emoji: h['emoji'] ?? '✨',
          color: h['color'] ?? AppColors.primary.value,
          checkedToday: done,
          onOpen: () => Navigator.pushNamed(
            context,
            AppRoutes.habitDetails,
            arguments: HabitDetailsArgs(
              habitId: habitId,
              title: h['title'] ?? 'Habit',
              emoji: h['emoji'] ?? '✨',
              habitType: HabitType.completionOnly,
              goalValue: h['targetPerDay'] ?? 1,
            ),
          ),
          onToggle: () => FirestoreService.instance.toggleToday(uid, habitId),
          habit: null,
        );
      },
    );
  }
}

// --- Supporting UI Components ---

class _ProfileAvatar extends StatelessWidget {
  final String name;
  const _ProfileAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primarySoft,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : "U",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.stroke.withOpacity(0.5)),
          ),
          child: Icon(icon, size: 22, color: Colors.black87),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.wb_sunny_outlined,
            size: 64,
            color: Colors.orange.shade200,
          ),
          const SizedBox(height: 16),
          Text("No habits for today", style: AppText.muted),
        ],
      ),
    );
  }
}

class _AuthFallback extends StatelessWidget {
  const _AuthFallback();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.login),
          child: const Text('Sign in again'),
        ),
      ),
    );
  }
}
