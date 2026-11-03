import 'dart:typed_data';
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
  _MonthData({
    required this.year,
    required this.month,
    required this.monthName,
    required this.firstDayGreg,
  });
}

/// Generates an elegant, typography-first calendar PDF.
///
/// Design principles:
///   • No boxes, no cell borders — just numbers in a clean grid
///   • One serif (Times) for display, one sans (Helvetica) for labels
///   • Accent color drawn from the calendar itself
///   • Generous whitespace, restrained use of color
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
  }) async {
    final doc = pw.Document(
      title: '${calendar.name} Calendar',
      author: 'Universal Calendar',
      creator: 'Universal Calendar',
    );

    final accent = _pdfColorFromHex(calendar.colorHex);
    final textColor = PdfColor.fromHex('#1A1A1A');
    final softColor = PdfColor.fromHex('#555555');
    final mutedColor = PdfColor.fromHex('#999999');
    final lightColor = PdfColor.fromHex('#DDDDDD');
    final bgColor = PdfColors.white;

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

    // ── Cover page ────────────────────────────────────────────────────
    if (includeCoverPage) {
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(60),
        build: (pw.Context context) {
          return pw.Container(
            color: bgColor,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Spacer(flex: 3),
                pw.Container(width: 32, height: 2, color: accent),
                pw.SizedBox(height: 26),
                pw.Text(
                  'CALENDAR',
                  style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: 11,
                    color: mutedColor,
                    letterSpacing: 6,
                  ),
                ),
                pw.SizedBox(height: 22),
                pw.Text(
                  _yearLabel(startYear, endYear),
                  style: pw.TextStyle(
                    font: pw.Font.timesBold(),
                    fontSize: 120,
                    color: textColor,
                    height: 0.95,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  calendar.name,
                  style: pw.TextStyle(
                    font: pw.Font.timesItalic(),
                    fontSize: 28,
                    color: accent,
                  ),
                ),
                pw.Spacer(flex: 5),
                pw.Container(width: 90, height: 0.5, color: lightColor),
                pw.SizedBox(height: 14),
                pw.Text(
                  _footerDescriptor(calendar),
                  style: pw.TextStyle(
                    font: pw.Font.helvetica(),
                    fontSize: 8,
                    color: mutedColor,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 40),
              ],
            ),
          );
        },
      ));
    }

    // ── Month pages ───────────────────────────────────────────────────
    String pageLabel(int i) => includeCoverPage ? '${i + 2}' : '${i + 1}';

    for (int i = 0; i < months.length; i++) {
      final m = months[i];
      final monthEvents = includeEvents
          ? _eventsForMonth(allEvents, calendar, m.year, m.month)
          : <CalendarEvent>[];
      final monthSpecials = includeSpecialDays
          ? calendar.specialDays.where((s) => s.month == m.month).toList()
          : <SpecialDay>[];

      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(60, 60, 60, 44),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(width: 22, height: 1.5, color: accent),
              pw.SizedBox(height: 16),
              pw.Text(
                m.monthName.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  fontSize: 10,
                  color: mutedColor,
                  letterSpacing: 5,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                '${m.year}',
                style: pw.TextStyle(
                  font: pw.Font.timesBold(),
                  fontSize: 44,
                  color: textColor,
                  height: 1,
                ),
              ),
              pw.SizedBox(height: 28),
              _buildGrid(calendar, m, allEvents, monthSpecials,
                  accent, textColor, mutedColor),
              if (monthSpecials.isNotEmpty) ...[
                pw.SizedBox(height: 22),
                _buildSectionHeader('SPECIAL DAYS', mutedColor),
                pw.SizedBox(height: 8),
                _buildSpecialDays(monthSpecials, softColor, mutedColor),
              ],
              if (monthEvents.isNotEmpty) ...[
                pw.SizedBox(height: 22),
                _buildSectionHeader('EVENTS', mutedColor),
                pw.SizedBox(height: 8),
                _buildEventsList(monthEvents, softColor, mutedColor),
              ],
              pw.Spacer(),
              pw.Container(height: 0.5, color: lightColor),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    calendar.name,
                    style: pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: 8,
                      color: mutedColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.Text(
                    'PAGE ${pageLabel(i)}',
                    style: pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: 8,
                      color: mutedColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ));
    }

    return doc.save();
  }

  // ── Month discovery ────────────────────────────────────────────────

  static List<_MonthData> _computeMonthsInRange(
    CalendarModel calendar,
    int startYear,
    int startMonth,
    int endYear,
    int endMonth,
  ) {
    final approxStartGreg = startYear - calendar.yearOffset;
    final approxEndGreg = endYear - calendar.yearOffset;
    final bufferStart = DateTime(approxStartGreg - 1, 1, 1);
    final bufferEnd = DateTime(approxEndGreg + 2, 12, 31);

    final byKey = <String, _MonthData>{};
    var current = bufferStart;
    while (!current.isAfter(bufferEnd)) {
      final info = CalendarMath.getCalendarDateInfo(calendar, current);
      final cy = info['year'] as int;
      final cm = info['month'] as int;
      if (_inRange(cy, cm, startYear, startMonth, endYear, endMonth) &&
          info['day'] == 1) {
        final key = '$cy-$cm';
        byKey.putIfAbsent(
          key,
          () => _MonthData(
            year: cy,
            month: cm,
            monthName: calendar.fullMonthNames[(cm - 1)
                .clamp(0, calendar.fullMonthNames.length - 1)
                .toInt()],
            firstDayGreg: current,
          ),
        );
      }
      current = current.add(const Duration(days: 1));
    }

    final months = byKey.values.toList()
      ..sort((a, b) =>
          a.year != b.year ? a.year.compareTo(b.year) : a.month.compareTo(b.month));
    return months;
  }

  static bool _inRange(int y, int m, int sy, int sm, int ey, int em) {
    if (y < sy || y > ey) return false;
    if (y == sy && m < sm) return false;
    if (y == ey && m > em) return false;
    return true;
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
      final d = CalendarMath.parseDate(e.date, 'YYYY-MM-DD');
      final info = CalendarMath.getCalendarDateInfo(calendar, d);
      if (info['year'] == year && info['month'] == month) {
        result.add(e);
      }
    }
    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  // ── Grid ──────────────────────────────────────────────────────────

  static pw.Widget _buildGrid(
    CalendarModel calendar,
    _MonthData m,
    List<CalendarEvent> allEvents,
    List<SpecialDay> monthSpecials,
    PdfColor accent,
    PdfColor textColor,
    PdfColor mutedColor,
  ) {
    final daysInWeek = calendar.daysPerWeek.clamp(1, 14);
    final daysInMonth = CalendarMath.getDaysInMonthForCalendar(
        calendar, m.year, m.month);
    final startOffset = CalendarMath.getWeekStartOffset(calendar, m.firstDayGreg);

    final weekdayNames = _weekdayNames(calendar, daysInWeek);

    final Map<int, List<CalendarEvent>> eventsByDay = {};
    for (final e in _eventsForMonth(allEvents, calendar, m.year, m.month)) {
      final d = CalendarMath.parseDate(e.date, 'YYYY-MM-DD');
      final info = CalendarMath.getCalendarDateInfo(calendar, d);
      final day = info['day'] as int;
      eventsByDay.putIfAbsent(day, () => []).add(e);
    }
    final Map<int, List<SpecialDay>> specialsByDay = {};
    for (final s in monthSpecials) {
      specialsByDay.putIfAbsent(s.day, () => []).add(s);
    }

    final totalCells = startOffset + daysInMonth;
    final weekCount = (totalCells / daysInWeek).ceil();

    return pw.Table(
      columnWidths: {
        for (int i = 0; i < daysInWeek; i++) i: const pw.FlexColumnWidth(),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          children: weekdayNames.map((name) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(
              name.toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: pw.Font.helveticaBold(),
                fontSize: 7,
                color: mutedColor,
                letterSpacing: 1.5,
              ),
            ),
          )).toList(),
        ),
        for (int w = 0; w < weekCount; w++)
          pw.TableRow(
            children: List.generate(daysInWeek, (d) {
              final cellIdx = w * daysInWeek + d;
              final dayNum = cellIdx - startOffset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Text(
                    '·',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: 12,
                      color: mutedColor,
                    ),
                  ),
                );
              }
              final hasEvents = eventsByDay.containsKey(dayNum);
              final hasSpecial = specialsByDay.containsKey(dayNum);
              final specialColor = hasSpecial
                  ? _pdfColorFromHex(specialsByDay[dayNum]!.first.colorHex)
                  : null;

              final numberStyle = hasSpecial
                  ? pw.TextStyle(
                      font: pw.Font.timesItalic(),
                      fontSize: 13,
                      color: specialColor,
                      fontWeight: pw.FontWeight.bold,
                    )
                  : hasEvents
                      ? pw.TextStyle(
                          font: pw.Font.timesBold(),
                          fontSize: 13,
                          color: textColor,
                        )
                      : pw.TextStyle(
                          font: pw.Font.times(),
                          fontSize: 13,
                          color: textColor,
                        );

              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Text(
                  '$dayNum',
                  textAlign: pw.TextAlign.center,
                  style: numberStyle,
                ),
              );
            }),
          ),
      ],
    );
  }

  static List<String> _weekdayNames(CalendarModel calendar, int daysInWeek) {
    final names = calendar.shortDayNames;
    if (names.isEmpty) {
      return List.generate(daysInWeek, (i) => 'D${i + 1}');
    }
    final startIdx = calendar.dayNames.indexOf(calendar.weekStartDay);
    final s = startIdx < 0 ? 0 : startIdx;
    return List.generate(
        daysInWeek, (i) => names[(s + i) % names.length]);
  }

  // ── Sections ──────────────────────────────────────────────────────

  static pw.Widget _buildSectionHeader(String label, PdfColor mutedColor) {
    return pw.Text(
      label,
      style: pw.TextStyle(
        font: pw.Font.helveticaBold(),
        fontSize: 8,
        color: mutedColor,
        letterSpacing: 3,
      ),
    );
  }

  static pw.Widget _buildEventsList(
    List<CalendarEvent> events,
    PdfColor softColor,
    PdfColor mutedColor,
  ) {
    final display = events.take(10).toList();
    final remaining = events.length - display.length;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        ...display.map((e) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 7),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 44,
                    child: pw.Text(
                      e.isAllDay ? 'All day' : e.time,
                      style: pw.TextStyle(
                        font: pw.Font.helvetica(),
                        fontSize: 9,
                        color: mutedColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          e.title,
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontSize: 11,
                            color: softColor,
                          ),
                        ),
                        if (e.notes.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              e.notes,
                              maxLines: 2,
                              overflow: pw.TextOverflow.clip,
                              style: pw.TextStyle(
                                font: pw.Font.timesItalic(),
                                fontSize: 9,
                                color: mutedColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        if (remaining > 0)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              '+ $remaining more events',
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 8,
                color: mutedColor,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildSpecialDays(
    List<SpecialDay> specials,
    PdfColor softColor,
    PdfColor mutedColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: specials.map((s) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: pw.BoxDecoration(
                    color: _pdfColorFromHex(s.colorHex),
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        s.name,
                        style: pw.TextStyle(
                          font: pw.Font.times(),
                          fontSize: 11,
                          color: softColor,
                        ),
                      ),
                      pw.Text(
                        '${s.month}/${s.day}',
                        style: pw.TextStyle(
                          font: pw.Font.helvetica(),
                          fontSize: 8,
                          color: mutedColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  static String _yearLabel(int startYear, int endYear) {
    if (startYear == endYear) return '$startYear';
    return '$startYear–$endYear';
  }

  static String _footerDescriptor(CalendarModel calendar) {
    final week = calendar.weekStartDay;
    final months = calendar.monthsPerYear;
    return '$months MONTHS · WEEK BEGINS $week';
  }

  static PdfColor _pdfColorFromHex(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      if (cleaned.length != 6) return PdfColor.fromHex('#8B82FF');
      return PdfColor.fromHex('#$cleaned');
    } catch (_) {
      return PdfColor.fromHex('#8B82FF');
    }
  }
}