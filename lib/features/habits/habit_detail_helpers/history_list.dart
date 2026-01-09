import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../utils/streak_utils.dart';
import '../habit_models.dart';
import 'helpers.dart';
import 'model.dart';

class HabitHistoryList extends StatefulWidget {
  HabitHistoryList({required this.logs, required this.habitArgs});

  final List<HabitLog> logs;
  final HabitDetailsArgs habitArgs;

  @override
  State<HabitHistoryList> createState() => _HabitHistoryListState();
}

class _HabitHistoryListState extends State<HabitHistoryList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final logs = widget.logs;

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void showDetails(HabitLog log) {
      final progressLine = progressSummary(log, widget.habitArgs) ?? '—';
      final status = log.isCompleted ? 'Done' : 'Pending';
      final noteController = TextEditingController(
        text: (log.note?.isNotEmpty ?? false) ? log.note! : '',
      );
      bool saving = false;

      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> saveNote() async {
                final trimmed = noteController.text.trim();
                setSheetState(() => saving = true);
                try {
                  final docRef = FirebaseFirestore.instance
                      .collection('habits')
                      .doc(widget.habitArgs.habitId)
                      .collection('logs')
                      .doc(dateKey(log.date));
                  await docRef.set({
                    'note': trimmed.isEmpty ? null : trimmed,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Note saved')));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not save note: $e')),
                    );
                  }
                } finally {
                  setSheetState(() => saving = false);
                }
              }

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
                          backgroundColor: scheme.secondaryContainer
                              .withOpacity(0.25),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Note',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Add a note for this day...',
                        filled: true,
                        fillColor: scheme.surfaceVariant.withOpacity(0.25),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: saving ? null : saveNote,
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
                        label: const Text('Save note'),
                      ),
                    ),
                  ],
                ),
              );
            },
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
    }) {
      return InkWell(
        onTap: () => showDetails(log),
        child: cell(text, align: align),
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
      final progressLine = progressSummary(log, widget.habitArgs) ?? '—';
      final status = log.isCompleted ? 'Done' : 'Pending';
      final note = (log.note?.isNotEmpty ?? false) ? log.note! : '—';
      rows.add(
        TableRow(
          children: [
            tapCell(friendlyDate(log.date), log),
            tapCell(status, log),
            tapCell(progressLine, log, align: TextAlign.center),
            tapCell(note, log),
          ],
        ),
      );
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
