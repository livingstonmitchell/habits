import 'package:flutter/material.dart';
import 'package:habits_app/utils/validator.dart';
import 'package:habits_app/utils/widgets/appbutton.dart';
import 'package:habits_app/utils/widgets/custom_textfiels.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:habits_app/models/habit_models.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class AddEditHabitScreen extends StatefulWidget {
  const AddEditHabitScreen({super.key});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _target = TextEditingController();
  final _unit = TextEditingController();

  bool _loading = false;

  String _emoji = "✨";
  String _frequency = "daily";
  HabitType _habitType = HabitType.completionOnly;
  bool _active = true;
  int _color = 0xFF6D28D9;

  String? _habitId; // if editing

  HabitType? _parseHabitType(dynamic value) {
    if (value is HabitType) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      for (final type in HabitType.values) {
        if (type.name.toLowerCase() == lower) return type;
      }
    }
    return null;
  }

  String get _goalHint {
    switch (_habitType) {
      case HabitType.steps:
        return "e.g., 5000";
      case HabitType.duration:
        return "e.g., 30";
      case HabitType.timesPerDay:
        return "e.g., 3";
      case HabitType.completionOnly:
      default:
        return "e.g., 1";
    }
  }

  String get _unitHint {
    switch (_habitType) {
      case HabitType.duration:
        return "minutes";
      case HabitType.steps:
        return "steps";
      case HabitType.timesPerDay:
        return "times";
      case HabitType.completionOnly:
      default:
        return "";
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && _habitId == null && args['habit'] != null) {
      final habit = Map<String, dynamic>.from(args['habit']);
      _habitId = habit['id'] as String?;
      _title.text = (habit['title'] ?? '').toString();
      _emoji = (habit['emoji'] ?? '✨').toString();
      _frequency = (habit['frequency'] ?? 'daily').toString();
      _habitType =
          _parseHabitType(habit['habitType']) ?? HabitType.completionOnly;
      _active = (habit['isActive'] ?? true) == true;
      _color = (habit['color'] is int) ? habit['color'] as int : _color;
      final t = habit['targetPerDay'];
      if (t != null) _target.text = t.toString();
      final g = habit['goalValue'];
      if (g != null && _target.text.isEmpty) {
        _target.text = g.toString();
      }
      final u = habit['unitLabel'];
      if (u != null) _unit.text = u.toString();
      setState(() {});
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        _snack("Please sign in again.");
        return;
      }
      final uid = user.uid;

      final target = _target.text.trim().isEmpty
          ? null
          : int.tryParse(_target.text.trim());

      final unitLabel = _unit.text.trim().isEmpty ? null : _unit.text.trim();

      final data = <String, dynamic>{
        'title': _title.text.trim(),
        'emoji': _emoji,
        'color': _color,
        'frequency': _frequency,
        'targetPerDay': target,
        'isActive': _active,
        'habitType': _habitType.name,
        'goalValue': target,
        'unitLabel': unitLabel,
      };

      if (_habitId == null) {
        await FirestoreService.instance.addHabit(uid, data);
      } else {
        await FirestoreService.instance.updateHabit(uid, _habitId!, data);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _snack("Save failed. Please try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _snack("Please sign in again.");
      return;
    }
    final uid = user.uid;
    final id = _habitId!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete habit?"),
        content: const Text("This will remove the habit and its logs."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirestoreService.instance.deleteHabit(uid, id);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = _habitId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? "Edit Habit" : "New Habit"),
        actions: [
          if (editing)
            IconButton(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editing ? "Update your habit" : "Create a new habit",
                  style: AppText.h2,
                ),
                const SizedBox(height: 14),

                AppTextField(
                  controller: _title,
                  label: "Title",
                  hint: "e.g., Drink water",
                  validator: (v) => Validators.requiredField(v, "Title"),
                ),
                const SizedBox(height: 12),

                Text("Emoji", style: AppText.muted),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _emoji,
                  items:
                      const [
                            "✨",
                            "💧",
                            "🏃",
                            "📚",
                            "🧘",
                            "🍎",
                            "😴",
                            "🧠",
                            "🦷",
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _emoji = v ?? "✨"),
                ),
                const SizedBox(height: 12),

                Text("Frequency", style: AppText.muted),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _frequency,
                  items: const [
                    DropdownMenuItem(value: "daily", child: Text("Daily")),
                    DropdownMenuItem(value: "weekly", child: Text("Weekly")),
                  ],
                  onChanged: (v) => setState(() => _frequency = v ?? "daily"),
                ),
                const SizedBox(height: 12),

                Text("Measurement", style: AppText.muted),
                const SizedBox(height: 6),
                DropdownButtonFormField<HabitType>(
                  value: _habitType,
                  items: const [
                    DropdownMenuItem(
                      value: HabitType.completionOnly,
                      child: Text("Completion only"),
                    ),
                    DropdownMenuItem(
                      value: HabitType.timesPerDay,
                      child: Text("Times per day"),
                    ),
                    DropdownMenuItem(
                      value: HabitType.steps,
                      child: Text("Steps"),
                    ),
                    DropdownMenuItem(
                      value: HabitType.duration,
                      child: Text("Minutes"),
                    ),
                  ],
                  onChanged: (v) => setState(
                    () => _habitType = v ?? HabitType.completionOnly,
                  ),
                ),
                const SizedBox(height: 12),

                AppTextField(
                  controller: _target,
                  label: "Goal (optional)",
                  hint: _goalHint,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _unit,
                  label: "Unit label (optional)",
                  hint: _unitHint,
                ),
                const SizedBox(height: 12),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: const Text("Active"),
                ),

                Text("Color", style: AppText.muted),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children:
                      [
                        0xFF6D28D9,
                        0xFF0EA5E9,
                        0xFF16A34A,
                        0xFFEF4444,
                        0xFFF59E0B,
                      ].map((c) {
                        final selected = c == _color;
                        return GestureDetector(
                          onTap: () => setState(() => _color = c),
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),

                const Spacer(),
                AppButton(
                  text: editing ? "Save Changes" : "Save Habit",
                  onTap: _save,
                  loading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
