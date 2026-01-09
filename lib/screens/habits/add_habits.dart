// import 'package:flutter/material.dart';
// import 'package:habits_app/utils/validator.dart';
// import 'package:habits_app/utils/widgets/appbutton.dart';
// import 'package:habits_app/utils/widgets/custom_textfiels.dart';
// import 'package:habits_app/utils/theme.dart';

// import '../../services/auth_service.dart';
// import '../../services/firestore_service.dart';

// class AddEditHabitScreen extends StatefulWidget {
//   const AddEditHabitScreen({super.key});

//   @override
//   State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
// }

// class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final _title = TextEditingController();
//   final _target = TextEditingController();

//   bool _loading = false;

//   String _emoji = "✨";
//   String _frequency = "daily";
//   bool _active = true;
//   int _color = 0xFF6D28D9;

//   String? _habitId; // if editing

//   @override
//   void dispose() {
//     _title.dispose();
//     _target.dispose();
//     super.dispose();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args = ModalRoute.of(context)?.settings.arguments as Map?;
//     if (args != null && _habitId == null && args['habit'] != null) {
//       final habit = Map<String, dynamic>.from(args['habit']);
//       _habitId = habit['id'] as String?;
//       _title.text = (habit['title'] ?? '').toString();
//       _emoji = (habit['emoji'] ?? '✨').toString();
//       _frequency = (habit['frequency'] ?? 'daily').toString();
//       _active = (habit['isActive'] ?? true) == true;
//       _color = (habit['color'] is int) ? habit['color'] as int : _color;
//       final t = habit['targetPerDay'];
//       if (t != null) _target.text = t.toString();
//       setState(() {});
//     }
//   }

//   void _snack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
//     );
//   }

//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _loading = true);
//     try {
//       final user = AuthService.instance.currentUser;
//       if (user == null) {
//         _snack("Please sign in again.");
//         return;
//       }
//       final uid = user.uid;

//       final target = _target.text.trim().isEmpty
//           ? null
//           : int.tryParse(_target.text.trim());

//       final data = <String, dynamic>{
//         'title': _title.text.trim(),
//         'emoji': _emoji,
//         'color': _color,
//         'frequency': _frequency,
//         'targetPerDay': target,
//         'isActive': _active,
//         'habitType': 'completionOnly',
//         'goalValue': target,
//       };

//       if (_habitId == null) {
//         await FirestoreService.instance.addHabit(uid, data);
//       } else {
//         await FirestoreService.instance.updateHabit(uid, _habitId!, data);
//       }

//       if (!mounted) return;
//       Navigator.pop(context);
//     } catch (e) {
//       _snack("Save failed. Please try again.");
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _confirmDelete() async {
//     final user = AuthService.instance.currentUser;
//     if (user == null) {
//       _snack("Please sign in again.");
//       return;
//     }
//     final uid = user.uid;
//     final id = _habitId!;
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Delete habit?"),
//         content: const Text("This will remove the habit and its logs."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text("Delete"),
//           ),
//         ],
//       ),
//     );

//     if (ok == true) {
//       await FirestoreService.instance.deleteHabit(uid, id);
//       if (!mounted) return;
//       Navigator.pop(context);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final editing = _habitId != null;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(editing ? "Edit Habit" : "New Habit"),
//         actions: [
//           if (editing)
//             IconButton(
//               onPressed: _confirmDelete,
//               icon: const Icon(Icons.delete_outline),
//             ),
//         ],
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   editing ? "Update your habit" : "Create a new habit",
//                   style: AppText.h2,
//                 ),
//                 const SizedBox(height: 14),

//                 AppTextField(
//                   controller: _title,
//                   label: "Title",
//                   hint: "e.g., Drink water",
//                   validator: (v) => Validators.requiredField(v, "Title"),
//                 ),
//                 const SizedBox(height: 12),

//                 Text("Emoji", style: AppText.muted),
//                 const SizedBox(height: 6),
//                 DropdownButtonFormField<String>(
//                   value: _emoji,
//                   items:
//                       const [
//                             "✨",
//                             "💧",
//                             "🏃",
//                             "📚",
//                             "🧘",
//                             "🍎",
//                             "😴",
//                             "🧠",
//                             "🦷",
//                           ]
//                           .map(
//                             (e) => DropdownMenuItem(value: e, child: Text(e)),
//                           )
//                           .toList(),
//                   onChanged: (v) => setState(() => _emoji = v ?? "✨"),
//                 ),
//                 const SizedBox(height: 12),

//                 Text("Frequency", style: AppText.muted),
//                 const SizedBox(height: 6),
//                 DropdownButtonFormField<String>(
//                   value: _frequency,
//                   items: const [
//                     DropdownMenuItem(value: "daily", child: Text("Daily")),
//                     DropdownMenuItem(value: "weekly", child: Text("Weekly")),
//                   ],
//                   onChanged: (v) => setState(() => _frequency = v ?? "daily"),
//                 ),
//                 const SizedBox(height: 12),

//                 AppTextField(
//                   controller: _target,
//                   label: "Target per day (optional)",
//                   hint: "e.g., 1",
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 12),

//                 SwitchListTile(
//                   contentPadding: EdgeInsets.zero,
//                   value: _active,
//                   onChanged: (v) => setState(() => _active = v),
//                   title: const Text("Active"),
//                 ),

//                 Text("Color", style: AppText.muted),
//                 const SizedBox(height: 10),
//                 Wrap(
//                   spacing: 10,
//                   children:
//                       [
//                         0xFF6D28D9,
//                         0xFF0EA5E9,
//                         0xFF16A34A,
//                         0xFFEF4444,
//                         0xFFF59E0B,
//                       ].map((c) {
//                         final selected = c == _color;
//                         return GestureDetector(
//                           onTap: () => setState(() => _color = c),
//                           child: Container(
//                             height: 42,
//                             width: 42,
//                             decoration: BoxDecoration(
//                               color: Color(c),
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                 color: selected
//                                     ? Colors.black
//                                     : Colors.transparent,
//                                 width: 2,
//                               ),
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                 ),

//                 const Spacer(),
//                 AppButton(
//                   text: editing ? "Save Changes" : "Save Habit",
//                   onTap: _save,
//                   loading: _loading,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:habits_app/utils/validator.dart';
import 'package:habits_app/utils/widgets/appbutton.dart';
import 'package:habits_app/utils/widgets/custom_textfiels.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:habits_app/utils/widgets/habitcard.dart';
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

  bool _loading = false;
  String _emoji = "✨";
  String _frequency = "daily";
  int _color = 0xFF6D28D9;
  String? _habitId;

  final List<String> _emojiList = ["✨", "💧", "🏃", "📚", "🧘", "🍎", "😴", "🧠", "🔋", "💪"];
  final List<int> _colorList = [0xFF6D28D9, 0xFF0EA5E9, 0xFF16A34A, 0xFFEF4444, 0xFFF59E0B];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && _habitId == null && args['habit'] != null) {
      final habit = Map<String, dynamic>.from(args['habit']);
      _habitId = habit['id'];
      _title.text = habit['title'] ?? '';
      _emoji = habit['emoji'] ?? '✨';
      _frequency = habit['frequency'] ?? 'daily';
      _color = habit['color'] ?? _color;
      _target.text = habit['targetPerDay']?.toString() ?? '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;

    final data = {
      'title': _title.text.trim(),
      'emoji': _emoji,
      'color': _color,
      'frequency': _frequency,
      'targetPerDay': int.tryParse(_target.text) ?? 1,
      'isActive': true,
    };

    if (_habitId == null) {
      await FirestoreService.instance.addHabit(uid, data);
    } else {
      await FirestoreService.instance.updateHabit(uid, _habitId!, data);
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFE),
      appBar: AppBar(
        title: Text(_habitId == null ? "New Habit" : "Edit Habit"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
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
                    // --- Live Preview ---
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

                    // --- Title Input ---
                    AppTextField(
                      controller: _title,
                      label: "Habit Title",
                      hint: "e.g. Drink Water",
                      onChanged: (v) => setState(() {}),
                      validator: (v) => v!.isEmpty ? "Title required" : null,
                    ),
                    const SizedBox(height: 20),

                    // --- Emoji Selector ---
                    const Text("Icon", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildEmojiPicker(),
                    const SizedBox(height: 20),

                    // --- Frequency Selector ---
                    const Text("Frequency", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildFrequencySelector(),
                    const SizedBox(height: 20),

                    // --- Color Selector ---
                    const Text("Color", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildColorPicker(),
                  ],
                ),
              ),
            ),
            
            // --- Bottom Save Button ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: AppButton(
                text: _habitId == null ? "Create Habit" : "Save Changes",
  onTap: _save,
  loading: _loading,
  color: AppColors.primary, // Add this line
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

  Widget _buildColorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _colorList.map((c) {
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



class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged; // Added this

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.onChanged, // Added this
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      onChanged: onChanged, // Connect it here
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}