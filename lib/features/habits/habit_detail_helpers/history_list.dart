import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/firestore_service.dart';
import '../../../utils/streak_utils.dart';
import '../../../models/habit_models.dart';
import 'helpers.dart';
import 'model.dart';

class HabitHistoryList extends StatefulWidget {
  HabitHistoryList({
    required this.logs,
    required this.habitArgs,
    required this.uid,
  });

  final List<HabitLog> logs;
  final HabitDetailsArgs habitArgs;
  final String uid;

  @override
  State<HabitHistoryList> createState() => _HabitHistoryListState();
}

class _HabitHistoryListState extends State<HabitHistoryList> {
  bool _expanded = false;

  Future<void> _saveEntries({
    required HabitLog log,
    required List<ProgressEntry> entries,
  }) async {
    final goal = log.goalValue ?? widget.habitArgs.goalValue ?? 0;
    int running = 0;
    final entryMaps = <Map<String, dynamic>>[];
    final notes = <String>[];

    for (final entry in entries) {
      running += entry.added;
      final entryGoal = entry.goal ?? goal;
      if ((entry.note ?? '').isNotEmpty) notes.add(entry.note!);
      entryMaps.add({
        'added': entry.added,
        'total': running,
        'goal': entryGoal,
        'note': entry.note,
        'timestamp': entry.timestamp ?? Timestamp.now(),
      });
    }

    final completed = goal > 0 ? running >= goal : log.isCompleted;
    final todayKey = dateKey(log.date);

    await FirestoreService.instance
        .updateHabitLog(widget.uid, widget.habitArgs.habitId, todayKey, {
          'entries': entryMaps,
          'progress': running,
          'goal': goal == 0 ? null : goal,
          'goalValue': goal == 0 ? null : goal,
          'notes': notes.isEmpty ? null : notes,
          'note': notes.isEmpty ? null : notes.last,
          'completed': completed,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.logs;

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void showDetails(
      HabitLog log, {
      int? entryIndex,
      String? noteText,
      String? progressText,
    }) {
      final status = log.isCompleted ? 'Done' : 'Pending';
      final progressLine =
          progressText ?? progressSummary(log, widget.habitArgs) ?? '—';

      final ProgressEntry? entry =
          entryIndex != null && entryIndex < log.entries.length
          ? log.entries[entryIndex]
          : null;

      final amountController = TextEditingController(
        text: entry?.added.toString() ?? '',
      );
      final noteController = TextEditingController(
        text: noteText ?? entry?.note ?? '',
      );
      bool saving = false;

      Future<void> handleSave() async {
        if (entry == null) return;
        final added = int.tryParse(amountController.text.trim());
        if (added == null || added < 0) return;
        final newNote = noteController.text.trim();

        final entries = List<ProgressEntry>.from(log.entries);
        entries[entryIndex!] = ProgressEntry(
          added: added,
          total: entry.total,
          goal: entry.goal,
          note: newNote.isEmpty ? null : newNote,
          timestamp: entry.timestamp,
        );

        saving = true;
        setState(() {});
        try {
          await _saveEntries(log: log, entries: entries);
          if (mounted) Navigator.of(context).pop();
        } finally {
          saving = false;
          setState(() {});
        }
      }

      Future<void> handleDelete() async {
        if (entry == null) return;
        final entries = List<ProgressEntry>.from(log.entries)
          ..removeAt(entryIndex!);
        saving = true;
        setState(() {});
        try {
          await _saveEntries(log: log, entries: entries);
          if (mounted) Navigator.of(context).pop();
        } finally {
          saving = false;
          setState(() {});
        }
      }

      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friendlyDate(log.date),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(status),
                      backgroundColor: log.isCompleted
                          ? scheme.primary.withOpacity(0.15)
                          : scheme.outlineVariant.withOpacity(0.3),
                    ),
                    const SizedBox(width: 10),
                    Chip(
                      label: Text('Progress: $progressLine'),
                      backgroundColor: scheme.secondaryContainer.withOpacity(
                        0.25,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (entry != null) ...[
                  Text(
                    'Edit entry',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (added)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Note'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: saving ? null : handleSave,
                          icon: saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Save'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: saving ? null : handleDelete,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'Notes',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (log.notes.isEmpty)
                    Text(
                      'No notes for this day yet.',
                      style: textTheme.bodyMedium,
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: log.notes.length,
                      separatorBuilder: (_, __) => const Divider(height: 10),
                      itemBuilder: (_, idx) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: textTheme.bodyMedium),
                            Expanded(
                              child: Text(
                                log.notes[idx],
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ],
            ),
          );
        },
      );
    }

    Widget cell(
      String text, {
      bool header = false,
      TextAlign align = TextAlign.left,
      int maxLines = 2,
      TextOverflow overflow = TextOverflow.ellipsis,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Text(
          text,
          textAlign: align,
          maxLines: maxLines,
          overflow: overflow,
          style: header
              ? textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                )
              : textTheme.bodyMedium,
        ),
      );
    }

    Widget tapCell(
      String text,
      HabitLog log, {
      TextAlign align = TextAlign.left,
      int maxLines = 2,
      int? entryIndex,
      String? noteText,
      String? progressText,
    }) {
      return InkWell(
        onTap: () => showDetails(
          log,
          entryIndex: entryIndex,
          noteText: noteText,
          progressText: progressText,
        ),
        child: cell(text, align: align, maxLines: maxLines),
      );
    }

    final rows = <TableRow>[
      TableRow(
        children: [
          cell('Date', header: true),
          cell('Status', header: true),
          cell('Progress', header: true, align: TextAlign.center),
          cell('Note', header: true),
        ],
      ),
    ];

    for (final log in logs) {
      final goal = log.goalValue ?? widget.habitArgs.goalValue;
      final status = log.isCompleted ? 'Done' : 'Pending';

      final entries = log.entries;
      if (entries.isNotEmpty) {
        for (var i = 0; i < entries.length; i++) {
          final entry = entries[i];
          final entryGoal = entry.goal ?? goal;
          final pct = (entryGoal != null && entryGoal > 0)
              ? ((entry.total / entryGoal) * 100)
                    .clamp(0, 999)
                    .toStringAsFixed(0)
              : null;
          final progressLine = (entryGoal != null && entryGoal > 0)
              ? '${entry.total}/${entryGoal}${pct != null ? ' ($pct%)' : ''}'
              : progressSummary(log, widget.habitArgs) ?? '—';
          final note = entry.note ?? (i < log.notes.length ? log.notes[i] : '');

          rows.add(
            TableRow(
              children: [
                tapCell(
                  i == 0 ? friendlyDate(log.date) : '',
                  log,
                  entryIndex: i,
                  progressText: progressLine,
                  noteText: note,
                ),
                tapCell(
                  i == 0 ? status : '',
                  log,
                  entryIndex: i,
                  progressText: progressLine,
                  noteText: note,
                ),
                tapCell(
                  progressLine,
                  log,
                  align: TextAlign.center,
                  entryIndex: i,
                  progressText: progressLine,
                  noteText: note,
                ),
                tapCell(
                  note.isEmpty ? '—' : note,
                  log,
                  maxLines: 3,
                  entryIndex: i,
                  progressText: progressLine,
                  noteText: note,
                ),
              ],
            ),
          );
        }
      } else {
        final progressVal = log.progress ?? 0;
        final pct = (goal != null && goal > 0)
            ? ((progressVal / goal) * 100).clamp(0, 999).toStringAsFixed(0)
            : null;
        final progressLine = (goal != null && goal > 0)
            ? '$progressVal/$goal${pct != null ? ' ($pct%)' : ''}'
            : (progressSummary(log, widget.habitArgs) ?? '—');
        final notes = log.notes;

        if (notes.isEmpty) {
          rows.add(
            TableRow(
              children: [
                tapCell(friendlyDate(log.date), log),
                tapCell(status, log),
                tapCell(progressLine, log, align: TextAlign.center),
                tapCell('—', log, maxLines: 3),
              ],
            ),
          );
        } else {
          for (var i = 0; i < notes.length; i++) {
            rows.add(
              TableRow(
                children: [
                  tapCell(i == 0 ? friendlyDate(log.date) : '', log),
                  tapCell(i == 0 ? status : '', log),
                  tapCell(progressLine, log, align: TextAlign.center),
                  tapCell(notes[i], log, maxLines: 3),
                ],
              ),
            );
          }
        }
      }
    }

    final tableCard = Card(
      elevation: 6,
      shadowColor: scheme.primary.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              scheme.surfaceVariant.withOpacity(0.25),
              scheme.surface.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: scheme.outline.withOpacity(0.18)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 520),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(110),
                1: FixedColumnWidth(90),
                2: FixedColumnWidth(110),
                3: FixedColumnWidth(180),
              },
              border: TableBorder.symmetric(
                inside: BorderSide(
                  color: scheme.outlineVariant.withOpacity(0.4),
                  width: 0.6,
                ),
              ),
              children: rows,
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Text(
                'History',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 20),
            ],
          ),
        ),
        if (_expanded && logs.isEmpty) ...[
          const SizedBox(height: 8),
          Text('No completions yet. Start your streak today!'),
        ],
        if (_expanded && logs.isNotEmpty) ...[
          const SizedBox(height: 8),
          tableCard,
        ],
      ],
    );
  }
}
