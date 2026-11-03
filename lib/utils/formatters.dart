import '../models/calendar_event.dart';

/// Returns the end time of [event] as `HH:MM` (24-hour).
///
/// Example: an event starting at `14:30` with `durationMinutes == 60` returns
/// `"15:30"`.
String formatEventEnd(CalendarEvent event) {
  final parts = event.time.split(':');
  final start = DateTime(
    2000,
    1,
    1,
    int.tryParse(parts[0]) ?? 0,
    parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
  );
  final end = start.add(Duration(minutes: event.durationMinutes));
  return '${end.hour.toString().padLeft(2, '0')}:'
      '${end.minute.toString().padLeft(2, '0')}';
}