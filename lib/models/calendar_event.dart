import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  String title;
  String date;
  String time;
  String notes;
  String calendarId;
  Color color;

  /// Number of minutes before the event start time when the alarm should ring.
  /// If null, no alarm is set for this event.
  /// e.g. 0 = at event time, 15 = 15 minutes before, etc.
  int? reminderMinutesBefore;

  /// Convenience alias for alarm time offset in minutes before event.
  int? get alarmMinutesBefore => reminderMinutesBefore;
  set alarmMinutesBefore(int? value) => reminderMinutesBefore = value;

  /// Has an alarm scheduled?
  bool get hasAlarm => reminderMinutesBefore != null;

  /// `YYYY-MM-DD` end-of-span. `null` or equal to [date] means single-day.
  String? endDate;

  /// Sound/tone ID to play continuously when the alarm rings.
  String? reminderSound;
  String? get alarmSound => reminderSound;
  set alarmSound(String? value) => reminderSound = value;

  bool isAllDay;
  int durationMinutes;

  /// Alarm style: whether volume is enforced and screen turns on when ringing.
  bool alarmStyle;

  /// Repeat mode: 'once', 'daily', or 'weekly'.
  String repeatMode;
  DateTime? repeatUntil;

  /// Snooze duration in minutes for this event's alarm (default 5 minutes).
  int snoozeMinutes;

  /// Kept for backwards-compatible JSON migration.
  bool escalatingReminder;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.notes,
    required this.calendarId,
    this.color = Colors.blue,
    this.reminderMinutesBefore,
    this.endDate,
    this.reminderSound,
    this.isAllDay = false,
    this.durationMinutes = 60,
    this.alarmStyle = true,
    this.repeatMode = 'once',
    this.repeatUntil,
    this.snoozeMinutes = 5,
    this.escalatingReminder = false,
  });

  bool get isMultiDay {
    if (endDate == null || endDate!.isEmpty) return false;
    return endDate != date;
  }

  Map toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'time': time,
        'notes': notes,
        'calendarId': calendarId,
        'color': color.toARGB32(),
        'reminderMinutesBefore': reminderMinutesBefore,
        'endDate': endDate,
        'reminderSound': reminderSound,
        'isAllDay': isAllDay,
        'durationMinutes': durationMinutes,
        'alarmStyle': alarmStyle,
        'repeatMode': repeatMode,
        'repeatUntil': repeatUntil?.toIso8601String(),
        'snoozeMinutes': snoozeMinutes,
        'escalatingReminder': escalatingReminder,
      };

  factory CalendarEvent.fromJson(Map json) {
    final rawMode = json['repeatMode'] as String?;
    final mode =
        (rawMode == 'daily' || rawMode == 'weekly') ? rawMode! : 'once';
    final rawUntil = json['repeatUntil'];
    final rawEnd = json['endDate'] as String?;
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      date: json['date'],
      time: json['time'],
      notes: json['notes'] ?? '',
      calendarId: json['calendarId'] ?? '',
      color: Color((json['color'] as int?) ?? Colors.blue.toARGB32()),
      reminderMinutesBefore: json['reminderMinutesBefore'] as int?,
      endDate: (rawEnd == null || rawEnd.isEmpty) ? null : rawEnd,
      reminderSound: json['reminderSound'] as String?,
      isAllDay: json['isAllDay'] as bool? ?? (json['time'] == '00:00'),
      durationMinutes: (json['durationMinutes'] as int?) ?? 60,
      alarmStyle: json['alarmStyle'] as bool? ?? true,
      repeatMode: mode,
      repeatUntil: rawUntil is String ? DateTime.tryParse(rawUntil) : null,
      snoozeMinutes: (json['snoozeMinutes'] as int?) ?? 5,
      escalatingReminder: json['escalatingReminder'] as bool? ?? false,
    );
  }
}
