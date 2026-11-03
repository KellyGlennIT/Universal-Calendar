import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../models/calendar_model.dart';

/// Data-export helpers. Stateless — every method is a pure function of its
/// arguments. Returns strings ready for the clipboard or a file.
class ExportService {
  ExportService._();

  /// Builds a complete `.ics` (RFC 5545) file body for [calendar] and its
  /// [events]. Handles all-day events, reminders (VALARM), and text escaping.
  ///
  /// Save the returned string to a file ending in `.ics` and import it into
  /// Google Calendar, Apple Calendar, Outlook, or Thunderbird.
  static String generateIcs({
    required CalendarModel calendar,
    required List<CalendarEvent> events,
  }) {
    final buf = StringBuffer();
    buf.writeln('BEGIN:VCALENDAR');
    buf.writeln('VERSION:2.0');
    buf.writeln('PRODID:-//Universal Calendar//EN');
    buf.writeln('CALSCALE:GREGORIAN');
    buf.writeln('X-WR-CALNAME:${_esc(calendar.name)}');

    for (final event in events) {
      final dateParts = event.date.split('-').map(int.parse).toList();
      final timeParts = event.time.split(':').map(int.parse).toList();
      if (dateParts.length != 3 || timeParts.length < 2) continue;
      final start = DateTime(
          dateParts[0], dateParts[1], dateParts[2], timeParts[0], timeParts[1]);
      final end = start.add(Duration(minutes: event.durationMinutes));

      buf.writeln('BEGIN:VEVENT');
      buf.writeln('UID:${event.id}@universal_calendar');
      buf.writeln('DTSTAMP:${_icsDateTime(DateTime.now().toUtc())}');
      if (event.isAllDay) {
        buf.writeln('DTSTART;VALUE=DATE:${_icsDateOnly(start)}');
        buf.writeln('DTEND;VALUE=DATE:${_icsDateOnly(end)}');
      } else {
        buf.writeln('DTSTART:${_icsDateTime(start.toUtc())}');
        buf.writeln('DTEND:${_icsDateTime(end.toUtc())}');
      }
      buf.writeln('SUMMARY:${_esc(event.title)}');
      if (event.notes.isNotEmpty) {
        buf.writeln('DESCRIPTION:${_esc(event.notes)}');
      }
      if (event.reminderMinutesBefore != null &&
          event.reminderMinutesBefore! >= 0) {
        buf.writeln('BEGIN:VALARM');
        buf.writeln('TRIGGER:-PT${event.reminderMinutesBefore}M');
        buf.writeln('ACTION:DISPLAY');
        buf.writeln('DESCRIPTION:${_esc(event.title)}');
        buf.writeln('END:VALARM');
      }
      buf.writeln('END:VEVENT');
    }

    buf.writeln('END:VCALENDAR');
    return buf.toString();
  }

  /// Builds a CSV file body for [events]. Columns:
  /// `Date,Time,Duration (min),Title,Notes,All-day,Reminder (min)`.
  static String generateCsv(List<CalendarEvent> events) {
    final buf = StringBuffer();
    buf.writeln('Date,Time,Duration (min),Title,Notes,All-day,Reminder (min)');
    for (final e in events) {
      buf.writeln([
        e.date,
        e.time,
        e.durationMinutes.toString(),
        _csv(e.title),
        _csv(e.notes),
        e.isAllDay ? 'Yes' : 'No',
        e.reminderMinutesBefore?.toString() ?? '',
      ].join(','));
    }
    return buf.toString();
  }

  /// Escapes iCalendar-special characters per RFC 5545 §3.3.11.
  static String _esc(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '');

  /// Escapes a CSV field by quoting when it contains a comma, quote, or newline.
  static String _csv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _icsDateOnly(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}'
      '${dt.month.toString().padLeft(2, '0')}'
      '${dt.day.toString().padLeft(2, '0')}';

  static String _icsDateTime(DateTime dt) =>
      '${_icsDateOnly(dt)}'
      'T${dt.hour.toString().padLeft(2, '0')}'
      '${dt.minute.toString().padLeft(2, '0')}'
      '00Z';

  /// Converts a `Color` to `#RRGGBB` — used when persisting user-chosen
  /// calendar colors to JSON.
  static String colorToHex(Color c) {
    final argb = c.toARGB32();
    final rgb = argb & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}