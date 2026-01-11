import 'package:flutter/material.dart';
import 'package:habits_app/models/habit_models.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:habits_app/utils/validator.dart';
import 'package:habits_app/utils/widgets/appbutton.dart';
import 'package:habits_app/utils/widgets/custom_textfiels.dart';
import 'package:habits_app/utils/widgets/habitcard.dart';
import 'package:habits_app/utils/routes/app_router.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class AddEditHabitScreen extends StatefulWidget {
  const AddEditHabitScreen({super.key});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  static const List<String> _emojiList = [
    "✨", "💧", "🏃", "📚", "🧘", "🍎", "😴", "🧠", "🦷",
    "🥦", "🥩", "🚫🥤", "🏋️", "🤸", "🪢", "🏃‍♂️",
  ];

  static const List<int> _colorOptions = [
    0xFF6D28D9,
    0xFF0EA5E9,
    0xFF16A34A,
    0xFFEF4444,
    0xFFF59E0B,
  ];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _target = TextEditingController();
  final _unit = TextEditingController();

  bool _loading = false;
  String _emoji = "✨";
  String _frequency = "daily";
  HabitType _habitType = HabitType.completionOnly;
  bool _active = true;
  int _color = _colorOptions.first;

  String? _habitId;

  bool _didInitFromArgs = false;

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

  HabitType _guessHabitType({required String title, required String emoji, String? category}) {
    final t = title.toLowerCase();
    final c = (category ?? '').toLowerCase();

    if (emoji.contains("🏃") || emoji.contains("🏋") || c.contains("fitness") || t.contains("run") || t.contains("walk") || t.contains("steps")) {
      return HabitType.steps;
    }
    if (emoji.contains("💧") || c.contains("nutrition") || t.contains("water") || t.contains("drink") || t.contains("fruit") || t.contains("veg")) {
      return HabitType.timesPerDay;
    }
    if (emoji.contains("😴") || c.contains("sleep") || t.contains("sleep")) {
      return HabitType.duration;
    }
    if (emoji.contains("🧘") || emoji.contains("🧠") || c.contains("mental") || t.contains("medit")) {
      return HabitType.duration;
    }
    return HabitType.completionOnly;
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
    if (_didInitFromArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args == null) {
      _didInitFromArgs = true;
      return;
    }

    // ===========================
    // 1) EDIT FLOW (existing habit)
    // ===========================
    if (_habitId == null && args['habit'] != null) {
      final habit = Map<String, dynamic>.from(args['habit']);

      _habitId = habit['id'] as String?;
      _title.text = (habit['title'] ?? '').toString();
      _emoji = (habit['emoji'] ?? '✨').toString();
      _frequency = (habit['frequency'] ?? 'daily').toString();
      _habitType = _parseHabitType(habit['habitType']) ?? HabitType.completionOnly;
      _active = (habit['isActive'] ?? true) == true;
      _color = (habit['color'] is int) ? habit['color'] as int : _colorOptions.first;

      final t = habit['targetPerDay'];
      if (t != null) _target.text = t.toString();
      final g = habit['goalValue'];
      if (g != null && _target.text.isEmpty) _target.text = g.toString();
      final u = habit['unitLabel'];
      if (u != null) _unit.text = u.toString();

      _didInitFromArgs = true;
      setState(() {});
      return;
    }

    // ===========================
    // 2) PREFILL FLOW (suggestion card)
    // ===========================
    final preTitle = args['prefillTitle']?.toString();
    final preEmoji = args['prefillEmoji']?.toString();
    final preCategory = args['prefillCategory']?.toString();
    final preGoal = args['prefillGoal'];
    final preUnit = args['prefillUnit']?.toString();
    final preHabitType = args['prefillHabitType'];

    if (_habitId == null) {
      if (preTitle != null && preTitle.trim().isNotEmpty && _title.text.isEmpty) {
        _title.text = preTitle.trim();
      }
      if (preEmoji != null && preEmoji.trim().isNotEmpty) {
        _emoji = preEmoji.trim();
      }

      if (preHabitType != null) {
        _habitType = _parseHabitType(preHabitType) ?? _habitType;
      } else {
        _habitType = _guessHabitType(title: _title.text, emoji: _emoji, category: preCategory);
      }

      if (_target.text.trim().isEmpty && preGoal != null) {
        final goalStr = preGoal.toString().trim();
        if (goalStr.isNotEmpty) _target.text = goalStr;
      }

      if (_unit.text.trim().isEmpty && preUnit != null && preUnit.trim().isNotEmpty) {
        _unit.text = preUnit.trim();
      }

      if (_unit.text.trim().isEmpty) {
        if (_habitType == HabitType.duration) _unit.text = "minutes";
        if (_habitType == HabitType.steps) _unit.text = "steps";
        if (_habitType == HabitType.timesPerDay) _unit.text = "times";
      }

      if (preCategory != null) {
        final c = preCategory.toLowerCase();
        if (c.contains("fitness")) _color = 0xFF16A34A;
        if (c.contains("nutrition")) _color = 0xFFF59E0B;
        if (c.contains("sleep")) _color = 0xFF0EA5E9;
        if (c.contains("mental")) _color = 0xFF6D28D9;
      }
    }

    _didInitFromArgs = true;
    setState(() {});
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

      final targetText = _target.text.trim();
      final target = targetText.isEmpty ? null : int.tryParse(targetText);
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

      String habitId = _habitId ?? '';
      if (_habitId == null) {
        habitId = await FirestoreService.instance.addHabit(user.uid, data);
      } else {
        await FirestoreService.instance.updateHabit(user.uid, _habitId!, data);
        habitId = _habitId!;
      }

      if (!mounted) return;

      final args = HabitDetailsArgs(
        habitId: habitId,
        title: _title.text.trim(),
        emoji: _emoji,
        habitType: _habitType,
        goalValue: target,
        unitLabel: unitLabel,
        description: null,
      );

      await Navigator.pushReplacementNamed(context, AppRoutes.habitDetails, arguments: args);
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
    if (_habitId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete habit?"),
        content: const Text("This will remove the habit and its logs."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (ok == true) {
      await FirestoreService.instance.deleteHabit(user.uid, _habitId!);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = _habitId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFE),
      appBar: AppBar(
        title: Text(editing ? "Edit Habit" : "New Habit"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          if (editing)
            IconButton(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PREVIEW", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    HabitCard(
                      title: _title.text.isEmpty ? "Your Habit Name" : _title.text,
                      subtitle: _frequency,
                      emoji: _emoji,
                      color: _color,
                      checkedToday: false,
                      onOpen: () {},
                      onToggle: () {},
                      habit: null,
                    ),
                    const SizedBox(height: 25),
                    AppTextField(
                      controller: _title,
                      label: "Habit Title",
                      hint: "e.g. Drink Water",
                      validator: (v) => Validators.requiredField(v, "Title"),
                    ),
                    const SizedBox(height: 20),
                    const Text("Icon", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildEmojiPicker(),
                    const SizedBox(height: 20),
                    const Text("Frequency", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildFrequencySelector(),
                    const SizedBox(height: 20),
                    const Text("Measurement", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildMeasurementSelector(),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _target,
                      label: "Goal (optional)",
                      hint: _goalHint,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _unit,
                      label: "Unit label (optional)",
                      hint: _unitHint,
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                      title: const Text("Active"),
                    ),
                    const SizedBox(height: 10),
                    const Text("Color", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildColorPicker(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: AppButton(
                text: editing ? "Save Changes" : "Save Habit",
                onTap: _save,
                loading: _loading,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _emojiList.map((e) {
        final selected = _emoji == e;
        return GestureDetector(
          onTap: () => setState(() => _emoji = e),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Text(e, style: const TextStyle(fontSize: 20)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencySelector() {
    return Row(
      children: ["daily", "weekly"].map((f) {
        final selected = _frequency == f;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _frequency = f),
            child: Container(
              margin: EdgeInsets.only(right: f == "daily" ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Center(
                child: Text(
                  f.toUpperCase(),
                  style: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMeasurementSelector() {
    return DropdownButtonFormField<HabitType>(
      value: _habitType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
      ),
      items: const [
        DropdownMenuItem(value: HabitType.completionOnly, child: Text("Completion only")),
        DropdownMenuItem(value: HabitType.timesPerDay, child: Text("Times per day")),
        DropdownMenuItem(value: HabitType.steps, child: Text("Steps")),
        DropdownMenuItem(value: HabitType.duration, child: Text("Minutes")),
      ],
      onChanged: (v) => setState(() => _habitType = v ?? HabitType.completionOnly),
    );
  }

  Widget _buildColorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _colorOptions.map((c) {
        final selected = _color == c;
        return GestureDetector(
          onTap: () => setState(() => _color = c),
          child: Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: Color(c),
              shape: BoxShape.circle,
              border: Border.all(color: selected ? Colors.black : Colors.transparent, width: 3),
            ),
            child: selected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
        );
      }).toList(),
    );
  }
}
