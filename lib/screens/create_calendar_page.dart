import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calendar_model.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/calendar_math.dart';
import '../l10n/tr.dart';

class CreateCalendarPage extends StatefulWidget {
  const CreateCalendarPage({super.key});

  @override
  State<CreateCalendarPage> createState() => _CreateCalendarPageState();
}

class _CreateCalendarPageState extends State<CreateCalendarPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  bool _structureModified = false;

  String _template = 'gregorian';
  final _nameController = TextEditingController();
  Color _selectedColor = const Color(0xFF8B82FF);
  String _selectedEmoji = '📅';

  final _daysPerWeekController = TextEditingController(text: '7');
  final _weeksPerMonthController = TextEditingController(text: '4');
  final _monthsPerYearController = TextEditingController(text: '12');
  final _yearStartMonthController = TextEditingController(text: '1');
  final _yearStartDayController = TextEditingController(text: '1');
  final _leapYearPatternController = TextEditingController();
  String _leapYearRule = 'gregorian';
  String _weekStartDay = 'Monday';
  int _yearOffset = 0;
  List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  List<int> _monthLengths = [
    31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
  ];
  bool _monthsExpanded = false;

  String _timeFormat = '24h';
  String _dateFormat = 'DD/MM/YYYY';
  String _timezone = 'UTC+0';
  bool _showSeconds = false;
  bool _showMilliseconds = false;
  bool _showAdvanced = false;

  static const _colorChoices = <Color>[
    Color(0xFF8B82FF),
    Color(0xFF63C7C2),
    Color(0xFFFF6B6B),
    Color(0xFFFFA94D),
    Color(0xFF51CF66),
    Color(0xFF4DABF7),
    Color(0xFFF783AC),
    Color(0xFFFFD43B),
  ];
  static const _emojiChoices = <String>[
    '📅', '🗓️', '⛪', '🌍', '✡️', '☪️', '✝️', '🌿', '📖', '⭐', '🌙', '🔔',
  ];

  @override
  void initState() {
    super.initState();
    _applyTemplate('gregorian');
    _nameController.text = 'Gregorian';
  }

  String _calendarTypeForTemplate(String template) {
    switch (template) {
      case 'gregorian':
        return 'gregorian';
      case 'ethiopian':
        return 'ethiopian';
      case 'biblical':
        return 'biblical';
      case 'julian':
        return 'julian';
      case 'islamic':
        return 'islamic';
      case 'coptic':
        return 'coptic';
      case 'french_republican':
        return 'french_republican';
      default:
        return 'user';
    }
  }

  void _updateMonthLengths() {
    final months =
        (int.tryParse(_monthsPerYearController.text) ?? 12)
            .clamp(1, 20)
            .toInt();
    while (_monthNames.length < months) {
      _monthNames.add('Month ${_monthNames.length + 1}');
    }
    if (_monthNames.length > months) {
      _monthNames = _monthNames.take(months).toList();
    }
    while (_monthLengths.length < months) {
      _monthLengths.add(30);
    }
    if (_monthLengths.length > months) {
      _monthLengths = _monthLengths.take(months).toList();
    }
  }

  void _applyTemplate(String template) {
    switch (template) {
      case 'gregorian':
        _daysPerWeekController.text = '7';
        _weeksPerMonthController.text = '4';
        _monthsPerYearController.text = '12';
        _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        _monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        _monthLengths = [
          31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
        ];
        _timeFormat = '24h';
        _dateFormat = 'DD/MM/YYYY';
        _leapYearRule = 'gregorian';
        _weekStartDay = 'Monday';
        _yearStartMonthController.text = '1';
        _yearStartDayController.text = '1';
        _yearOffset = 0;
        break;
      case 'julian':
        _daysPerWeekController.text = '7';
        _weeksPerMonthController.text = '4';
        _monthsPerYearController.text = '12';
        _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        _monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        _monthLengths = [
          31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
        ];
        _timeFormat = '24h';
        _dateFormat = 'DD/MM/YYYY';
        _leapYearRule = 'every4';
        _weekStartDay = 'Monday';
        _yearStartMonthController.text = '1';
        _yearStartDayController.text = '1';
        _yearOffset = 0;
        break;
      case 'ethiopian':
        _daysPerWeekController.text = '7';
        _weeksPerMonthController.text = '4';
        _monthsPerYearController.text = '13';
        _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        _monthNames = [
          'Meskerem', 'Tikimt', 'Hedar', 'Tahsas', 'Tir', 'Yekatit',
          'Megabit', 'Miazia', 'Genbot', 'Sene', 'Hamle', 'Nehase',
          'Pagume',
        ];
        _monthLengths = [
          30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 5,
        ];
        _timeFormat = '12h';
        _dateFormat = 'DD/MM/YYYY';
        _leapYearRule = 'every4';
        _weekStartDay = 'Monday';
        _yearStartMonthController.text = '1';
        _yearStartDayController.text = '1';
        _yearOffset = -8;
        break;
      case 'coptic':
        _daysPerWeekController.text = '7';
        _weeksPerMonthController.text = '4';
        _monthsPerYearController.text = '13';
        _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        _monthNames = [
          'Thout', 'Paopi', 'Hathor', 'Koiak', 'Tobi', 'Meshir',
          'Paremhat', 'Paremoude', 'Pashons', 'Paoni', 'Epip', 'Mesori',
          'Pi Kogi Enavot',
        ];
        _monthLengths = [
          30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 5,
        ];
        _timeFormat = '12h';
        _dateFormat = 'DD/MM/YYYY';
        _leapYearRule = 'every4';
        _weekStartDay = 'Monday';
        _yearStartMonthController.text = '1';
        _yearStartDayController.text = '1';
        _yearOffset = -284;
        break;
      case 'biblical':
        _daysPerWeekController.text = '7';
        _weeksPerMonthController.text = '4';
        _monthsPerYearController.text = '12';
        _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        _monthNames = [
          'Tishri', 'Cheshvan', 'Kislev', 'Tevet', 'Shevat', 'Adar',
          'Nisan', 'Iyar', 'Sivan', 'Tammuz', 'Av', 'Elul',
        ];
        _monthLengths = [
          30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29,
        ];
        _timeFormat = 'biblical';
        _dateFormat = 'DD/MM/YYYY';
        _leapYearRule = 'custom';
        _leapYearPatternController.text = '3,6,8,11,14,17,19';
        _weekStartDay = 'Sunday';
        _yearStartMonthController.text = '7';
        _yearStartDayController.text = '1';
        _yearOffset = 0;
        break;
      case 'islamic':
        _daysPerWeekController.text = '7';
        _weeksPerMonthController.text = '4';
        _monthsPerYearController.text = '12';
        _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        _monthNames = [
          'Muharram', 'Safar', 'Rabi I', 'Rabi II', 'Jumada I',
          'Jumada II', 'Rajab', "Sha'ban", 'Ramadan', 'Shawwal',
          "Dhu al-Q'dah", 'Dhu al-Hijjah',
        ];
        _monthLengths = [
          30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29,
        ];
        _timeFormat = '12h';
        _dateFormat = 'DD/MM/YYYY';
        _leapYearRule = 'custom';
        _leapYearPatternController.text = '2,5,7,10,13,16,18,21,24,26,29';
        _weekStartDay = 'Sunday';
        _yearStartMonthController.text = '1';
        _yearStartDayController.text = '1';
        _yearOffset = -579;
        break;
      case 'french_republican':
        _daysPerWeekController.text = '10';
        _weeksPerMonthController.text = '3';
        _monthsPerYearController.text = '12';
        _dayNames = [
          'Primidi', 'Duodi', 'Tridi', 'Quartidi', 'Quintidi',
          'Sextidi', 'Septidi', 'Octidi', 'Nonidi', 'Décadi',
        ];
        _monthNames = [
          'Vendémiaire', 'Brumaire', 'Frimaire', 'Nivôse', 'Pluviôse',
          'Ventôse', 'Germinal', 'Floréal', 'Prairial', 'Messidor',
          'Thermidor', 'Fructidor',
        ];
        _monthLengths = [30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30];
        _timeFormat = '24h';
        _dateFormat = 'DD/MM/YYYY';
        _leapYearRule = 'gregorian';
        _weekStartDay = 'Primidi';
        _yearStartMonthController.text = '9';
        _yearStartDayController.text = '22';
        _yearOffset = -1791;
        break;
      default:
        _daysPerWeekController.text = '7';
        _weeksPerMonthController.text = '4';
        _monthsPerYearController.text = '12';
        _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        _monthNames = List.generate(12, (i) => 'Month ${i + 1}');
        _monthLengths = List<int>.filled(12, 30);
        _timeFormat = '24h';
        _dateFormat = 'DD/MM/YYYY';
        _leapYearRule = 'none';
        _weekStartDay = 'Monday';
        _yearStartMonthController.text = '1';
        _yearStartDayController.text = '1';
        _yearOffset = 0;
        break;
    }
    _structureModified = false;
    _updateMonthLengths();
  }

  void _distributeMonthLengths() {
    final months = _monthNames.length;
    final totalDays =
        (int.tryParse(_daysPerWeekController.text) ?? 7) *
            (int.tryParse(_weeksPerMonthController.text) ?? 4) *
            months;
    final base = totalDays ~/ months;
    final remainder = totalDays % months;
    setState(() {
      _structureModified = true;
      _monthLengths = List<int>.generate(
          months, (i) => base + (i < remainder ? 1 : 0));
    });
  }

  Widget _buildPreview() {
    final dayCount =
        (int.tryParse(_daysPerWeekController.text) ?? 7).clamp(1, 14).toInt();
    final totalDays = _monthLengths.fold(0, (a, b) => a + b);
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _selectedColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _selectedColor.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Text(_selectedEmoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nameController.text.isEmpty
                    ? tr(context, 'Unnamed')
                    : _nameController.text,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$dayCount ${tr(context, 'days/week')} · '
                '${_monthNames.length} ${tr(context, 'months/year')} · '
                '$totalDays ${tr(context, 'days')}',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildStep1() {
    const templates = <(String, String, IconData)>[
      ('gregorian', 'Gregorian', Icons.calendar_today),
      ('julian', 'Julian', Icons.history_edu),
      ('ethiopian', 'Ethiopian', Icons.public),
      ('coptic', 'Coptic', Icons.church),
      ('biblical', 'Biblical', Icons.menu_book),
      ('islamic', 'Islamic', Icons.nightlight_round),
      ('french_republican', 'French Republican', Icons.auto_awesome),
      ('none', 'Custom', Icons.build),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(context, 'Choose a starting template'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
            tr(context,
                'Select a predefined calendar structure or start from scratch.'),
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: templates.map((t) {
            final selected = _template == t.$1;
            return _TemplateCard(
              title: t.$2,
              icon: t.$3,
              selected: selected,
              onTap: () => setState(() {
                _template = t.$1;
                _applyTemplate(t.$1);
                if (_nameController.text.isEmpty ||
                    _nameController.text == 'Gregorian') {
                  _nameController.text = t.$1 == 'none' ? '' : t.$2;
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(tr(context, 'Name your calendar'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: tr(context, 'Calendar Name'),
            prefixIcon: const Icon(Icons.title),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v?.trim().isEmpty ?? true)
              ? tr(context, 'Enter a title')
              : null,
        ),
        const SizedBox(height: 20),
        Text(tr(context, 'Color & Icon'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _colorChoices.map((c) {
            final selected =
                _selectedColor.toARGB32() == c.toARGB32();
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: c.withValues(alpha: 0.5),
                              blurRadius: 10),
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _emojiChoices.map((e) {
            final selected = _selectedEmoji == e;
            return GestureDetector(
              onTap: () => setState(() => _selectedEmoji = e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? _selectedColor.withValues(alpha: 0.20)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? _selectedColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
        _buildPreview(),
      ],
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, 'Year Structure'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _daysPerWeekController,
                decoration: InputDecoration(
                    labelText: tr(context, 'Days per week')),
                keyboardType: TextInputType.number,
                onChanged: (value) => setState(() {
                  _structureModified = true;
                  final count =
                      (int.tryParse(value) ?? 7).clamp(1, 14).toInt();
                  while (_dayNames.length < count) {
                    _dayNames.add('Day ${_dayNames.length + 1}');
                  }
                  if (_dayNames.length > count) {
                    _dayNames = _dayNames.take(count).toList();
                  }
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _weeksPerMonthController,
                decoration: InputDecoration(
                    labelText: tr(context, 'Weeks per month')),
                keyboardType: TextInputType.number,
                onChanged: (_) =>
                    setState(() => _structureModified = true),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _yearStartMonthController,
                decoration: const InputDecoration(
                    labelText: 'Start Month (1–12)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 1 || n > 12
                      ? 'Use 1–12'
                      : null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _yearStartDayController,
                decoration: const InputDecoration(
                    labelText: 'Start Day (1–31)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final day = int.tryParse(v ?? '');
                  final month =
                      int.tryParse(_yearStartMonthController.text);
                  if (day == null ||
                      month == null ||
                      month < 1 ||
                      month > 12 ||
                      day < 1 ||
                      day > 31) {
                    return 'Invalid date';
                  }
                  final maxDay = DateTime(2000, month + 1, 0).day;
                  return day > maxDay
                      ? 'Max $maxDay for this month'
                      : null;
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('leap_$_leapYearRule'),
            initialValue: _leapYearRule,
            decoration:
                InputDecoration(labelText: tr(context, 'Leap Year Rule')),
            items: [
              DropdownMenuItem(
                  value: 'none',
                  child: Text(tr(context, 'No leap years'))),
              DropdownMenuItem(
                  value: 'every4',
                  child: Text(tr(context, 'Every 4 years'))),
              DropdownMenuItem(
                  value: 'gregorian',
                  child: Text(tr(context,
                      'Gregorian (every 4 except century)'))),
              DropdownMenuItem(
                  value: 'custom',
                  child: Text(tr(context, 'Custom pattern'))),
            ],
            onChanged: (v) => setState(() {
              _leapYearRule = v!;
              _structureModified = true;
            }),
          ),
          if (_leapYearRule == 'custom') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _leapYearPatternController,
              decoration: const InputDecoration(
                labelText:
                    'Leap Years (comma-separated positions in cycle)',
                hintText: 'e.g., 3,6,8,11,14,17,19',
              ),
              onChanged: (_) => _structureModified = true,
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _monthsPerYearController,
                decoration: const InputDecoration(
                  labelText: 'Months per Year',
                  prefixIcon: Icon(Icons.view_list),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {
                  _structureModified = true;
                  _updateMonthLengths();
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: '$_yearOffset',
                decoration: const InputDecoration(
                  labelText: 'Year Offset',
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType:
                    TextInputType.numberWithOptions(signed: true),
                onChanged: (value) => setState(() {
                  _yearOffset = int.tryParse(value) ?? 0;
                  _structureModified = true;
                }),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Text(tr(context, 'Weekday names'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._dayNames.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  key: ValueKey(
                      'wd_${entry.key}_${_dayNames.length}'),
                  initialValue: entry.value,
                  decoration: InputDecoration(
                    labelText: 'Day ${entry.key + 1}',
                    prefixIcon: const Icon(Icons.today),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    _dayNames[entry.key] = value;
                    _structureModified = true;
                  },
                ),
              )),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(
                'weekstart_${_dayNames.length}_$_weekStartDay'),
            initialValue: _dayNames.contains(_weekStartDay)
                ? _weekStartDay
                : (_dayNames.isNotEmpty ? _dayNames.first : null),
            decoration:
                const InputDecoration(labelText: 'Week starts on'),
            items: _dayNames
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() {
              _weekStartDay = v ?? _weekStartDay;
              _structureModified = true;
            }),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: ExpansionTile(
              initiallyExpanded: _monthsExpanded,
              onExpansionChanged: (v) =>
                  setState(() => _monthsExpanded = v),
              title: Text(tr(context, 'Months & Days'),
                  style:
                      const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${_monthNames.length} ${tr(context, 'months/year')} · '
                  '${_monthLengths.fold(0, (a, b) => a + b)} ${tr(context, 'days')}',
                  style: const TextStyle(fontSize: 12)),
              children: [
                ..._monthNames.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(children: [
                        SizedBox(
                          width: 24,
                          child: Text('${e.key + 1}.',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: e.value,
                            decoration: const InputDecoration(
                                labelText: 'Name', isDense: true),
                            onChanged: (v) {
                              _monthNames[e.key] = v;
                              _structureModified = true;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20),
                              onPressed: () => setState(() {
                                if (_monthLengths[e.key] > 1) {
                                  _monthLengths[e.key]--;
                                }
                                _structureModified = true;
                              }),
                            ),
                            SizedBox(
                              width: 28,
                              child: Text('${_monthLengths[e.key]}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 20),
                              onPressed: () => setState(() {
                                if (_monthLengths[e.key] < 60) {
                                  _monthLengths[e.key]++;
                                }
                                _structureModified = true;
                              }),
                            ),
                          ],
                        ),
                      ]),
                    )),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 8, top: 4),
                  child: TextButton.icon(
                    onPressed: _distributeMonthLengths,
                    icon: const Icon(Icons.balance),
                    label: Text(tr(context, 'Distribute evenly')),
                  ),
                ),
              ],
            ),
          ),
          _buildPreview(),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(context, 'Time & Finish'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: ValueKey('timeformat_$_timeFormat'),
          initialValue: _timeFormat,
          decoration:
              InputDecoration(labelText: tr(context, 'Time Format')),
          items: [
            DropdownMenuItem(
                value: '12h', child: Text(tr(context, '12-hour'))),
            DropdownMenuItem(
                value: '24h', child: Text(tr(context, '24-hour'))),
            DropdownMenuItem(
                value: 'biblical',
                child: Text(tr(context, 'Biblical (sunrise-based)'))),
          ],
          onChanged: (v) => setState(() => _timeFormat = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('dateformat_$_dateFormat'),
          initialValue: _dateFormat,
          decoration:
              InputDecoration(labelText: tr(context, 'Date Format')),
          items: [
            DropdownMenuItem(
                value: 'DD/MM/YYYY',
                child: Text(tr(context, 'DD/MM/YYYY'))),
            DropdownMenuItem(
                value: 'MM/DD/YYYY',
                child: Text(tr(context, 'MM/DD/YYYY'))),
            DropdownMenuItem(
                value: 'YYYY-MM-DD',
                child: Text(tr(context, 'YYYY-MM-DD'))),
          ],
          onChanged: (v) => setState(() => _dateFormat = v!),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr(context, 'Show Advanced Options')),
          value: _showAdvanced,
          onChanged: (v) => setState(() => _showAdvanced = v),
        ),
        if (_showAdvanced) ...[
          Row(children: [
            Checkbox(
                value: _showSeconds,
                onChanged: (v) =>
                    setState(() => _showSeconds = v ?? false)),
            Text(tr(context, 'Show seconds')),
          ]),
          Row(children: [
            Checkbox(
                value: _showMilliseconds,
                onChanged: (v) => setState(
                    () => _showMilliseconds = v ?? false)),
            Text(tr(context, 'Show milliseconds')),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Timezone (e.g., UTC+1)',
              hintText: 'UTC+0',
            ),
            initialValue: 'UTC+0',
            onChanged: (v) => setState(() => _timezone = v),
          ),
        ],
        const SizedBox(height: 20),
        _buildPreview(),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(context, 'Review & Create'),
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _summaryRow(
                    tr(context, 'Name:'),
                    _nameController.text.isEmpty
                        ? tr(context, 'Unnamed')
                        : _nameController.text),
                _summaryRow(tr(context, 'Template:'), _template),
                _summaryRow(
                    tr(context, 'Months:'), '${_monthNames.length}'),
                _summaryRow(tr(context, 'Days per week:'),
                    '${_dayNames.length}'),
                _summaryRow(tr(context, 'Total days per year:'),
                    '${_monthLengths.fold(0, (a, b) => a + b)}'),
                _summaryRow(
                    tr(context, 'Time format:'), _timeFormat),
                _summaryRow(
                    tr(context, 'Date format:'), _dateFormat),
                _summaryRow(
                    tr(context, 'Year offset:'), '$_yearOffset'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 6),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 12))),
        ]),
      );

  List<Widget> _buildSteps() =>
      [_buildStep1(), _buildStep2(), _buildStep3()];

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final steps = _buildSteps();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Create Calendar')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / steps.length,
            backgroundColor: Colors.grey.shade800,
            valueColor:
                AlwaysStoppedAnimation(Theme.of(context).primaryColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              Text(
                '${tr(context, 'Step')} ${_currentStep + 1} ${tr(context, 'of')} 3',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: steps[_currentStep],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _currentStep--),
                      child: Text(tr(context, 'Back')),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < steps.length - 1) {
                        if (_currentStep == 0 &&
                            _nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    tr(context, 'Enter a title'))),
                          );
                          return;
                        }
                        if (_currentStep == 1 &&
                            !(_formKey.currentState?.validate() ??
                                true)) {
                          return;
                        }
                        setState(() => _currentStep++);
                      } else {
                        _createCalendar();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _currentStep == steps.length - 1
                          ? tr(context, 'Finish')
                          : tr(context, 'Next'),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _colorToHex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _createCalendar() {
    // Day boundaries are always midnight in the current engine, so the
    // wizard no longer exposes a Day Start control that would mislead users
    // into thinking the calendar honours sunset/sunrise day starts.
    final newCal = CalendarModel(
      id: CalendarMath.generateId(),
      name: _nameController.text.trim().isEmpty
          ? 'Unnamed Calendar'
          : _nameController.text.trim(),
      daysPerWeek:
          (int.tryParse(_daysPerWeekController.text) ?? 7)
              .clamp(1, 14)
              .toInt(),
      dayNames: List<String>.from(_dayNames),
      weeksPerMonth:
          (int.tryParse(_weeksPerMonthController.text) ?? 4)
              .clamp(1, 100)
              .toInt(),
      monthsPerYear: _monthNames.length,
      monthNames: List<String>.from(_monthNames),
      yearStart: CalendarMath.formatDate(DateTime.now(), 'YYYY-MM-DD'),
      timeFormat: _timeFormat,
      dateFormat: _dateFormat,
      calendarType:
          _structureModified ? 'user' : _calendarTypeForTemplate(_template),
      yearStartMonth:
          int.tryParse(_yearStartMonthController.text) ?? 1,
      yearStartDay: int.tryParse(_yearStartDayController.text) ?? 1,
      leapYearRule: _leapYearRule,
      leapYearPattern: _leapYearPatternController.text,
      monthLengths: List<int>.from(_monthLengths),
      weekStartDay: _weekStartDay,
      dayStartTime: 'midnight',
      customDayStart: '',
      timezone: _timezone,
      showSeconds: _showSeconds,
      showMilliseconds: _showMilliseconds,
      yearOffset: _yearOffset,
      colorHex: _colorToHex(_selectedColor),
      emoji: _selectedEmoji,
    );
    Provider.of<CalendarProvider>(context, listen: false)
        .addCalendar(newCal);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _daysPerWeekController.dispose();
    _weeksPerMonthController.dispose();
    _monthsPerYearController.dispose();
    _yearStartMonthController.dispose();
    _yearStartDayController.dispose();
    _leapYearPatternController.dispose();
    super.dispose();
  }
}

class _TemplateCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
          : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 36,
                color: selected
                    ? Theme.of(context).primaryColor
                    : Colors.grey),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}