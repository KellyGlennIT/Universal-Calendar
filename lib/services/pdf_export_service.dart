import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/calendar_model.dart';
import '../models/calendar_event.dart';
import '../models/special_day.dart';
import '../utils/calendar_math.dart';

class _MonthData {
  final int year;
  final int month;
  final String monthName;
  final DateTime firstDayGreg;
  final int daysInMonth;
  final List<String> monthNamesInYear;
  _MonthData({
    required this.year,
    required this.month,
    required this.monthName,
    required this.firstDayGreg,
    required this.daysInMonth,
    required this.monthNamesInYear,
  });
}

/// Produces a print-ready wall calendar: one landscape A4 sheet per month,
/// with a large month banner, a Sunday-first seven-column grid, weekend
/// shading, a highlighted "today", event chips inside their cells and a
/// notebook of that month's events beneath the grid.
class PdfExportService {
  static Future<Uint8List> generateCalendarPdf({
    required CalendarModel calendar,
    required List<CalendarEvent> allEvents,
    required int startYear,
    required int startMonth,
    required int endYear,
    required int endMonth,
    bool includeEvents = true,
    bool includeSpecialDays = true,
    bool includeCoverPage = true,
    String? localeCode,
  }) async {
    final doc = pw.Document(
      title: '${calendar.name} — ${_yearLabel(startYear, endYear)}',
      author: 'Universal Calendar',
      creator: 'Universal Calendar',
    );

    // A bundled Unicode font, so French accents and calendar month names in
    // non-Latin scripts are never dropped by the PDF's base-14 fonts.
    final theme = await _pdfTheme();

    final accent = _pdfColorFromHex(calendar.colorHex);
    const ink = PdfColor.fromInt(0xFF1C1F26);
    const softInk = PdfColor.fromInt(0xFF5A6070);
    const hairline = PdfColor.fromInt(0xFFDDE1E8);
    const weekendWash = PdfColor.fromInt(0xFFF4F6FA);

    final months = _computeMonthsInRange(
      calendar,
      startYear,
      startMonth,
      endYear,
      endMonth,
    );
    if (months.isEmpty) {
      throw StateError('No months in the selected range.');
    }

    if (includeCoverPage) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          theme: theme,
          build: (_) =>
              _coverPage(calendar, accent, ink, softInk, months.length),
        ),
      );
    }

    for (var i = 0; i < months.length; i++) {
      final month = months[i];
      final events = includeEvents
          ? _eventsForMonth(allEvents, calendar, month.year, month.month)
          : <CalendarEvent>[];
      final specials = includeSpecialDays
          ? calendar.specialDays.where((s) => s.month == month.month).toList()
          : <SpecialDay>[];

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 22),
          theme: theme,
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _banner(month, calendar, accent, ink, softInk),
              pw.SizedBox(height: 12),
              _weekdayRow(calendar, accent, ink, softInk),
              pw.SizedBox(height: 4),
              pw.Expanded(
                child: _grid(
                  calendar: calendar,
                  month: month,
                  events: events,
                  specials: specials,
                  accent: accent,
                  ink: ink,
                  softInk: softInk,
                  hairline: hairline,
                  weekendWash: weekendWash,
                ),
              ),
              pw.SizedBox(height: 10),
              _footer(
                calendar,
                month,
                i,
                months.length,
                accountEvents: includeEvents,
                accountSpecials: includeSpecialDays,
                ink: ink,
                softInk: softInk,
                hairline: hairline,
                accent: accent,
              ),
            ],
          ),
        ),
      );
    }

    return doc.save();
  }

  // ── Fonts ──────────────────────────────────────────────────────────

  /// Builds the document theme from the bundled Noto Sans pair.
  static Future<pw.ThemeData> _pdfTheme() async {
    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    return pw.ThemeData.withFont(base: regular, bold: bold);
  }

  // ── Cover ──────────────────────────────────────────────────────────

  static pw.Widget _coverPage(
    CalendarModel calendar,
    PdfColor accent,
    PdfColor ink,
    PdfColor softInk,
    int monthCount,
  ) {
    return pw.Container(
      color: accent,
      child: pw.Stack(
        children: [
          pw.Positioned(
            right: -140,
            top: -140,
            child: pw.Container(
              width: 520,
              height: 520,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.Positioned(
            left: -80,
            bottom: -120,
            child: pw.Container(
              width: 380,
              height: 380,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(70),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(30),
                    border: pw.Border.all(
                      color: PdfColor.fromInt(0xFFFFFFFF),
                      width: 0.8,
                    ),
                  ),
                  child: pw.Text(
                    'UNIVERSAL CALENDAR',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                pw.Text(
                  calendar.name.toUpperCase(),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 62,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(width: 70, height: 3, color: PdfColors.white),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      _descriptor(calendar, monthCount),
                      style: pw.TextStyle(
                        color: PdfColor.fromInt(0xFFFFFFFF),
                        fontSize: 11,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Month banner ───────────────────────────────────────────────────

  static pw.Widget _banner(
    _MonthData month,
    CalendarModel calendar,
    PdfColor accent,
    PdfColor ink,
    PdfColor softInk,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                month.monthName.toUpperCase(),
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  color: accent,
                  fontSize: 30,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                calendar.name,
                style: pw.TextStyle(
                  color: softInk,
                  fontSize: 9,
                  letterSpacing: 2.2,
                ),
              ),
            ],
          ),
        ),
        pw.Text(
          '${month.year}',
          style: pw.TextStyle(
            color: ink,
            fontSize: 44,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: -1.5,
          ),
        ),
      ],
    );
  }

  // ── Weekday header ─────────────────────────────────────────────────

  static pw.Widget _weekdayRow(
    CalendarModel calendar,
    PdfColor accent,
    PdfColor ink,
    PdfColor softInk,
  ) {
    final days = calendar.daysPerWeek.clamp(1, 14).toInt();
    final names = _weekdayLabels(calendar, days);
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom:
                pw.BorderSide(color: PdfColor.fromInt(0xFFDDE1E8), width: 0.7)),
      ),
      child: pw.Row(
        children: List.generate(days, (i) {
          final isWeekend = _isWeekend(calendar, i);
          return pw.Expanded(
            child: pw.Text(
              names[i].toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: isWeekend ? accent : softInk,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Grid ───────────────────────────────────────────────────────────

  static pw.Widget _grid({
    required CalendarModel calendar,
    required _MonthData month,
    required List<CalendarEvent> events,
    required List<SpecialDay> specials,
    required PdfColor accent,
    required PdfColor ink,
    required PdfColor softInk,
    required PdfColor hairline,
    required PdfColor weekendWash,
  }) {
    final days = calendar.daysPerWeek.clamp(1, 14).toInt();
    final startOffset =
        CalendarMath.getWeekStartOffset(calendar, month.firstDayGreg);
    final cellCount = startOffset + month.daysInMonth;
    final weeks = (cellCount / days).ceil();

    final eventsByDay = <int, List<CalendarEvent>>{};
    for (final e in events) {
      final d = CalendarMath.parseDate(e.date, 'YYYY-MM-DD');
      final info = CalendarMath.getCalendarDateInfo(calendar, d);
      eventsByDay.putIfAbsent(info['day'] as int, () => []).add(e);
    }
    final specialsByDay = <int, List<SpecialDay>>{};
    for (final s in specials) {
      specialsByDay.putIfAbsent(s.day, () => []).add(s);
    }

    final today = DateTime.now();
    final todayInfo = CalendarMath.getCalendarDateInfo(calendar, today);

    return pw.Column(
      children: List.generate(weeks, (w) {
        return pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: List.generate(days, (c) {
              final index = w * days + c;
              final dayNum = index - startOffset + 1;
              final isWeekend = _isWeekend(calendar, c);
              final inMonth = dayNum >= 1 && dayNum <= month.daysInMonth;

              if (!inMonth) {
                return pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: hairline, width: 0.4),
                      color: PdfColors.white,
                    ),
                  ),
                );
              }

              final isToday = todayInfo['year'] == month.year &&
                  todayInfo['month'] == month.month &&
                  todayInfo['day'] == dayNum;
              final dayEvents = eventsByDay[dayNum] ?? const [];
              final daySpecials = specialsByDay[dayNum] ?? const [];

              return pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(5, 3, 5, 3),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: hairline, width: 0.4),
                    color: isWeekend ? weekendWash : PdfColors.white,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 17,
                            height: 17,
                            alignment: pw.Alignment.center,
                            decoration: isToday
                                ? pw.BoxDecoration(
                                    shape: pw.BoxShape.circle,
                                    color: accent,
                                  )
                                : null,
                            child: pw.Text(
                              '$dayNum',
                              style: pw.TextStyle(
                                fontSize: isToday ? 9 : 10.5,
                                color: isToday ? PdfColors.white : ink,
                                fontWeight: isToday
                                    ? pw.FontWeight.bold
                                    : pw.FontWeight.normal,
                              ),
                            ),
                          ),
                          pw.Spacer(),
                          if (daySpecials.isNotEmpty)
                            pw.Container(
                              width: 5,
                              height: 5,
                              margin: const pw.EdgeInsets.only(top: 5),
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                color: _pdfColorFromHex(
                                    daySpecials.first.colorHex),
                              ),
                            ),
                        ],
                      ),
                      if (daySpecials.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 1),
                          child: pw.Text(
                            daySpecials.first.name,
                            maxLines: 1,
                            overflow: pw.TextOverflow.clip,
                            style: pw.TextStyle(
                              fontSize: 5.6,
                              color:
                                  _pdfColorFromHex(daySpecials.first.colorHex),
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      pw.SizedBox(height: 1.5),
                      ...dayEvents.take(3).map(
                            (e) => pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 1.2),
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 1),
                              decoration: pw.BoxDecoration(
                                color: _toLight(_colorOf(e, accent)),
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                              child: pw.Row(
                                children: [
                                  if (!e.isAllDay) ...[
                                    pw.Text(
                                      e.time,
                                      style: pw.TextStyle(
                                        fontSize: 4.8,
                                        color: _colorOf(e, accent),
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.SizedBox(width: 2),
                                  ],
                                  pw.Expanded(
                                    child: pw.Text(
                                      e.title,
                                      maxLines: 1,
                                      overflow: pw.TextOverflow.clip,
                                      style: pw.TextStyle(
                                        fontSize: 5.4,
                                        color: ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (dayEvents.length > 3)
                        pw.Text(
                          '+${dayEvents.length - 3}',
                          style: pw.TextStyle(
                            fontSize: 4.8,
                            color: softInk,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  // ── Footer / event notebook ────────────────────────────────────────

  static pw.Widget _footer(
    CalendarModel calendar,
    _MonthData month,
    int index,
    int total, {
    required bool accountEvents,
    required bool accountSpecials,
    required PdfColor ink,
    required PdfColor softInk,
    required PdfColor hairline,
    required PdfColor accent,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(height: 0.5, color: hairline),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            pw.Text(
              calendar.name,
              style: pw.TextStyle(
                fontSize: 7.5,
                color: softInk,
                letterSpacing: 1.6,
              ),
            ),
            pw.Spacer(),
            pw.Text(
              '${index + 1} / $total',
              style: pw.TextStyle(
                fontSize: 7.5,
                color: softInk,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Month discovery ────────────────────────────────────────────────

  static List<_MonthData> _computeMonthsInRange(
    CalendarModel calendar,
    int startYear,
    int startMonth,
    int endYear,
    int endMonth,
  ) {
    final result = <_MonthData>[];
    var year = startYear;
    var month = startMonth;
    var guard = 0;
    while (guard < 600) {
      guard++;
      if (year > endYear || (year == endYear && month > endMonth)) break;

      final names = CalendarMath.monthNamesForYear(calendar, year);
      final safeMonth = month.clamp(1, names.length);
      final start =
          CalendarMath.monthStartInCalendar(calendar, year, safeMonth);
      result.add(_MonthData(
        year: year,
        month: safeMonth,
        monthName: names[safeMonth - 1],
        firstDayGreg: start,
        daysInMonth:
            CalendarMath.getDaysInMonthForCalendar(calendar, year, safeMonth),
        monthNamesInYear: names,
      ));

      // Advance to the next month in this calendar's own numbering.
      month++;
      if (month > names.length) {
        month = 1;
        year++;
      }
    }
    return result;
  }

  static List<CalendarEvent> _eventsForMonth(
    List<CalendarEvent> allEvents,
    CalendarModel calendar,
    int year,
    int month,
  ) {
    final result = <CalendarEvent>[];
    for (final e in allEvents) {
      if (e.calendarId != calendar.id) continue;
      final info = CalendarMath.getCalendarDateInfo(
          calendar, CalendarMath.parseDate(e.date, 'YYYY-MM-DD'));
      if (info['year'] == year && info['month'] == month) result.add(e);
    }
    result.sort((a, b) {
      final da = CalendarMath.parseDate(a.date, 'YYYY-MM-DD');
      final db = CalendarMath.parseDate(b.date, 'YYYY-MM-DD');
      final byDate = da.compareTo(db);
      return byDate != 0 ? byDate : a.time.compareTo(b.time);
    });
    return result;
  }

  // ── Helpers ────────────────────────────────────────────────────────

  static bool _isWeekend(CalendarModel calendar, int column) {
    if (calendar.daysPerWeek != 7) return false;
    final labels = _weekdayLabels(calendar, 7);
    final name = labels[column].toLowerCase();
    return name.startsWith('sat') ||
        name.startsWith('sun') ||
        name.startsWith('sam') ||
        name.startsWith('dim') ||
        name.startsWith('sha') ||
        name.startsWith('shb');
  }

  static List<String> _weekdayLabels(CalendarModel calendar, int days) {
    if (calendar.calendarType == 'gregorian') {
      return CalendarMath.weekdayHeaders(calendar);
    }
    return CalendarMath.weekdayHeaders(calendar);
  }

  static PdfColor _colorOf(CalendarEvent event, PdfColor fallback) {
    final c = event.color;
    return PdfColor.fromInt(c.toARGB32());
  }

  static PdfColor _toLight(PdfColor color) => PdfColor(
        color.red * 0.12 + 1 * 0.88,
        color.green * 0.12 + 1 * 0.88,
        color.blue * 0.12 + 1 * 0.88,
      );

  static String _yearLabel(int startYear, int endYear) =>
      startYear == endYear ? '$startYear' : '$startYear – $endYear';

  static String _descriptor(CalendarModel calendar, int monthCount) {
    final weeks = calendar.daysPerWeek;
    return '$monthCount MONTHS  ·  $weeks-DAY WEEK  ·  WEEK BEGINS ${calendar.weekStartDay.toUpperCase()}';
  }

  static PdfColor _pdfColorFromHex(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      if (cleaned.length != 6) return PdfColor.fromInt(0xFF8B82FF);
      return PdfColor.fromInt(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return PdfColor.fromInt(0xFF8B82FF);
    }
  }
}
