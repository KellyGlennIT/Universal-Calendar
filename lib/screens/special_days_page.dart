import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calendar_model.dart';
import '../models/special_day.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/calendar_math.dart';
import '../l10n/tr.dart';

/// Editor for a single calendar's special days.
class SpecialDaysPage extends StatefulWidget {
  final String calendarId;
  const SpecialDaysPage({super.key, required this.calendarId});

  @override
  State<SpecialDaysPage> createState() => _SpecialDaysPageState();
}

class _SpecialDaysPageState extends State<SpecialDaysPage> {
  final List<SpecialDay> _working = [];
  late CalendarModel _calendar;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final cal = provider.calendars.firstWhere(
      (c) => c.id == widget.calendarId,
      orElse: () => provider.calendars.first,
    );
    _calendar = cal;
    _working.addAll(cal.specialDays.map((s) => s.copy()));
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('${tr(context, 'Special Days')} · ${_calendar.name}'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: tr(context, 'Save'),
            onPressed: _save,
          ),
        ],
      ),
      body: _working.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_border,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(tr(context, 'No special days yet')),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'Tap + to add one'),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _working.length,
              itemBuilder: (context, index) {
                final s = _working[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: s.color.withValues(alpha: 0.2),
                      child: Text(s.emoji,
                          style: const TextStyle(fontSize: 18)),
                    ),
                    title: Text(s.name),
                    subtitle: Text(
                      '${_calendar.fullMonthNames[s.month - 1]} ${s.day}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _edit(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 20, color: Colors.red),
                          onPressed: () =>
                              setState(() => _working.removeAt(index)),
                        ),
                      ],
                    ),
                    onTap: () => _edit(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(null),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _edit(int? index) {
    final existing = index != null ? _working[index] : null;
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    int month = existing?.month ?? _calendar.yearStartMonth;
    int day = existing?.day ?? 1;
    String emoji = existing?.emoji ?? '⭐';
    Color color = existing?.color ?? const Color(0xFFD4AF37);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) {
          final maxMonth = _calendar.fullMonthNames.length;
          final maxDay = CalendarMath.getDaysInMonthForCalendar(
            _calendar,
            _calendar.yearStartMonth > 0 ? 2000 : 2000,
            month,
          );
          return AlertDialog(
            title: Text(
              existing == null
                  ? tr(context, 'Add')
                  : tr(context, 'Edit'),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Name:'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: month,
                        decoration: InputDecoration(
                          labelText: tr(context, 'Month:'),
                        ),
                        items: List.generate(maxMonth, (i) {
                          final m = i + 1;
                          return DropdownMenuItem(
                            value: m,
                            child: Text(
                              _calendar.fullMonthNames[i],
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        onChanged: (v) {
                          if (v == null) return;
                          update(() {
                            month = v;
                            final newMax =
                                CalendarMath.getDaysInMonthForCalendar(
                              _calendar,
                              2000,
                              v,
                            );
                            if (day > newMax) day = newMax;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: day.clamp(1, maxDay),
                        decoration: InputDecoration(
                          labelText: tr(context, 'Day:'),
                        ),
                        items: List.generate(maxDay, (i) {
                          final d = i + 1;
                          return DropdownMenuItem(
                              value: d, child: Text('$d'));
                        }),
                        onChanged: (v) {
                          if (v != null) update(() => day = v);
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: TextEditingController(text: emoji),
                    decoration: InputDecoration(
                      labelText: tr(context, 'Icon'),
                      hintText: '⭐',
                    ),
                    onChanged: (v) => emoji = v.isEmpty ? '⭐' : v,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Text(tr(context, 'Color'),
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: const [
                          Color(0xFFD4AF37),
                          Color(0xFF4DABF7),
                          Color(0xFF51CF66),
                          Color(0xFFFF6B6B),
                          Color(0xFF8B82FF),
                          Color(0xFFF783AC),
                        ].map((c) {
                          final selected =
                              color.toARGB32() == c.toARGB32();
                          return GestureDetector(
                            onTap: () => update(() => color = c),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c,
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: selected
                                  ? const Icon(Icons.check,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(tr(context, 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final hex =
                      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
                  final entry = SpecialDay(
                    id: existing?.id ?? CalendarMath.generateId(),
                    name: name,
                    month: month,
                    day: day.clamp(1, maxDay),
                    emoji: emoji,
                    colorHex: hex,
                  );
                  setState(() {
                    if (index == null) {
                      _working.add(entry);
                    } else {
                      _working[index] = entry;
                    }
                  });
                  Navigator.pop(dialogContext);
                },
                child: Text(tr(context, 'Save')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _save() {
    final provider =
        Provider.of<CalendarProvider>(context, listen: false);
    provider.setSpecialDays(widget.calendarId, _working);
    Navigator.pop(context);
  }
}