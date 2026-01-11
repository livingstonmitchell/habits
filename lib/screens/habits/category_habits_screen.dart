import 'package:flutter/material.dart';
import 'package:habits_app/models/habit_models.dart';
import 'package:habits_app/services/firestore_service.dart';
import 'package:habits_app/utils/routes/app_router.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:habits_app/utils/widgets/habitcard.dart';

class CategoryHabitsScreen extends StatefulWidget {
  final String uid;
  final String title;
  final List<Map<String, dynamic>> habits;

  const CategoryHabitsScreen({
    super.key,
    required this.uid,
    required this.title,
    required this.habits,
  });

  @override
  State<CategoryHabitsScreen> createState() => _CategoryHabitsScreenState();
}

class _CategoryHabitsScreenState extends State<CategoryHabitsScreen> {
  String _search = "";
  bool _activeOnly = true;
  String _freq = "all"; // all/daily/weekly
  String _sort = "newest"; // newest/title

  List<Map<String, dynamic>> _apply(List<Map<String, dynamic>> list) {
    var out = List<Map<String, dynamic>>.from(list);

    if (_activeOnly) {
      out = out.where((h) => (h['isActive'] ?? true) == true).toList();
    }

    if (_freq != "all") {
      out = out.where((h) => (h['frequency'] ?? 'daily').toString() == _freq).toList();
    }

    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      out = out.where((h) => (h['title'] ?? '').toString().toLowerCase().contains(q)).toList();
    }

    if (_sort == "title") {
      out.sort((a, b) => (a['title'] ?? '').toString().compareTo((b['title'] ?? '').toString()));
    }
    return out;
  }

  Future<void> _openFilterSheet() async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _CategoryFilterSheet(
        activeOnly: _activeOnly,
        freq: _freq,
        sort: _sort,
      ),
    );

    if (res != null && mounted) {
      setState(() {
        _activeOnly = (res['activeOnly'] as bool?) ?? _activeOnly;
        _freq = (res['freq'] as String?) ?? _freq;
        _sort = (res['sort'] as String?) ?? _sort;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _apply(widget.habits);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
                              hintText: "Search in this category...",
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

          Expanded(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.stroke),
                      ),
                      child: Text("No habits found.", style: AppText.muted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final h = filtered[i];
                      final habitId = (h['id'] ?? '').toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StreamBuilder<bool>(
                          stream: FirestoreService.instance.watchCompletedToday(widget.uid, habitId),
                          builder: (context, snap) {
                            final done = snap.data ?? false;

                            return HabitCard(
                              title: (h['title'] ?? '').toString(),
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
                                  goalValue: h['targetPerDay'] is int
                                      ? h['targetPerDay'] as int
                                      : int.tryParse('${h['targetPerDay']}'),
                                  unitLabel: (h['unitLabel'] ?? '').toString().trim().isEmpty
                                      ? null
                                      : (h['unitLabel'] ?? '').toString(),
                                  description: null,
                                ),
                              ),
                              onToggle: () => FirestoreService.instance.toggleToday(widget.uid, habitId),
                              habit: null,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterSheet extends StatefulWidget {
  final bool activeOnly;
  final String freq;
  final String sort;

  const _CategoryFilterSheet({
    required this.activeOnly,
    required this.freq,
    required this.sort,
  });

  @override
  State<_CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<_CategoryFilterSheet> {
  late bool _activeOnly = widget.activeOnly;
  late String _freq = widget.freq;
  late String _sort = widget.sort;

  @override
  Widget build(BuildContext context) {
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
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),

            SwitchListTile(
              value: _activeOnly,
              onChanged: (v) => setState(() => _activeOnly = v),
              title: const Text("Active only"),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 10),
            const Align(alignment: Alignment.centerLeft, child: Text("Frequency", style: TextStyle(fontWeight: FontWeight.w900))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                _pill("All", _freq == "all", () => setState(() => _freq = "all")),
                _pill("Daily", _freq == "daily", () => setState(() => _freq = "daily")),
                _pill("Weekly", _freq == "weekly", () => setState(() => _freq = "weekly")),
              ],
            ),

            const SizedBox(height: 14),
            const Align(alignment: Alignment.centerLeft, child: Text("Sort", style: TextStyle(fontWeight: FontWeight.w900))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                _pill("Newest", _sort == "newest", () => setState(() => _sort = "newest")),
                _pill("Title", _sort == "title", () => setState(() => _sort = "title")),
              ],
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, {
                  "activeOnly": _activeOnly,
                  "freq": _freq,
                  "sort": _sort,
                }),
                child: const Text("Apply"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, bool selected, VoidCallback onTap) {
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
          style: TextStyle(fontWeight: FontWeight.w900, color: selected ? Colors.white : AppColors.text),
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
            border: Border.all(color: AppColors.stroke.withOpacity(0.6)),
          ),
          child: Icon(icon, size: 22, color: Colors.black87),
        ),
      ),
    );
  }
}
