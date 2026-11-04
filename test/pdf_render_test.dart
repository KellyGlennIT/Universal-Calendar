import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_calendar/models/calendar_event.dart';
import 'package:universal_calendar/services/pdf_export_service.dart';
import 'package:universal_calendar/utils/calendar_presets.dart';

void main() {
  testWidgets('generate wall calendar pdf', (tester) async {
    final cal = calendarFromPreset('gregorian');
    CalendarEvent ev(
            String id, String title, String date, String time, Color color,
            {String notes = '', bool allDay = false}) =>
        CalendarEvent(
          id: id,
          title: title,
          date: date,
          time: time,
          notes: notes,
          calendarId: cal.id,
          color: color,
          isAllDay: allDay,
        );

    final events = [
      ev('1', 'Rent due', '2026-11-01', '00:00', Colors.red, allDay: true),
      ev('2', 'Team stand-up', '2026-11-03', '09:00', Colors.blue,
          notes: 'Daily sync'),
      ev('3', 'Design review', '2026-11-05', '14:30', Colors.purple),
      ev('4', 'Church service', '2026-11-08', '10:00', Colors.teal),
      ev('5', 'Dentist', '2026-11-17', '11:15', Colors.orange),
      ev('6', 'Family dinner', '2026-11-28', '19:00', Colors.pink),
    ];

    final bytes = await PdfExportService.generateCalendarPdf(
      calendar: cal,
      allEvents: events,
      startYear: 2026,
      startMonth: 10,
      endYear: 2026,
      endMonth: 12,
      includeCoverPage: true,
    );
    Directory('build').createSync(recursive: true);
    File('build/sample_calendar.pdf').writeAsBytesSync(bytes);
    expect(bytes.length, greaterThan(2000));
    // A PDF always starts with %PDF-
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  }, timeout: const Timeout(Duration(seconds: 40)));
}
