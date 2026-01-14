import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:habits_app/models/habit_models.dart';
import 'package:habits_app/screens/habits/category_habits_screen.dart';
import 'package:habits_app/screens/nutrition/manage_nutrition_screen.dart';
import 'package:habits_app/screens/nutrition/nutrition_action_screen.dart';
import 'package:habits_app/screens/nutrition/nutrition_meal_screen.dart';
import 'package:habits_app/screens/nutrition/water_tracker_screen.dart';
import 'package:habits_app/services/auth_service.dart';
import 'package:habits_app/services/firestore_service.dart';
import 'package:habits_app/utils/routes/app_router.dart';
import 'package:habits_app/utils/streak_utils.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:habits_app/utils/widgets/habitcard.dart';
import 'package:intl/intl.dart';

class TodayHomeScreen extends StatefulWidget {
  const TodayHomeScreen({super.key});

  @override
  State<TodayHomeScreen> createState() => _TodayHomeScreenState();
}

class _TodayHomeScreenState extends State<TodayHomeScreen> {
  // ✅ MAIN TAB
  String _tab =
      "All"; // All / Habits / Nutrition / Sleep / Just Because / For the foodie / House and home / Financials / Health and wellness / In the morning / The night before
  String _search = "";

  bool _showOnlyActive = true;
  String _freqFilter = "all"; // all / daily / weekly
  String _sort = "newest"; // newest / title

  // ✅ Cache preview chips so they don't reshuffle every rebuild
  late final List<Map<String, String>> _quickIdeasPreviewCache;

  @override
  void initState() {
    super.initState();
    _quickIdeasPreviewCache = _buildRandomQuickIdeasPreview(limit: 3);
  }

  // ✅ Suggestions for the NEW tabs
  static const Map<String, List<Map<String, String>>> _suggestionGroups = {
    "Just Because": [
      {"t": "Give someone a compliment", "e": "💬"},
      {"t": "Smile at a stranger", "e": "😊"},
      {"t": "Text an old friend", "e": "📩"},
      {"t": "Outdoor activities", "e": "🌳"},
      {"t": "On-time / Wasn’t late", "e": "⏰"},
      {"t": "Learn something new", "e": "🧠"},
      {"t": "Laughing out loud", "e": "😂"},
      {"t": "Gratitude practice", "e": "🙏"},
      {"t": "Journaling", "e": "📓"},
      {"t": "Reading", "e": "📚"},
      {"t": "No screen time", "e": "📵"},
    ],
    "For the foodie": [
      {"t": "Try a new recipe", "e": "🍳"},
      {"t": "Eat breakfast", "e": "🥣"},
      {"t": "Meat-free eating", "e": "🥗"},
      {"t": "Order in", "e": "🛵"},
      {"t": "Cook at home", "e": "🏠"},
      {"t": "No alcohol", "e": "🚫🍷"},
      {"t": "Eat fruit", "e": "🍎"},
      {"t": "Eat veggies", "e": "🥦"},
      {"t": "Drink 8 glasses of water", "e": "💧"},
      {"t": "No late-night snacking", "e": "🌙"},
      {"t": "Meal planning", "e": "🗓️"},
    ],
    "House and home": [
      {"t": "Sweep", "e": "🧹"},
      {"t": "Mop", "e": "🧼"},
      {"t": "Clear the sink", "e": "🚰"},
      {"t": "Water plants", "e": "🪴"},
      {"t": "Tidy up", "e": "🧺"},
    ],
    "Financials": [
      {"t": "No spending", "e": "🚫💸"},
      {"t": "Pay bills", "e": "🧾"},
      {"t": "No credit card balance", "e": "💳"},
      {"t": "Pay day", "e": "💰"},
    ],
    "Health and wellness": [
      {"t": "Vitamins/meds", "e": "💊"},
      {"t": "Mood", "e": "🙂"},
      {"t": "Meditation", "e": "🧘"},
      {"t": "Exercise", "e": "🏋️"},
      {"t": "Daily steps", "e": "👟"},
      {"t": "Affirmations", "e": "✨"},
      {"t": "Slept 7-8 hours", "e": "😴"},
    ],
    "In the morning": [
      {"t": "Caffeine-Free", "e": "☕🚫"},
      {"t": "Coffee without sugar", "e": "☕"},
      {"t": "Write a to-do list", "e": "✅"},
      {"t": "Clear our inbox", "e": "📥"},
      {"t": "Send a just because text to a friend", "e": "📩"},
    ],
    "The night before": [
      {"t": "Pack lunch", "e": "🥪"},
      {"t": "Layout clothes", "e": "👕"},
      {"t": "Review tomorrow’s schedule", "e": "🗓️"},
      {"t": "10-minute tidy up", "e": "🧺"},
      {"t": "Give thanks", "e": "🙏"},
      {"t": "Wind down an hour before bedtime", "e": "🌙"},
    ],
  };

  static const Set<String> _suggestionTabs = {
    "Just Because",
    "For the foodie",
    "House and home",
    "Financials",
    "Health and wellness",
    "In the morning",
    "The night before",
  };

  bool get _isSuggestionTab => _suggestionTabs.contains(_tab);

  // ✅ RANDOM preview builder (cached in initState)
  List<Map<String, String>> _buildRandomQuickIdeasPreview({int limit = 3}) {
    final all = _suggestionGroups.entries
        .expand((e) => e.value.map((it) => {"t": it["t"]!, "e": it["e"]!, "c": e.key}))
        .toList();

    all.shuffle(Random());

    return all.take(limit).toList();
  }

  List<Map<String, String>> _suggestionItemsForMainTab() {
    if (_tab == "All") {
      return _suggestionGroups.entries
          .expand((e) => e.value.map((it) => {"t": it["t"]!, "e": it["e"]!, "c": e.key}))
          .toList();
    }
    final list = _suggestionGroups[_tab] ?? const [];
    return list.map((it) => {"t": it["t"]!, "e": it["e"]!, "c": _tab}).toList();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  // ====== UI-only category inference (no schema changes) ======
  String _categoryOf(Map<String, dynamic> h) {
    final title = (h['title'] ?? '').toString().toLowerCase();
    final emoji = (h['emoji'] ?? '').toString();

    bool hasAny(List<String> w) => w.any((x) => title.contains(x));

    if (emoji.contains('🏃') ||
        emoji.contains('🏋') ||
        hasAny(['run', 'walk', 'gym', 'exercise', 'workout', 'fitness', 'steps'])) {
      return "Fitness";
    }
    if (emoji.contains('💧') ||
        emoji.contains('🍎') ||
        hasAny(['water', 'hydrate', 'diet', 'food', 'nutrition', 'protein', 'fruit', 'veg'])) {
      return "Nutrition";
    }
    if (emoji.contains('😴') || hasAny(['sleep', 'bed', 'rest'])) {
      return "Sleep";
    }
    if (emoji.contains('🧘') ||
        emoji.contains('🧠') ||
        hasAny(['meditate', 'meditation', 'mindful', 'calm', 'breath', 'gratitude', 'mental'])) {
      return "Mental health";
    }
    if (emoji.contains('📚') ||
        hasAny(['study', 'read', 'journal', 'learn', 'plan', 'focus', 'budget', 'product'])) {
      return "Productivity";
    }
    return "Lifestyle";
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.stroke,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text("Filter & Sort", style: AppText.h2),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _showOnlyActive,
                  onChanged: (v) => setState(() => _showOnlyActive = v),
                  title: const Text("Show only active habits"),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 10),
                const _SheetGroupTitle("Frequency"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    _Pill(
                      text: "All",
                      selected: _freqFilter == "all",
                      onTap: () => setState(() => _freqFilter = "all"),
                    ),
                    _Pill(
                      text: "Daily",
                      selected: _freqFilter == "daily",
                      onTap: () => setState(() => _freqFilter = "daily"),
                    ),
                    _Pill(
                      text: "Weekly",
                      selected: _freqFilter == "weekly",
                      onTap: () => setState(() => _freqFilter = "weekly"),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SheetGroupTitle("Sort"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    _Pill(
                      text: "Newest",
                      selected: _sort == "newest",
                      onTap: () => setState(() => _sort = "newest"),
                    ),
                    _Pill(
                      text: "Title",
                      selected: _sort == "title",
                      onTap: () => setState(() => _sort = "title"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> habits) {
    var list = habits;

    if (_showOnlyActive) {
      list = list.where((h) => (h['isActive'] ?? true) == true).toList();
    }

    if (_freqFilter != "all") {
      list = list.where((h) => (h['frequency'] ?? 'daily').toString() == _freqFilter).toList();
    }

    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      list = list.where((h) => (h['title'] ?? '').toString().toLowerCase().contains(q)).toList();
    }

    if (_sort == "title") {
      list.sort((a, b) => (a['title'] ?? '').toString().compareTo((b['title'] ?? '').toString()));
    }

    return list;
  }

  Future<void> _confirmDeleteHabit({
    required String uid,
    required String habitId,
    required String title,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete habit?"),
        content: Text("Are you sure you want to delete “$title”? This will remove its history too."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirestoreService.instance.deleteHabit(uid, habitId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Habit deleted")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not delete habit: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) return const _AuthFallback();
    final uid = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          heroTag: 'home-fab',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.addHabit),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ===== Top row =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RoundIconButton(
                      icon: Icons.widgets_outlined,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.addHabit),
                    ),
                    StreamBuilder<Map<String, dynamic>?>(
                      stream: FirestoreService.instance.watchProfile(uid),
                      builder: (context, snap) {
                        final name = (snap.data?['displayName'] ?? 'User').toString();
                        return InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.userProfile,
                            arguments: {'tab': 2},
                          ),
                          child: _ProfileAvatar(name: name),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ===== Search + Filter =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.stroke),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (v) => setState(() => _search = v),
                                decoration: const InputDecoration(
                                  hintText: "Search habits...",
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _RoundIconButton(
                      icon: Icons.tune_rounded,
                      onTap: _openFilterSheet,
                    ),
                  ],
                ),
              ),
            ),

            // ===== Tabs =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: _TabPills(
                  value: _tab,
                  onChanged: (v) => setState(() => _tab = v),
                ),
              ),
            ),

            // ===== Header card =====
            SliverToBoxAdapter(
              child: _HeaderStatsCard(
                uid: uid,
                greeting: _getGreeting(),
                onOpenCalendar: () => Navigator.pushNamed(context, AppRoutes.calendar),
              ),
            ),

            // ===== Main content =====
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService.instance.watchHabits(uid),
              builder: (context, snap) {
                final rawHabits = snap.data ?? [];
                final filtered = _applyFilters(rawHabits);

                // ✅ Suggestion tab -> show ONLY suggestions
                if (_isSuggestionTab) {
                  final items = _suggestionItemsForMainTab();
                  return SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        const SizedBox(height: 10),
                        _SectionHeader(
                          title: _tab,
                          action: "Add",
                          onAction: () => Navigator.pushNamed(context, AppRoutes.addHabit),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _SuggestionsWrap(
                            items: items,
                            onPick: (title, category, emoji) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.addHabit,
                                arguments: {
                                  "prefillTitle": title,
                                  "prefillEmoji": emoji,
                                  "prefillCategory": category,
                                  "prefillHabitType": "completionOnly",
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  );
                }

                // ✅ Habits-only list
                if (_tab == "Habits") {
                  return _HabitsListSliver(
                    uid: uid,
                    habits: filtered,
                    onDelete: (habitId, title) => _confirmDeleteHabit(uid: uid, habitId: habitId, title: title),
                  );
                }

                final showAll = _tab == "All";
                final showNutrition = _tab == "Nutrition";
                final showSleep = _tab == "Sleep";

                final fitness = filtered.where((h) => _categoryOf(h) == "Fitness").toList();
                final lifestyle = filtered.where((h) => _categoryOf(h) == "Lifestyle").toList();
                final productivity = filtered.where((h) => _categoryOf(h) == "Productivity").toList();
                final mental = filtered.where((h) => _categoryOf(h) == "Mental health").toList();
                final nutrition = filtered.where((h) => _categoryOf(h) == "Nutrition").toList();
                final sleep = filtered.where((h) => _categoryOf(h) == "Sleep").toList();

                return SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      const SizedBox(height: 8),

                      // ✅ All tab
                      if (showAll) ...[
                        _SectionHeader(
                          title: "Start New Habits",
                          action: "Add",
                          onAction: () => Navigator.pushNamed(context, AppRoutes.addHabit),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 150,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _SuggestionCard(
                                title: "Drink Water",
                                subtitle: "Hydration 💧",
                                emoji: "💧",
                                category: "Nutrition",
                                goalText: "8 glasses",
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.addHabit,
                                  arguments: {
                                    "prefillTitle": "Drink Water",
                                    "prefillEmoji": "💧",
                                    "prefillCategory": "Nutrition",
                                    "prefillGoal": 8,
                                    "prefillUnit": "glasses",
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              _SuggestionCard(
                                title: "Eat Fruit",
                                subtitle: "Vitamins 🍎",
                                emoji: "🍎",
                                category: "Nutrition",
                                goalText: "2 servings",
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.addHabit,
                                  arguments: {
                                    "prefillTitle": "Eat Fruit",
                                    "prefillEmoji": "🍎",
                                    "prefillCategory": "Nutrition",
                                    "prefillGoal": 2,
                                    "prefillUnit": "servings",
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              _SuggestionCard(
                                title: "Meditation",
                                subtitle: "Calm 🧘",
                                emoji: "🧘",
                                category: "Mental health",
                                goalText: "10 minutes",
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.addHabit,
                                  arguments: {
                                    "prefillTitle": "Meditation",
                                    "prefillEmoji": "🧘",
                                    "prefillCategory": "Mental health",
                                    "prefillGoal": 10,
                                    "prefillUnit": "minutes",
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ✅ Quick ideas (PREVIEW ONLY 3 RANDOM)
                        _SectionHeader(
                          title: "Quick ideas",
                          action: "See all",
                          onAction: () => setState(() => _tab = "Just Because"),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _SuggestionsWrap(
                            items: _quickIdeasPreviewCache, // ✅ only 3 random
                            onPick: (title, category, emoji) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.addHabit,
                                arguments: {
                                  "prefillTitle": title,
                                  "prefillEmoji": emoji,
                                  "prefillCategory": category,
                                  "prefillHabitType": "completionOnly",
                                },
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 18),

                        _SectionHeader(title: "Health widgets", action: "Customize", onAction: () {}),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: const [
                              Expanded(child: _HealthWidgetCard(title: "Heart rate", value: "100 / 60", icon: Icons.favorite_border)),
                              SizedBox(width: 12),
                              Expanded(child: _HealthWidgetCard(title: "Blood sugar", value: "100 / 70", icon: Icons.opacity_outlined)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: const [
                              Expanded(child: _HealthWidgetCard(title: "Water", value: "2 / 8", icon: Icons.water_drop_outlined)),
                              SizedBox(width: 12),
                              Expanded(child: _HealthWidgetCard(title: "Sleep", value: "6h 20m", icon: Icons.bedtime_outlined)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        _CategoryStrip(title: "Fitness", items: fitness, uid: uid),
                        _CategoryStrip(title: "Lifestyle", items: lifestyle, uid: uid),
                        _CategoryStrip(title: "Productivity", items: productivity, uid: uid),
                        _CategoryStrip(title: "Mental health", items: mental, uid: uid),
                        _CategoryStrip(title: "Nutrition", items: nutrition, uid: uid),
                        _CategoryStrip(title: "Sleep", items: sleep, uid: uid),

                        const SizedBox(height: 16),

                        _SectionHeader(
                          title: "Recent activity",
                          action: "Calendar",
                          onAction: () => Navigator.pushNamed(context, AppRoutes.calendar),
                        ),
                        const SizedBox(height: 10),
                        _RecentActivity(uid: uid, habits: filtered),

                        const SizedBox(height: 16),

                        _SectionHeader(
                          title: "This week",
                          action: "Open calendar",
                          onAction: () => Navigator.pushNamed(context, AppRoutes.calendar),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _MiniWeekRow(onTap: () => Navigator.pushNamed(context, AppRoutes.calendar)),
                        ),

                        const SizedBox(height: 16),

                        _SectionHeader(
                          title: "Today's Tasks",
                          action: "Add",
                          onAction: () => Navigator.pushNamed(context, AppRoutes.addHabit),
                        ),
                        const SizedBox(height: 8),
                        _HabitsInlineList(
                          uid: uid,
                          habits: filtered,
                          onDelete: (habitId, title) => _confirmDeleteHabit(uid: uid, habitId: habitId, title: title),
                        ),

                        const SizedBox(height: 120),
                      ],

                      // ✅ Nutrition tab
                      if (showNutrition) ...[
                        const SizedBox(height: 6),
                        _NutritionPanel(onOpenHabits: () => setState(() => _tab = "Habits")),
                        const SizedBox(height: 14),
                        _CategoryStrip(title: "Nutrition habits", items: nutrition, uid: uid),
                        const SizedBox(height: 120),
                      ],

                      // ✅ Sleep tab
                      if (showSleep) ...[
                        const SizedBox(height: 6),
                        _SleepPanel(onOpenHabits: () => setState(() => _tab = "Habits")),
                        const SizedBox(height: 14),
                        _CategoryStrip(title: "Sleep habits", items: sleep, uid: uid),
                        const SizedBox(height: 120),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ========================= UI blocks =========================

class _TabPills extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _TabPills({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      "All",
      "Habits",
      "Nutrition",
      "Sleep",
      "Just Because",
      "For the foodie",
      "House and home",
      "Financials",
      "Health and wellness",
      "In the morning",
      "The night before",
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final t = tabs[i];
          final selected = t == value;

          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChanged(t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? AppColors.primary : AppColors.stroke),
              ),
              child: Text(
                t,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : AppColors.text,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderStatsCard extends StatelessWidget {
  final String uid;
  final String greeting;
  final VoidCallback onOpenCalendar;
  const _HeaderStatsCard({
    required this.uid,
    required this.greeting,
    required this.onOpenCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 18,
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
                Text(greeting, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 6),
                const Text(
                  "Your rhythm today",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEE, MMM d').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onOpenCalendar,
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;
  const _SectionHeader({required this.title, required this.action, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          Text(title, style: AppText.h2.copyWith(fontSize: 19)),
          const Spacer(),
          TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final String category;
  final String? goalText;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.category,
    required this.onTap,
    this.goalText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.muted),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MiniChip(text: category),
                      if (goalText != null && goalText!.trim().isNotEmpty) _MiniChip(text: goalText!, icon: Icons.flag_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _MiniChip({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.text),
            const SizedBox(width: 6),
          ],
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class _HealthWidgetCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _HealthWidgetCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.muted),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Suggestions Wrap
class _SuggestionsWrap extends StatelessWidget {
  final List<Map<String, String>> items;
  final void Function(String title, String category, String emoji) onPick;

  const _SuggestionsWrap({required this.items, required this.onPick});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Text("No suggestions in this tab.", style: AppText.muted),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((it) {
        final title = it["t"]!;
        final emoji = it["e"]!;
        final category = it["c"]!;

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onPick(title, category, emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------- Horizontal category strips ----------
class _CategoryStrip extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String uid;

  const _CategoryStrip({required this.title, required this.items, required this.uid});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: title,
          action: "See all",
          onAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryHabitsScreen(uid: uid, title: title, habits: items),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemBuilder: (context, i) => _CategoryHabitCard(uid: uid, habit: items[i]),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: items.length.clamp(0, 12),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _CategoryHabitCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> habit;

  const _CategoryHabitCard({required this.uid, required this.habit});

  @override
  Widget build(BuildContext context) {
    final title = (habit['title'] ?? '').toString();
    final emoji = (habit['emoji'] ?? '✨').toString();
    final color = (habit['color'] is int) ? habit['color'] as int : AppColors.primary.value;
    final habitId = (habit['id'] ?? '').toString();
    final freq = (habit['frequency'] ?? 'daily').toString();

    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
              const Spacer(),
              StreamBuilder<bool>(
                stream: FirestoreService.instance.watchCompletedToday(uid, habitId),
                builder: (context, snap) {
                  final done = snap.data ?? false;
                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => FirestoreService.instance.toggleToday(uid, habitId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: done ? Color(color).withOpacity(0.10) : AppColors.bg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: done ? Color(color) : AppColors.stroke),
                      ),
                      child: Icon(done ? Icons.check : Icons.add, size: 18, color: done ? Color(color) : AppColors.text),
                    ),
                  );
                },
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(freq, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.muted),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- Recent Activity ----------
class _RecentActivity extends StatelessWidget {
  final String uid;
  final List<Map<String, dynamic>> habits;

  const _RecentActivity({required this.uid, required this.habits});

  static String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<List<_ActivityItem>> _load() async {
    final now = DateTime.now();
    final start = _startOfDay(now.subtract(const Duration(days: 6)));
    final startKey = _dateKey(start);

    final out = <_ActivityItem>[];

    for (final h in habits) {
      final habitId = (h['id'] ?? '').toString();
      if (habitId.isEmpty) continue;

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('habits')
          .doc(habitId)
          .collection('logs')
          .where('isCompleted', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: startKey)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) continue;

      final data = snap.docs.first.data();
      final date = (data['date'] ?? '').toString();
      if (date.isEmpty) continue;

      out.add(_ActivityItem(
        habitId: habitId,
        title: (h['title'] ?? 'Habit').toString(),
        emoji: (h['emoji'] ?? '✨').toString(),
        dateKey: date,
      ));
    }

    out.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return out.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ActivityItem>>(
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: LinearProgressIndicator(),
          );
        }

        final items = snap.data ?? [];
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Text("No check-ins yet this week.", style: AppText.muted),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: items.map((it) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: Text(it.emoji, style: const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.title, style: const TextStyle(fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text("Checked • ${it.dateKey}", style: AppText.muted),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _ActivityItem {
  final String habitId;
  final String title;
  final String emoji;
  final String dateKey;
  _ActivityItem({required this.habitId, required this.title, required this.emoji, required this.dateKey});
}

// ---------- Mini week ----------
class _MiniWeekRow extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniWeekRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (i) => DateTime(start.year, start.month, start.day + i));

    bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: days.map((d) {
            final isToday = sameDay(d, today);
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primarySoft : AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isToday ? AppColors.primary : AppColors.stroke),
                ),
                child: Column(
                  children: [
                    Text(DateFormat('E').format(d).substring(0, 1), style: AppText.muted),
                    const SizedBox(height: 6),
                    Text("${d.day}", style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------- Habit lists ----------
class _HabitsListSliver extends StatelessWidget {
  final String uid;
  final List<Map<String, dynamic>> habits;
  final void Function(String habitId, String title) onDelete;

  const _HabitsListSliver({
    required this.uid,
    required this.habits,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) return const SliverToBoxAdapter(child: _EmptyState());

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _HabitRow(uid: uid, h: habits[index], onDelete: onDelete),
        ),
        childCount: habits.length,
      ),
    );
  }
}

class _HabitsInlineList extends StatelessWidget {
  final String uid;
  final List<Map<String, dynamic>> habits;
  final void Function(String habitId, String title) onDelete;

  const _HabitsInlineList({
    required this.uid,
    required this.habits,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) return const _EmptyState();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: habits
            .map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HabitRow(uid: uid, h: h, onDelete: onDelete),
                ))
            .toList(),
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> h;
  final void Function(String habitId, String title) onDelete;

  const _HabitRow({
    required this.uid,
    required this.h,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final habitId = (h['id'] ?? '').toString();
    final title = (h['title'] ?? '').toString();

    return StreamBuilder<bool>(
      stream: FirestoreService.instance.watchCompletedToday(uid, habitId),
      builder: (context, snap) {
        final done = snap.data ?? false;

        return GestureDetector(
          onLongPress: () => onDelete(habitId, title), // ✅ delete on long press
          child: HabitCard(
            title: title,
            subtitle: (h['frequency'] ?? 'daily').toString(),
            emoji: (h['emoji'] ?? '✨').toString(),
            color: (h['color'] is int) ? (h['color'] as int) : AppColors.primary.value,
            checkedToday: done,
            onOpen: () => Navigator.pushNamed(
              context,
              AppRoutes.habitDetails,
              arguments: HabitDetailsArgs(
                habitId: habitId,
                title: (h['title'] ?? 'Habit').toString(),
                emoji: (h['emoji'] ?? '✨').toString(),
                habitType: HabitType.completionOnly,
                goalValue: h['targetPerDay'] is int ? h['targetPerDay'] as int : int.tryParse('${h['targetPerDay']}'),
              ),
            ),
            onToggle: () => FirestoreService.instance.toggleToday(uid, habitId),
            habit: null,
          ),
        );
      },
    );
  }
}

// ---------- Top buttons / avatar ----------
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
            border: Border.all(color: AppColors.stroke.withOpacity(0.6)),
          ),
          child: Icon(icon, size: 22, color: Colors.black87),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  const _ProfileAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primarySoft,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "U",
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }
}

// ---------- Empty/auth ----------
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Text("Nothing to show here yet.", style: AppText.muted),
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
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
          child: const Text('Sign in again'),
        ),
      ),
    );
  }
}

class _SheetGroupTitle extends StatelessWidget {
  final String text;
  const _SheetGroupTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.primary : AppColors.stroke),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }
}

// ====================== Nutrition + Sleep Panels (UI-only) ======================

class _NutritionPanel extends StatefulWidget {
  /// You can still keep this if you want (for tab switching elsewhere),
  /// but we will NOT use it for the button anymore.
  final VoidCallback onOpenHabits;
  const _NutritionPanel({required this.onOpenHabits});

  @override
  State<_NutritionPanel> createState() => _NutritionPanelState();
}

class _NutritionPanelState extends State<_NutritionPanel> {
  String? get _uid => AuthService.instance.currentUser?.uid;

  // You can later store this in profile/settings
  final int _dailyCalorieGoal = 2500;

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Future<void> _openAddFoodDialog(String uid, String dayKey) async {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final fatCtrl = TextEditingController();

    String meal = "Any";

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setD) {
            return AlertDialog(
              title: const Text("Add food"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Food name (ex: Chicken)",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: calCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Calories (kcal)"),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: carbsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Carbs (g)"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: proteinCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Protein (g)"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: fatCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Fat (g)"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: meal,
                      items: const [
                        DropdownMenuItem(value: "Any", child: Text("Any")),
                        DropdownMenuItem(value: "Breakfast", child: Text("Breakfast")),
                        DropdownMenuItem(value: "Lunch", child: Text("Lunch")),
                        DropdownMenuItem(value: "Dinner", child: Text("Dinner")),
                        DropdownMenuItem(value: "Snack", child: Text("Snack")),
                      ],
                      onChanged: (v) => setD(() => meal = v ?? "Any"),
                      decoration: const InputDecoration(labelText: "Meal"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final calories = int.tryParse(calCtrl.text.trim()) ?? 0;

                    if (name.isEmpty || calories <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Enter a valid food name and calories.")),
                      );
                      return;
                    }

                    Navigator.pop(context, true);
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;

    if (saved != true) {
      nameCtrl.dispose();
      calCtrl.dispose();
      carbsCtrl.dispose();
      proteinCtrl.dispose();
      fatCtrl.dispose();
      return;
    }

    await FirestoreService.instance.addFoodForDay(
      uid: uid,
      dayKey: dayKey,
      name: nameCtrl.text.trim(),
      calories: int.tryParse(calCtrl.text.trim()) ?? 0,
      carbs: int.tryParse(carbsCtrl.text.trim()) ?? 0,
      protein: int.tryParse(proteinCtrl.text.trim()) ?? 0,
      fat: int.tryParse(fatCtrl.text.trim()) ?? 0,
      meal: meal,
    );

    nameCtrl.dispose();
    calCtrl.dispose();
    carbsCtrl.dispose();
    proteinCtrl.dispose();
    fatCtrl.dispose();
  }

  Future<bool> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete food?"),
        content: const Text("This will remove it from today's intake."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );
    return ok == true;
  }

  void _openManageNutrition() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageNutritionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) return const SizedBox.shrink();

    final dayKey = dateKey(dateOnly(DateTime.now()));

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.instance.watchFoodsForDay(uid, dayKey),
      builder: (context, snap) {
        final foods = snap.data ?? [];

        final totalCalories = foods.fold<int>(0, (sum, f) => sum + _asInt(f['calories']));
        final totalCarbs = foods.fold<int>(0, (sum, f) => sum + _asInt(f['carbs']));
        final totalProtein = foods.fold<int>(0, (sum, f) => sum + _asInt(f['protein']));
        final totalFat = foods.fold<int>(0, (sum, f) => sum + _asInt(f['fat']));

        final intake = (totalCalories / _dailyCalorieGoal).clamp(0.0, 1.0);
        final pct = (intake * 100).round();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("Daily intake", style: AppText.h2.copyWith(fontSize: 18)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.stroke),
                          ),
                          child: Text(
                            "$pct%",
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$totalCalories / $_dailyCalorieGoal kcal",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 10),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: intake,
                        minHeight: 12,
                        backgroundColor: AppColors.bg,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _macroChip("Carbs", "$totalCarbs g"),
                        const SizedBox(width: 8),
                        _macroChip("Protein", "$totalProtein g"),
                        const SizedBox(width: 8),
                        _macroChip("Fat", "$totalFat g"),
                      ],
                    ),

                    const SizedBox(height: 14),

                    if (foods.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.stroke),
                        ),
                        child: Text("No foods logged today yet.", style: AppText.muted),
                      )
                    else
                      Column(
                        children: foods.take(4).map((f) {
                          final id = (f['id'] ?? '').toString();
                          final name = (f['name'] ?? 'Food').toString();
                          final kcal = _asInt(f['calories']);
                          final meal = (f['meal'] ?? 'Any').toString();

                          return Dismissible(
                            key: ValueKey(id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDelete(),
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.red),
                            ),
                            onDismissed: (_) {
                              FirestoreService.instance.deleteFoodForDay(
                                uid: uid,
                                dayKey: dayKey,
                                foodId: id,
                              );
                            },
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                // Optional: open a "Food details" page later
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.stroke),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.restaurant_menu, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.w900),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(meal, style: AppText.muted),
                                        ],
                                      ),
                                    ),
                                    Text("$kcal kcal", style: AppText.muted),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openAddFoodDialog(uid, dayKey),
                        icon: const Icon(Icons.add),
                        label: const Text("Add food"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ✅ FIXED: This now opens ManageNutritionScreen
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _openManageNutrition,
                  child: const Text("Manage nutrition habits"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _macroChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.muted),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}




class _SleepPanel extends StatefulWidget {
  final VoidCallback onOpenHabits;
  const _SleepPanel({required this.onOpenHabits});

  @override
  State<_SleepPanel> createState() => _SleepPanelState();
}

class _SleepPanelState extends State<_SleepPanel> {
  double _sleepScore = 0.72; // UI-only
  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 30);
  final List<double> _week = const [0.55, 0.70, 0.62, 0.80, 0.66, 0.90, 0.74];

  Future<void> _pickBedtime() async {
    final picked = await showTimePicker(context: context, initialTime: _bedTime);
    if (picked != null) setState(() => _bedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final scorePct = (_sleepScore * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Sleep insights", style: AppText.h2.copyWith(fontSize: 18)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.stroke),
                      ),
                      child: Text(
                        "$scorePct%",
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 70,
                          width: 70,
                          child: CircularProgressIndicator(
                            value: _sleepScore,
                            strokeWidth: 7,
                            backgroundColor: AppColors.bg,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        Text(
                          "$scorePct",
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("You're on track", style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text("Aim for 7–8 hours and a steady bedtime.", style: AppText.muted),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SoftDivider(),
                const SizedBox(height: 12),
                Text("Last 7 days", style: AppText.muted),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final r = _week[i].clamp(0.0, 1.0);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.bg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.stroke),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.bottomCenter,
                                      heightFactor: (0.12 + (r * 0.88)).clamp(0.12, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("•", style: AppText.muted.copyWith(fontSize: 14)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.bedtime_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Bedtime",
                        style: AppText.body.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    TextButton(onPressed: _pickBedtime, child: Text(_bedTime.format(context))),
                  ],
                ),
                Text("Tap time to change bedtime reminder.", style: AppText.muted),
                const SizedBox(height: 6),
                Slider(
                  value: _sleepScore,
                  onChanged: (v) => setState(() => _sleepScore = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniActionCard(
                  title: "Wind down",
                  subtitle: "5 min breathing",
                  icon: Icons.self_improvement_outlined,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniActionCard(
                  title: "No phone",
                  subtitle: "30 min before bed",
                  icon: Icons.phonelink_erase_outlined,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onOpenHabits,
              child: const Text("Manage sleep habits"),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _MealRow({
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppText.muted),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}



class _MiniActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppText.muted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCounter extends StatelessWidget {
  final String valueText;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _MiniCounter({
    required this.valueText,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onMinus,
          child: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.stroke),
            ),
            child: const Icon(Icons.remove, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        Text(valueText, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPlus,
          child: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.stroke),
            ),
            child: const Icon(Icons.add, size: 18),
          ),
        ),
      ],
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, width: double.infinity, color: AppColors.stroke);
  }
}
