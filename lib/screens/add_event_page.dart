import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calendar_event.dart';
import '../models/calendar_model.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../services/notification_service.dart';
import '../utils/calendar_math.dart';
import '../l10n/tr.dart';

/// Create or edit a single event.
///
/// `eventToEdit == null` → new event; otherwise pre-fills the form for
/// editing the given event.
class AddEventPage extends StatefulWidget {
  final CalendarEvent? eventToEdit;
  const AddEventPage({super.key, this.eventToEdit});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late Color _selectedColor;
  late CalendarModel? _calendar;
  late String _timeFormat;
  bool _isAllDay = false;
  int? _reminderMinutesBefore;
  int _durationMinutes = 60;
  bool _saving = false;

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final e = widget.eventToEdit;
    if (e != null) {
      _selectedDate = CalendarMath.parseDate(e.date, 'YYYY-MM-DD');
      _selectedTime = TimeOfDay(
        hour: int.parse(e.time.split(':')[0]),
        minute: int.parse(e.time.split(':')[1]),
      );
      _selectedColor = e.color;
      _titleController.text = e.title;
      _notesController.text = e.notes;
      _isAllDay = e.isAllDay;
      _reminderMinutesBefore = e.reminderMinutesBefore;
      _durationMinutes = e.durationMinutes;
    } else {
      _selectedDate = provider.selectedDate;
      _selectedTime = TimeOfDay.now();
      _selectedColor = Colors.blue;
      _isAllDay = false;
    }
    _calendar = provider.selectedCalendar;
    _timeFormat = _calendar?.timeFormat ?? '24h';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final dateStr = CalendarMath.formatDate(_selectedDate, 'DD/MM/YYYY');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventToEdit == null
            ? tr(context, 'Add Event')
            : tr(context, 'Edit Event')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: tr(context, 'Event Title'),
                  prefixIcon: const Icon(Icons.title),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? tr(context, 'Enter a title')
                    : null,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Row(children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(dateStr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge)),
                        const Icon(Icons.arrow_drop_down,
                            color: Colors.grey),
                      ]),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr(context, 'All day')),
                      value: _isAllDay,
                      onChanged: (v) => setState(() => _isAllDay = v),
                    ),
                    if (!_isAllDay) ...[
                      const Divider(),
                      InkWell(
                        onTap: () => _selectTime(context),
                        child: Row(children: [
                          Icon(
                              _timeFormat == 'biblical'
                                  ? Icons.history
                                  : Icons.access_time,
                              color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_getFormattedTime(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge),
                                Text(_getTimeFormatLabel(),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.grey),
                        ]),
                      ),
                    ],
                  ]),
                ),
              ),
              if (!_isAllDay) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('duration_$_durationMinutes'),
                      initialValue: _durationMinutes,
                      decoration: InputDecoration(
                        labelText: tr(context, 'Duration'),
                        prefixIcon: const Icon(Icons.timelapse),
                        border: InputBorder.none,
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 15,
                            child: Text(tr(context, '15 min'))),
                        DropdownMenuItem(
                            value: 30,
                            child: Text(tr(context, '30 min'))),
                        DropdownMenuItem(
                            value: 45,
                            child: Text(tr(context, '45 min'))),
                        DropdownMenuItem(
                            value: 60,
                            child: Text(tr(context, '1 hour'))),
                        DropdownMenuItem(
                            value: 90,
                            child: Text(tr(context, '1.5 hours'))),
                        DropdownMenuItem(
                            value: 120,
                            child: Text(tr(context, '2 hours'))),
                        DropdownMenuItem(
                            value: 180,
                            child: Text(tr(context, '3 hours'))),
                      ],
                      onChanged: (v) =>
                          setState(() => _durationMinutes = v ?? 60),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey(
                        'reminder_${_reminderMinutesBefore ?? 'none'}'),
                    initialValue: _reminderMinutesBefore,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Reminder'),
                      prefixIcon: const Icon(
                          Icons.notifications_active_outlined),
                      border: InputBorder.none,
                    ),
                    items: <DropdownMenuItem<int?>>[
                      DropdownMenuItem(
                          value: null,
                          child: Text(tr(context, 'No reminder'))),
                      DropdownMenuItem(
                          value: 0,
                          child: Text(tr(context, 'At event time'))),
                      DropdownMenuItem(
                          value: 5,
                          child:
                              Text(tr(context, '5 minutes before'))),
                      DropdownMenuItem(
                          value: 10,
                          child:
                              Text(tr(context, '10 minutes before'))),
                      DropdownMenuItem(
                          value: 15,
                          child:
                              Text(tr(context, '15 minutes before'))),
                      DropdownMenuItem(
                          value: 30,
                          child:
                              Text(tr(context, '30 minutes before'))),
                      DropdownMenuItem(
                          value: 60,
                          child:
                              Text(tr(context, '1 hour before'))),
                      DropdownMenuItem(
                          value: 1440,
                          child: Text(tr(context, '1 day before'))),
                    ],
                    onChanged: (v) =>
                        setState(() => _reminderMinutesBefore = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0A0E17)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).brightness ==
                            Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(tr(context, 'Notes'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText:
                            tr(context, 'Add details or reminders...'),
                        hintStyle: const TextStyle(fontSize: 13),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(tr(context, 'Color'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((color) {
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: _selectedColor == color
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: _selectedColor == color
                            ? [
                                BoxShadow(
                                    color:
                                        color.withValues(alpha: 0.4),
                                    blurRadius: 8),
                              ]
                            : null,
                      ),
                      child: _selectedColor == color
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          widget.eventToEdit == null
                              ? tr(context, 'Save Event')
                              : tr(context, 'Update Event'),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFormattedTime() {
    final sunriseHour =
        Provider.of<CalendarProvider>(context, listen: false)
            .sunriseHour;
    if (_timeFormat == 'biblical') {
      return CalendarMath.getBiblicalTime(
          _selectedTime.hour, _selectedTime.minute,
          sunriseHour: sunriseHour);
    } else if (_timeFormat == '12h') {
      final ampm = _selectedTime.hour >= 12 ? 'PM' : 'AM';
      final h12 = _selectedTime.hour == 0
          ? 12
          : (_selectedTime.hour > 12
              ? _selectedTime.hour - 12
              : _selectedTime.hour);
      return '$h12:${_selectedTime.minute.toString().padLeft(2, '0')} $ampm';
    } else {
      return '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getTimeFormatLabel() {
    if (_timeFormat == 'biblical') {
      return tr(context, 'Biblical (sunrise-based)');
    }
    if (_timeFormat == '12h') return tr(context, '12-hour');
    return tr(context, '24-hour');
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    if (_timeFormat == 'biblical') {
      _showBiblicalTimePicker(context);
    } else {
      final picked = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: _timeFormat == '24h'),
          child: child!,
        ),
      );
      if (picked != null) setState(() => _selectedTime = picked);
    }
  }

  void _showBiblicalTimePicker(BuildContext context) {
    final sunriseHour =
        Provider.of<CalendarProvider>(context, listen: false)
            .sunriseHour;
    final sunsetHour = sunriseHour + 12;
    final labels = <String>[];
    final values = <int>[];
    for (int i = 0; i < 12; i++) {
      final startHour = sunriseHour + i;
      final endHour = (startHour + 1) % 24;
      labels.add(
          '${i + 1}${_ordinal(i + 1)} Hour (${_format12Hour(startHour)} - ${_format12Hour(endHour)})');
      values.add(startHour);
    }
    for (int i = 0; i < 12; i++) {
      final startHour = (sunsetHour + i) % 24;
      final endHour = (startHour + 1) % 24;
      labels.add(
          '${i + 1}${_ordinal(i + 1)} Hour of Night (${_format12Hour(startHour)} - ${_format12Hour(endHour)})');
      values.add(startHour);
    }
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(context, 'Select Biblical Time'),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: labels.length,
                itemBuilder: (context, index) => ListTile(
                  leading: Icon(
                      index < 12
                          ? Icons.wb_sunny
                          : Icons.nightlight_round,
                      size: 20),
                  title: Text(labels[index]),
                  onTap: () {
                    setState(() => _selectedTime =
                        TimeOfDay(hour: values[index], minute: 0));
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format12Hour(int hour24) {
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    final h12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    return '$h12 $ampm';
  }

  String _ordinal(int n) {
    if (n == 1) return 'st';
    if (n == 2) return 'nd';
    if (n == 3) return 'rd';
    return 'th';
  }

  Future<void> _saveEvent() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final provider =
        Provider.of<CalendarProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final dateStr = CalendarMath.formatDate(_selectedDate, 'YYYY-MM-DD');

    final event = CalendarEvent(
      id: widget.eventToEdit?.id ?? CalendarMath.generateId(),
      title: _titleController.text.trim(),
      date: dateStr,
      time: _isAllDay
          ? '00:00'
          : '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      notes: _notesController.text,
      calendarId: provider.selectedCalendarId.isNotEmpty
          ? provider.selectedCalendarId
          : (provider.calendars.isNotEmpty
              ? provider.calendars.first.id
              : ''),
      color: _selectedColor,
      reminderMinutesBefore: _reminderMinutesBefore,
      isAllDay: _isAllDay,
      durationMinutes: _durationMinutes,
    );

    var reminderDenied = false;
    if (_reminderMinutesBefore != null) {
      final granted =
          await CalendarNotificationService.requestPermission();
      reminderDenied = !granted;
    }
    if (widget.eventToEdit == null) {
      provider.addEvent(event);
    } else {
      provider.updateEvent(event);
    }
    if (!mounted) return;
    if (reminderDenied) {
      messenger.showSnackBar(SnackBar(
        content: Text(tr(context,
            'Reminder saved, but notifications are disabled. Enable them in Settings to receive it.')),
      ));
    }
    navigator.pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}