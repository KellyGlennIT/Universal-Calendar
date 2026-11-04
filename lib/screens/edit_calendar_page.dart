import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/calendar_model.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/calendar_math.dart';
import '../l10n/tr.dart';

/// Edit an existing calendar.
///
/// Everything that does not change the calendar's arithmetic can be edited
/// here: name, icon, colour, time/date format, week start and weekday names.
/// The year offset has its own live preview, so the user always sees the
/// year number that will actually be shown before saving.
class EditCalendarPage extends StatefulWidget {
  final CalendarModel calendar;
  const EditCalendarPage({super.key, required this.calendar});

  @override
  State<EditCalendarPage> createState() => _EditCalendarPageState();
}

class _EditCalendarPageState extends State<EditCalendarPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emojiController;
  late String _colorHex;
  late String _timeFormat;
  late String _dateFormat;
  late String _weekStartDay;
  late int _yearOffset;

  static const List<String> _emojis = [
    '📅',
    '🗓️',
    '🌍',
    '✡️',
    '☪️',
    '⛪',
    '🏛️',
    '🇫🇷',
    '🌙',
    '☀️',
    '⭐',
    '🔔',
  ];

  static const List<String> _colors = [
    '#4DABF7',
    '#51CF66',
    '#D4AF37',
    '#20C997',
    '#B197FC',
    '#CC5DE8',
    '#FF8787',
    '#FF922B',
  ];

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.calendar;
    _nameController = TextEditingController(text: c.name);
    _emojiController = TextEditingController(text: c.emoji);
    _colorHex = c.colorHex;
    _timeFormat = c.timeFormat;
    _dateFormat = c.dateFormat;
    _weekStartDay =
        _weekdays.contains(c.weekStartDay) ? c.weekStartDay : _weekdays.first;
    _yearOffset = c.yearOffset;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final accent = _hexToColor(_colorHex);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tr(context, 'Edit Calendar')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              tr(context, 'Save Changes'),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Identity ─────────────────────────────────────────────
          _sectionTitle(context, tr(context, 'Name & Icon')),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Calendar Name'),
                      prefixIcon: Icon(Icons.edit_outlined, color: accent),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr(context, 'Icon'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _emojis.map((e) {
                      final selected = _emojiController.text == e;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _emojiController.text = e);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? accent.withValues(alpha: 0.18)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? accent
                                  : Theme.of(context).dividerColor,
                              width: selected ? 1.6 : 1,
                            ),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 18)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Colour ───────────────────────────────────────────────
          _sectionTitle(context, tr(context, 'Color')),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((hex) {
                  final color = _hexToColor(hex);
                  final selected = _colorHex == hex;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _colorHex = hex);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                )
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Year offset with live preview ─────────────────────────
          _sectionTitle(context, tr(context, 'Year offset')),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_repeat, size: 18, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr(context,
                              'Offset = calendar year − Gregorian year'),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _stepButton(
                        icon: Icons.remove,
                        // Long-press jumps by 100 so historic calendars such
                        // as the French Republican (-1791) stay quick to set.
                        onLongPress: () => setState(() => _yearOffset -= 100),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _yearOffset--);
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => _editOffsetDirectly(context),
                                child: Text(
                                  '$_yearOffset',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              Text(
                                tr(context, 'Year offset'),
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 0.6,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _stepButton(
                        icon: Icons.add,
                        onLongPress: () => setState(() => _yearOffset += 100),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _yearOffset++);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _yearPreview(context, accent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Formats ──────────────────────────────────────────────
          _sectionTitle(context, tr(context, 'Time & Date')),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _dropdownTile(
                  context,
                  icon: Icons.access_time,
                  label: tr(context, 'Time Format'),
                  value: _timeFormat,
                  items: const {
                    '12h': '12-hour',
                    '24h': '24-hour',
                    'biblical': 'Biblical',
                  },
                  onChanged: (v) => setState(() => _timeFormat = v),
                ),
                const Divider(height: 1),
                _dropdownTile(
                  context,
                  icon: Icons.date_range_outlined,
                  label: tr(context, 'Date Format'),
                  value: _dateFormat,
                  items: const {
                    'DD/MM/YYYY': 'DD/MM/YYYY',
                    'MM/DD/YYYY': 'MM/DD/YYYY',
                    'YYYY-MM-DD': 'YYYY-MM-DD',
                  },
                  onChanged: (v) => setState(() => _dateFormat = v),
                ),
                if (widget.calendar.daysPerWeek == 7) ...[
                  const Divider(height: 1),
                  _dropdownTile(
                    context,
                    icon: Icons.view_week_outlined,
                    label: tr(context, 'Week starts on'),
                    value: _weekStartDay,
                    items: {for (final d in _weekdays) d: d},
                    onChanged: (v) => setState(() => _weekStartDay = v),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Structure (read-only summary) ────────────────────────
          _sectionTitle(context, tr(context, 'Structure')),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _summaryRow(context, tr(context, 'Days per week'),
                      '${widget.calendar.daysPerWeek}'),
                  _summaryRow(context, tr(context, 'Months per year'),
                      '${widget.calendar.monthsPerYear}'),
                  _summaryRow(context, tr(context, 'Total days per year'),
                      '${widget.calendar.monthLengths.fold<int>(0, (a, b) => a + b)}'),
                  const SizedBox(height: 6),
                  Text(
                    tr(context,
                        'To change month lengths or leap rules, duplicate this calendar and create a new one.'),
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Live year preview ────────────────────────────────────────────────

  /// Shows exactly which year number will appear for a few sample dates, so
  /// the offset is never a guess.
  Widget _yearPreview(BuildContext context, Color accent) {
    final preview = CalendarModel(
      id: widget.calendar.id,
      name: _nameController.text.isEmpty
          ? widget.calendar.name
          : _nameController.text,
      daysPerWeek: widget.calendar.daysPerWeek,
      dayNames: widget.calendar.dayNames,
      weeksPerMonth: widget.calendar.weeksPerMonth,
      monthsPerYear: widget.calendar.monthsPerYear,
      monthNames: widget.calendar.monthNames,
      yearStart: widget.calendar.yearStart,
      timeFormat: _timeFormat,
      dateFormat: _dateFormat,
      calendarType: widget.calendar.calendarType,
      yearStartMonth: widget.calendar.yearStartMonth,
      yearStartDay: widget.calendar.yearStartDay,
      leapYearRule: widget.calendar.leapYearRule,
      leapYearPattern: widget.calendar.leapYearPattern,
      monthLengths: widget.calendar.monthLengths,
      weekStartDay: _weekStartDay,
      yearOffset: _yearOffset,
      colorHex: _colorHex,
      emoji: _emojiController.text,
    );

    final now = DateTime.now();
    final samples = [
      now,
      DateTime(now.year + 1, 1, 1),
      DateTime(now.year - 1, 1, 1),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 13, color: accent),
              const SizedBox(width: 6),
              Text(
                tr(context, 'Preview'),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...samples.map((d) {
            final info = CalendarMath.getCalendarDateInfo(preview, d);
            final greg = '${d.day}/${d.month}/${d.year}';
            final own = '${info['day']}/${info['month']}/${info['year']}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      greg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward,
                      size: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Text(
                      own,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Small building blocks ──────────────────────────

  Widget _sectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      );

  /// Lets the user type a large offset instead of tapping dozens of times.
  Future<void> _editOffsetDirectly(BuildContext context) async {
    final controller = TextEditingController(text: '$_yearOffset');
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, 'Year offset')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: InputDecoration(
            helperText: tr(context, 'Offset = calendar year − Gregorian year'),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (text) =>
              Navigator.pop(dialogContext, int.tryParse(text.trim())),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(context, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
                dialogContext, int.tryParse(controller.text.trim())),
            child: Text(tr(context, 'Save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && mounted) setState(() => _yearOffset = value);
  }

  Widget _stepButton({
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Material(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _dropdownTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(label),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        isDense: true,
        items: items.entries
            .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    tr(context, e.value),
                    style: const TextStyle(fontSize: 13),
                  ),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      if (cleaned.length != 6) return const Color(0xFF8B82FF);
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFF8B82FF);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final c = widget.calendar;
    final updated = CalendarModel(
      id: c.id,
      name: name,
      daysPerWeek: c.daysPerWeek,
      dayNames: c.dayNames,
      weeksPerMonth: c.weeksPerMonth,
      monthsPerYear: c.monthsPerYear,
      monthNames: c.monthNames,
      yearStart: c.yearStart,
      timeFormat: _timeFormat,
      dateFormat: _dateFormat,
      calendarType: c.calendarType,
      yearStartMonth: c.yearStartMonth,
      yearStartDay: c.yearStartDay,
      leapYearRule: c.leapYearRule,
      leapYearPattern: c.leapYearPattern,
      monthLengths: c.monthLengths,
      weekStartDay: _weekStartDay,
      dayStartTime: c.dayStartTime,
      customDayStart: c.customDayStart,
      timezone: c.timezone,
      showSeconds: c.showSeconds,
      showMilliseconds: c.showMilliseconds,
      yearOffset: _yearOffset,
      colorHex: _colorHex,
      emoji: _emojiController.text.isEmpty ? c.emoji : _emojiController.text,
      specialDays: c.specialDays,
    );
    Provider.of<CalendarProvider>(context, listen: false)
        .updateCalendar(updated);
    Navigator.pop(context);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(tr(context, 'Calendar updated'))),
    );
  }
}
