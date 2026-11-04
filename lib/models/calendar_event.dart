import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  String title;
  String date;
  String time;
  String notes;
  String calendarId;
  Color color;
  int? reminderMinutesBefore;

  /// `YYYY-MM-DD` end-of-span. `null` or equal to [date] means single-day.
  String? endDate;

  String? reminderSound;
  bool isAllDay;
  int durationMinutes;

  bool alarmStyle;
  String repeatMode;
  DateTime? repeatUntil;

  /// When true, the reminder fires 5 times: at T, T+30s, T+60s, T+90s,
  /// T+120s. Gives the user 2 minutes of reminders so a single miss doesn't
  /// hide the event. Only applies to one-shot events (repeatMode == 'once').
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
    this.alarmStyle = false,
    this.repeatMode = 'once',
    this.repeatUntil,
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
      alarmStyle: json['alarmStyle'] as bool? ?? false,
      repeatMode: mode,
      repeatUntil: rawUntil is String ? DateTime.tryParse(rawUntil) : null,
      escalatingReminder: json['escalatingReminder'] as bool? ?? false,
    );
  }
}