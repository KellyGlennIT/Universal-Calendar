import 'package:flutter/material.dart';

/// A single scheduled event.
///
/// `date` is always `YYYY-MM-DD` (Gregorian storage format — display uses
/// `CalendarModel.dateFormat`). `time` is `HH:MM` 24-hour.
class CalendarEvent {
  final String id;
  String title;
  String date;
  String time;
  String notes;
  String calendarId;
  Color color;
  int? reminderMinutesBefore;

  /// Reminder tone ID (see `notification_sounds.dart`); `null` means the
  /// system default. Persisted so a reminder keeps its sound after a restart
  /// or a reboot-driven reschedule.
  String? reminderSound;
  bool isAllDay;
  int durationMinutes;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.notes,
    required this.calendarId,
    this.color = Colors.blue,
    this.reminderMinutesBefore,
    this.reminderSound,
    this.isAllDay = false,
    this.durationMinutes = 60,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'time': time,
        'notes': notes,
        'calendarId': calendarId,
        'color': color.toARGB32(),
        'reminderMinutesBefore': reminderMinutesBefore,
        'reminderSound': reminderSound,
        'isAllDay': isAllDay,
        'durationMinutes': durationMinutes,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'],
        title: json['title'],
        date: json['date'],
        time: json['time'],
        notes: json['notes'] ?? '',
        calendarId: json['calendarId'] ?? '',
        color: Color((json['color'] as int?) ?? Colors.blue.toARGB32()),
        reminderMinutesBefore: json['reminderMinutesBefore'] as int?,
        reminderSound: json['reminderSound'] as String?,
        isAllDay: json['isAllDay'] as bool? ?? (json['time'] == '00:00'),
        durationMinutes: (json['durationMinutes'] as int?) ?? 60,
      );
}