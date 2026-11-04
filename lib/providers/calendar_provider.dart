import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar_model.dart';
import '../models/calendar_event.dart';
import '../models/special_day.dart';
import '../services/notification_service.dart';
import '../utils/calendar_math.dart';
import '../utils/calendar_presets.dart';

/// Central state for calendars, events, and user preferences.
class CalendarProvider extends ChangeNotifier {
  List<CalendarModel> _calendars = [];
  List<CalendarEvent> _events = [];
  String _selectedCalendarId = '';
  DateTime _selectedDate = DateTime.now();
  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;
  bool _isLoading = false;
  String? _error;
  DateTime _anchorDate = DateTime.now();
  String _primaryCalendarId = '';
  String? _secondaryCalendarId;
  String? _globalTimeFormat;
  bool _showSeconds = false;
  bool _showDayNight = true;
  int _sunriseHour = 6;
  String _defaultReminderSound = 'default';

  // ── Auto-cleanup ───────────────────────────────────────────────────
  int? _autoCleanupDays;

  List<CalendarModel> get calendars => _calendars;
  List<CalendarEvent> get events => _events;
  String get selectedCalendarId => _selectedCalendarId;
  DateTime get selectedDate => _selectedDate;
  int get currentYear => _currentYear;
  int get currentMonth => _currentMonth;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get anchorDate => _anchorDate;
  String get primaryCalendarId => _primaryCalendarId;
  String? get secondaryCalendarId => _secondaryCalendarId;
  String? get globalTimeFormat => _globalTimeFormat;
  bool get showSeconds => _showSeconds;
  bool get showDayNight => _showDayNight;
  int get sunriseHour => _sunriseHour;
  String get defaultReminderSound => _defaultReminderSound;

  // ── Auto-cleanup getter ────────────────────────────────────────────
  int? get autoCleanupDays => _autoCleanupDays;

  CalendarModel? get selectedCalendar {
    for (final c in _calendars) {
      if (c.id == _selectedCalendarId) return c;
    }
    return _calendars.isNotEmpty ? _calendars.first : null;
  }

  // ── Multi-day aware: events covering the currently selected date ───
  List<CalendarEvent> get eventsForSelectedDate {
    final day = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    return _events.where((e) {
      if (_selectedCalendarId.isNotEmpty &&
          e.calendarId != _selectedCalendarId) {
        return false;
      }
      return _spansDay(e, day);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  // ── Multi-day aware: events covering any given date ────────────────
  List<CalendarEvent> eventsForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _events.where((e) {
      if (_selectedCalendarId.isNotEmpty &&
          e.calendarId != _selectedCalendarId) {
        return false;
      }
      return _spansDay(e, day);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  /// True if [e]'s span (date..endDate) includes [day].
  /// Returns false on unparsable data — never throws.
  bool _spansDay(CalendarEvent e, DateTime day) {
    try {
      final startParts = e.date.split('-').map(int.parse).toList();
      if (startParts.length != 3) return false;
      final start =
          DateTime(startParts[0], startParts[1], startParts[2]);
      final endStr =
          (e.endDate == null || e.endDate!.isEmpty) ? e.date : e.endDate!;
      final endParts = endStr.split('-').map(int.parse).toList();
      if (endParts.length != 3) return false;
      final end = DateTime(endParts[0], endParts[1], endParts[2]);
      return !day.isBefore(start) && !day.isAfter(end);
    } catch (_) {
      return false;
    }
  }

  List<CalendarEvent> eventsForCalendar(String calendarId) =>
      _events.where((e) => e.calendarId == calendarId).toList();

  CalendarEvent? findEventById(String id) {
    for (final e in _events) {
      if (e.id == id) return e;
    }
    return null;
  }

  CalendarProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final calendarsJson = prefs.getString('calendars');
      if (calendarsJson != null) {
        _calendars = (json.decode(calendarsJson) as List)
            .map((e) => CalendarModel.fromJson(e))
            .toList();
        _migrateWeekStart();
      } else {
        _loadDefaultCalendars();
      }
      final eventsJson = prefs.getString('events');
      if (eventsJson != null) {
        _events = (json.decode(eventsJson) as List)
            .map((e) => CalendarEvent.fromJson(e))
            .toList();
      }
      _primaryCalendarId = prefs.getString('primary_calendar_id') ?? '';
      _secondaryCalendarId = prefs.getString('secondary_calendar_id');
      _globalTimeFormat = prefs.getString('global_time_format');
      _showSeconds = prefs.getBool('show_seconds') ?? false;
      _showDayNight = prefs.getBool('show_day_night') ?? true;
      _sunriseHour = prefs.getInt('sunrise_hour') ?? 6;
      _defaultReminderSound =
          prefs.getString('default_reminder_sound') ?? 'default';
      // ── Auto-cleanup setting ──
      _autoCleanupDays = prefs.getInt('auto_cleanup_days');
      if (_primaryCalendarId.isNotEmpty &&
          _calendars.any((c) => c.id == _primaryCalendarId)) {
        _selectedCalendarId = _primaryCalendarId;
      } else if (_calendars.isNotEmpty) {
        _selectedCalendarId = _calendars.first.id;
      }
      _anchorDate = DateTime.now();
      _selectedDate = _anchorDate;
      _recalculateCurrentMonthYear();
      for (final event in _events) {
        unawaited(CalendarNotificationService.scheduleEvent(event));
      }
    } catch (e) {
      debugPrint('Load error: $e');
      _error = 'Failed to load data. Using defaults.';
      _loadDefaultCalendars();
    }
    _isLoading = false;
    notifyListeners();

    // ── Run auto-cleanup once on startup (fire-and-forget) ──
    if (_autoCleanupDays != null) {
      unawaited(runAutoCleanupIfEnabled());
    }
  }

  /// One-time migration: Gregorian calendars used to start the week on
  /// Monday. They now follow the familiar Sunday-first layout, so saved
  /// calendars are flipped unless the user had chosen another start day.
  void _migrateWeekStart() {
    for (final cal in _calendars) {
      if (cal.calendarType == 'gregorian' && cal.weekStartDay == 'Monday') {
        cal.weekStartDay = 'Sunday';
      }
    }
  }

  void _loadDefaultCalendars() {
    _calendars = [
      CalendarModel(
        id: CalendarMath.generateId(),
        name: 'Gregorian',
        daysPerWeek: 7,
        dayNames: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        weeksPerMonth: 4,
        monthsPerYear: 12,
        monthNames: const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ],
        yearStart: CalendarMath.formatDate(DateTime.now(), 'YYYY-MM-DD'),
        timeFormat: '24h',
        dateFormat: 'DD/MM/YYYY',
        calendarType: 'gregorian',
        weekStartDay: 'Sunday',
        monthLengths: const [
          31,
          28,
          31,
          30,
          31,
          30,
          31,
          31,
          30,
          31,
          30,
          31,
        ],
        yearOffset: 0,
        colorHex: '#4DABF7',
        emoji: '📅',
      ),
      CalendarModel(
        id: CalendarMath.generateId(),
        name: 'Ethiopian',
        daysPerWeek: 7,
        dayNames: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        weeksPerMonth: 4,
        monthsPerYear: 13,
        monthNames: const [
          'Meskerem',
          'Tikimt',
          'Hedar',
          'Tahsas',
          'Tir',
          'Yekatit',
          'Megabit',
          'Miazia',
          'Genbot',
          'Sene',
          'Hamle',
          'Nehase',
          'Pagume',
        ],
        yearStart: CalendarMath.formatDate(
            DateTime(DateTime.now().year, 9, 11), 'YYYY-MM-DD'),
        timeFormat: '12h',
        dateFormat: 'DD/MM/YYYY',
        calendarType: 'ethiopian',
        weekStartDay: 'Sunday',
        monthLengths: const [
          30,
          30,
          30,
          30,
          30,
          30,
          30,
          30,
          30,
          30,
          30,
          30,
          5,
        ],
        yearOffset: -8,
        colorHex: '#51CF66',
        emoji: '🌍',
      ),
      CalendarModel(
        id: CalendarMath.generateId(),
        name: 'Biblical',
        daysPerWeek: 7,
        dayNames: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        weeksPerMonth: 4,
        monthsPerYear: 12,
        monthNames: const [
          'Tishri',
          'Cheshvan',
          'Kislev',
          'Tevet',
          'Shevat',
          'Adar',
          'Nisan',
          'Iyar',
          'Sivan',
          'Tammuz',
          'Av',
          'Elul',
        ],
        yearStart: CalendarMath.formatDate(
            DateTime(DateTime.now().year, 9, 16), 'YYYY-MM-DD'),
        timeFormat: 'biblical',
        dateFormat: 'DD/MM/YYYY',
        calendarType: 'biblical',
        weekStartDay: 'Sunday',
        monthLengths: const [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29],
        yearOffset: 0,
        colorHex: '#D4AF37',
        emoji: '✡️',
      ),
    ];
    if (_selectedCalendarId.isEmpty && _calendars.isNotEmpty) {
      _selectedCalendarId = _calendars.first.id;
    }
    _anchorDate = DateTime.now();
    _selectedDate = _anchorDate;
    _recalculateCurrentMonthYear();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'calendars', json.encode(_calendars.map((e) => e.toJson()).toList()));
      await prefs.setString(
          'events', json.encode(_events.map((e) => e.toJson()).toList()));
      await prefs.setString('primary_calendar_id', _primaryCalendarId);
      if (_secondaryCalendarId == null) {
        await prefs.remove('secondary_calendar_id');
      } else {
        await prefs.setString('secondary_calendar_id', _secondaryCalendarId!);
      }
      if (_globalTimeFormat == null) {
        await prefs.remove('global_time_format');
      } else {
        await prefs.setString('global_time_format', _globalTimeFormat!);
      }
      await prefs.setBool('show_seconds', _showSeconds);
      await prefs.setBool('show_day_night', _showDayNight);
      await prefs.setInt('sunrise_hour', _sunriseHour);
      await prefs.setString('default_reminder_sound', _defaultReminderSound);
      // ── Auto-cleanup setting ──
      if (_autoCleanupDays == null) {
        await prefs.remove('auto_cleanup_days');
      } else {
        await prefs.setInt('auto_cleanup_days', _autoCleanupDays!);
      }
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  void _recalculateCurrentMonthYear() {
    final cal = selectedCalendar;
    if (cal == null) return;
    final dateInfo = CalendarMath.getCalendarDateInfo(cal, _anchorDate);
    _currentYear = dateInfo['year'] as int;
    _currentMonth = dateInfo['month'] as int;
    _selectedDate = _anchorDate;
  }

  // ── Calendar CRUD ────────────────────────────────────────────────────

  void addCalendar(CalendarModel cal) {
    _calendars.add(cal);
    _saveData();
    notifyListeners();
  }

  /// Creates a calendar from a preset key (e.g. 'julian', 'islamic') and
  /// adds it to the list. If a calendar with the same name already exists,
  /// appends a number ("Julian 2", "Julian 3", etc.).
  ///
  /// Returns the created calendar, or null if [type] is not a known preset.
  CalendarModel? addPresetCalendar(String type) {
    if (!calendarPresets.containsKey(type)) return null;

    // Pick a unique name so the UI never shows two "Julian" entries.
    final baseName = calendarPresets[type]!.name;
    var name = baseName;
    var counter = 2;
    while (_calendars.any((c) => c.name == name)) {
      name = '$baseName $counter';
      counter++;
    }

    final cal = calendarFromPreset(type, customName: name);
    _calendars.add(cal);
    _saveData();
    notifyListeners();
    return cal;
  }

  void updateCalendar(CalendarModel cal) {
    final idx = _calendars.indexWhere((c) => c.id == cal.id);
    if (idx != -1) {
      _calendars[idx] = cal;
      _saveData();
      notifyListeners();
    }
  }

  void deleteCalendar(String id) {
    if (_calendars.length <= 1) return;
    _calendars.removeWhere((c) => c.id == id);
    final removed = _events.where((e) => e.calendarId == id).toList();
    for (final e in removed) {
      unawaited(CalendarNotificationService.cancelEvent(e.id));
    }
    _events.removeWhere((e) => e.calendarId == id);
    if (_selectedCalendarId == id) _selectedCalendarId = _calendars.first.id;
    if (_primaryCalendarId == id) _primaryCalendarId = _calendars.first.id;
    if (_secondaryCalendarId == id) _secondaryCalendarId = null;
    _recalculateCurrentMonthYear();
    _saveData();
    notifyListeners();
  }

  /// Replaces the special days for [calendarId]. Used by SpecialDaysPage.
  void setSpecialDays(String calendarId, List<SpecialDay> days) {
    final idx = _calendars.indexWhere((c) => c.id == calendarId);
    if (idx == -1) return;
    _calendars[idx].specialDays = days;
    _saveData();
    notifyListeners();
  }

  void duplicateCalendar(String sourceId) {
    final idx = _calendars.indexWhere((c) => c.id == sourceId);
    if (idx == -1) return;
    final source = _calendars[idx];
    _calendars.add(CalendarModel(
      id: CalendarMath.generateId(),
      name: '${source.name} (copy)',
      daysPerWeek: source.daysPerWeek,
      dayNames: List<String>.from(source.dayNames),
      weeksPerMonth: source.weeksPerMonth,
      monthsPerYear: source.monthsPerYear,
      monthNames: List<String>.from(source.monthNames),
      yearStart: source.yearStart,
      timeFormat: source.timeFormat,
      dateFormat: source.dateFormat,
      calendarType: source.calendarType,
      yearStartMonth: source.yearStartMonth,
      yearStartDay: source.yearStartDay,
      leapYearRule: source.leapYearRule,
      leapYearPattern: source.leapYearPattern,
      monthLengths: List<int>.from(source.monthLengths),
      weekStartDay: source.weekStartDay,
      dayStartTime: source.dayStartTime,
      customDayStart: source.customDayStart,
      timezone: source.timezone,
      showSeconds: source.showSeconds,
      showMilliseconds: source.showMilliseconds,
      yearOffset: source.yearOffset,
      colorHex: source.colorHex,
      emoji: source.emoji,
      specialDays: source.specialDays.map((s) => s.copy()).toList(),
    ));
    _saveData();
    notifyListeners();
  }

  // ── Selection ────────────────────────────────────────────────────────

  void selectCalendar(String id) {
    if (_selectedCalendarId == id) return;
    _selectedCalendarId = id;
    _recalculateCurrentMonthYear();
    notifyListeners();
  }

  void selectDate(DateTime date) {
    if (_selectedDate == date) return;
    _selectedDate = date;
    _anchorDate = date;
    _recalculateCurrentMonthYear();
    notifyListeners();
  }

  void changeMonth(int delta) {
    final cal = selectedCalendar;
    if (cal == null || delta == 0) return;
    final currentInfo = CalendarMath.getCalendarDateInfo(cal, _anchorDate);
    final originalDay = currentInfo['day'] as int;
    var monthStart = _anchorDate.subtract(Duration(days: originalDay - 1));
    final direction = delta > 0 ? 1 : -1;
    for (var step = 0; step < delta.abs(); step++) {
      final info = CalendarMath.getCalendarDateInfo(cal, monthStart);
      if (direction > 0) {
        final length = CalendarMath.getDaysInMonthForCalendar(
            cal, info['year'] as int, info['month'] as int);
        monthStart = monthStart.add(Duration(days: length));
      } else {
        final prevDay = monthStart.subtract(const Duration(days: 1));
        final prevInfo = CalendarMath.getCalendarDateInfo(cal, prevDay);
        final prevLength = CalendarMath.getDaysInMonthForCalendar(
            cal, prevInfo['year'] as int, prevInfo['month'] as int);
        monthStart = monthStart.subtract(Duration(days: prevLength));
      }
    }
    final targetInfo = CalendarMath.getCalendarDateInfo(cal, monthStart);
    final targetLength = CalendarMath.getDaysInMonthForCalendar(
        cal, targetInfo['year'] as int, targetInfo['month'] as int);
    final targetDay = originalDay.clamp(1, targetLength).toInt();
    _anchorDate = monthStart.add(Duration(days: targetDay - 1));
    _selectedDate = _anchorDate;
    _recalculateCurrentMonthYear();
    notifyListeners();
  }

  void goToToday() {
    _anchorDate = DateTime.now();
    _selectedDate = _anchorDate;
    _recalculateCurrentMonthYear();
    notifyListeners();
  }

  // ── Event CRUD ───────────────────────────────────────────────────────

  void addEvent(CalendarEvent event) {
    _events.add(event);
    unawaited(CalendarNotificationService.scheduleEvent(event));
    _saveData();
    notifyListeners();
  }

  void updateEvent(CalendarEvent updatedEvent) {
    final idx = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (idx != -1) {
      _events[idx] = updatedEvent;
      unawaited(CalendarNotificationService.scheduleEvent(updatedEvent));
      _saveData();
      notifyListeners();
    }
  }

  void deleteEvent(String id) {
    _events.removeWhere((e) => e.id == id);
    unawaited(CalendarNotificationService.cancelEvent(id));
    _saveData();
    notifyListeners();
  }

  void rescheduleReminders() {
    for (final event in _events) {
      if (event.reminderMinutesBefore != null) {
        unawaited(CalendarNotificationService.scheduleEvent(event));
      }
    }
  }

  // ── Auto-cleanup of old events ───────────────────────────────────────

  /// Deletes every event whose final day (endDate or date) is strictly
  /// earlier than [days] before today. Returns the number of events removed.
  ///
  /// Cancels any pending notifications for removed events.
  Future<int> deleteEventsOlderThan(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffStr = '${cutoff.year.toString().padLeft(4, '0')}-'
        '${cutoff.month.toString().padLeft(2, '0')}-'
        '${cutoff.day.toString().padLeft(2, '0')}';

    final toRemove = _events.where((e) {
      final endStr =
          (e.endDate == null || e.endDate!.isEmpty) ? e.date : e.endDate!;
      return endStr.compareTo(cutoffStr) < 0;
    }).toList();

    if (toRemove.isEmpty) return 0;

    final ids = toRemove.map((e) => e.id).toSet();
    _events.removeWhere((e) => ids.contains(e.id));

    for (final id in ids) {
      try {
        await CalendarNotificationService.cancelEvent(id);
      } catch (_) {}
    }

    await _saveData();
    notifyListeners();
    return toRemove.length;
  }

  /// Sets the auto-cleanup threshold (in days). Pass `null` for "Never".
  /// If a non-null value is passed, immediately runs cleanup once.
  Future<void> setAutoCleanupDays(int? days) async {
    _autoCleanupDays = days;
    await _saveData();
    notifyListeners();
    if (days != null) {
      await deleteEventsOlderThan(days);
    }
  }

  /// Runs auto-cleanup using the saved setting. Called once on startup
  /// when an auto-cleanup value is stored. Safe to call any time.
  Future<void> runAutoCleanupIfEnabled() async {
    if (_autoCleanupDays == null) return;
    await deleteEventsOlderThan(_autoCleanupDays!);
  }

  // ── Settings ─────────────────────────────────────────────────────────

  Future<void> setPrimaryCalendar(String id) async {
    _primaryCalendarId = id;
    if (id.isNotEmpty) {
      _selectedCalendarId = id;
      _recalculateCurrentMonthYear();
    }
    _saveData();
    notifyListeners();
  }

  Future<void> setSecondaryCalendar(String? id) async {
    _secondaryCalendarId = id;
    _saveData();
    notifyListeners();
  }

  Future<void> setGlobalTimeFormat(String? format) async {
    _globalTimeFormat = format;
    _saveData();
    notifyListeners();
  }

  Future<void> setShowSeconds(bool value) async {
    _showSeconds = value;
    _saveData();
    notifyListeners();
  }

  Future<void> setShowDayNight(bool value) async {
    _showDayNight = value;
    _saveData();
    notifyListeners();
  }

  Future<void> setSunriseHour(int hour) async {
    _sunriseHour = hour;
    _saveData();
    notifyListeners();
  }

  Future<void> setDefaultReminderSound(String toneId) async {
    _defaultReminderSound = toneId;
    _saveData();
    notifyListeners();
  }

  String getEffectiveTimeFormat(CalendarModel cal) =>
      _globalTimeFormat ?? cal.timeFormat;

  // ── Reset / backup / restore ─────────────────────────────────────────

  Future<void> resetAllData() async {
    await CalendarNotificationService.cancelAll();
    _events.clear();
    _calendars.clear();
    _loadDefaultCalendars();
    _primaryCalendarId = _calendars.first.id;
    _secondaryCalendarId = null;
    _selectedCalendarId = _primaryCalendarId;
    await _saveData();
    notifyListeners();
  }

  Map<String, dynamic> getBackupPayload() => {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'calendars': _calendars.map((c) => c.toJson()).toList(),
        'events': _events.map((e) => e.toJson()).toList(),
        'settings': {
          'primary_calendar_id': _primaryCalendarId,
          'secondary_calendar_id': _secondaryCalendarId,
          'global_time_format': _globalTimeFormat,
          'show_seconds': _showSeconds,
          'show_day_night': _showDayNight,
          'sunrise_hour': _sunriseHour,
          'default_reminder_sound': _defaultReminderSound,
          'auto_cleanup_days': _autoCleanupDays,
        },
      };

  Future<bool> restoreFromBackup(Map<String, dynamic> payload) async {
    try {
      final calendarsRaw = payload['calendars'];
      final eventsRaw = payload['events'];
      if (calendarsRaw is! List || eventsRaw is! List) return false;
      if (calendarsRaw.isEmpty) return false;

      final newCalendars = calendarsRaw
          .map((e) =>
              CalendarModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final newEvents = eventsRaw
          .map((e) =>
              CalendarEvent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final settings = payload['settings'];
      final settingsMap = settings is Map
          ? Map<String, dynamic>.from(settings)
          : <String, dynamic>{};

      await CalendarNotificationService.cancelAll();

      _calendars = newCalendars;
      _events = newEvents;
      _primaryCalendarId =
          (settingsMap['primary_calendar_id'] as String?) ?? '';
      _secondaryCalendarId = settingsMap['secondary_calendar_id'] as String?;
      _globalTimeFormat = settingsMap['global_time_format'] as String?;
      _showSeconds = (settingsMap['show_seconds'] as bool?) ?? false;
      _showDayNight = (settingsMap['show_day_night'] as bool?) ?? true;
      _sunriseHour = (settingsMap['sunrise_hour'] as int?) ?? 6;
      _defaultReminderSound =
          (settingsMap['default_reminder_sound'] as String?) ?? 'default';
      _autoCleanupDays = settingsMap['auto_cleanup_days'] as int?;

      if (_primaryCalendarId.isEmpty ||
          !_calendars.any((c) => c.id == _primaryCalendarId)) {
        _primaryCalendarId = _calendars.first.id;
      }
      _selectedCalendarId = _primaryCalendarId;
      _anchorDate = DateTime.now();
      _selectedDate = _anchorDate;
      _recalculateCurrentMonthYear();

      for (final e in _events) {
        if (e.reminderMinutesBefore != null) {
          unawaited(CalendarNotificationService.scheduleEvent(e));
        }
      }

      await _saveData();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }
}