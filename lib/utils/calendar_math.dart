import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/calendar_model.dart';

/// The core calendar engine.
///
/// All methods are static — this is a pure utility class, never instantiated.
/// Handles six built-in calendar systems plus arbitrary user-defined ones:
///
///   • Gregorian          — the international civil calendar
///   • Ethiopian          — 13 months, leap year when year % 4 == 3
///   • Biblical (Hebrew)  — 12 or 13 months, 19-year Metonic cycle
///   • Julian             — pre-1582 Roman calendar (13 days behind Gregorian)
///   • Coptic             — 13-month liturgical calendar
///   • Islamic (Hijri)    — 12 lunar months, 30-year arithmetic cycle
///   • French Republican  — 12 months of 30 + 5/6 complementary days
///   • Custom (`user`)    — arbitrary month structure + leap rules
///
/// Renamed from `DateUtils` to avoid the collision with the `DateUtils`
/// class exported by `package:flutter/material.dart`.
class CalendarMath {
  static const _uuid = Uuid();

  /// Generates a fresh UUID v4 — used as event and calendar IDs.
  static String generateId() => _uuid.v4();

  /// Extracts the hour from an event's `time` field. Handles both plain
  /// `HH:MM` and legacy biblical-hour strings (`"3rd hour"`, `"1st watch"`).
  static int getHourFromTimeString(String timeStr) {
    if (timeStr.contains(':')) {
      final parts = timeStr.split(':');
      if (parts.isNotEmpty) return int.tryParse(parts[0]) ?? 0;
    }
    final lower = timeStr.toLowerCase();
    if (lower.contains('1st hour')) return 6;
    if (lower.contains('2nd hour')) return 7;
    if (lower.contains('3rd hour')) return 8;
    if (lower.contains('4th hour')) return 9;
    if (lower.contains('5th hour')) return 10;
    if (lower.contains('6th hour') && !lower.contains('3 pm')) return 11;
    if (lower.contains('7th hour')) return 12;
    if (lower.contains('8th hour')) return 13;
    if (lower.contains('9th hour')) return 14;
    if (lower.contains('10th hour')) return 15;
    if (lower.contains('11th hour')) return 16;
    if (lower.contains('12th hour')) return 17;
    if (lower.contains('1st watch')) return 18;
    if (lower.contains('2nd watch')) return 21;
    if (lower.contains('3rd watch')) return 23;
    if (lower.contains('4th watch')) return 2;
    if (lower.contains('morning watch') || lower.contains('sunrise')) return 5;
    final match = RegExp(r'\d+').firstMatch(timeStr);
    return match != null ? (int.tryParse(match.group(0)!) ?? 0) : 0;
  }

  /// Formats a `DateTime` using one of the calendar's own date formats.
  static String formatDate(DateTime date, String format) {
    switch (format) {
      case 'DD/MM/YYYY':
        return DateFormat('dd/MM/yyyy').format(date);
      case 'MM/DD/YYYY':
        return DateFormat('MM/dd/yyyy').format(date);
      case 'YYYY-MM-DD':
        return DateFormat('yyyy-MM-dd').format(date);
      default:
        return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  /// Parses a date string in one of the calendar's own formats.
  /// Returns [DateTime.now] on failure so callers never crash on bad data.
  static DateTime parseDate(String dateStr, String format) {
    try {
      switch (format) {
        case 'DD/MM/YYYY':
          return DateFormat('dd/MM/yyyy').parse(dateStr);
        case 'MM/DD/YYYY':
          return DateFormat('MM/dd/yyyy').parse(dateStr);
        case 'YYYY-MM-DD':
          return DateFormat('yyyy-MM-dd').parse(dateStr);
        default:
          return DateTime.parse(dateStr);
      }
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Days in a Gregorian month. Uses the standard day-0 trick.
  static int getDaysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  // ==================== ETHIOPIAN ====================

  /// Converts a Gregorian date to its Ethiopian equivalent.
  ///
  /// Ethiopian New Year (Enkutatash) falls on September 11, or September 12
  /// in years that immediately precede a Gregorian leap year.
  static Map<String, dynamic> toEthiopian(DateTime date) {
    const monthNames = [
      'Meskerem', 'Tikimt', 'Hedar', 'Tahsas', 'Tir', 'Yekatit', 'Megabit',
      'Miazia', 'Genbot', 'Sene', 'Hamle', 'Nehase', 'Pagume',
    ];
    final gregYear = date.year;
    final newYearDay = isGregorianLeapYear(gregYear + 1) ? 12 : 11;
    final ethNewYear = DateTime(gregYear, 9, newYearDay);
    int ethYear;
    DateTime startOfEthYear;
    if (date.isBefore(ethNewYear)) {
      ethYear = gregYear - 8;
      final prevGregYear = gregYear - 1;
      final prevNewYearDay = isGregorianLeapYear(prevGregYear + 1) ? 12 : 11;
      startOfEthYear = DateTime(prevGregYear, 9, prevNewYearDay);
    } else {
      ethYear = gregYear - 7;
      startOfEthYear = ethNewYear;
    }
    final daysSinceNewYear = date.difference(startOfEthYear).inDays;
    int monthIndex;
    int dayInMonth;
    if (daysSinceNewYear < 360) {
      monthIndex = daysSinceNewYear ~/ 30;
      dayInMonth = (daysSinceNewYear % 30) + 1;
    } else {
      monthIndex = 12;
      dayInMonth = daysSinceNewYear - 360 + 1;
    }
    return {
      'year': ethYear,
      'month': monthIndex + 1,
      'day': dayInMonth,
      'monthName': monthNames[monthIndex],
    };
  }

  /// Standard Gregorian leap-year rule.
  static bool isGregorianLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

  // ==================== HEBREW / BIBLICAL ====================

  /// Julian Day Number calculation — used as the shared reference for
  /// Hebrew conversions.
  static int _gregorianToRD(DateTime date) {
    int y = date.year, m = date.month, d = date.day;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = y ~/ 100;
    final b = 2 - a + (a ~/ 4);
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524;
  }

  /// Converts a Gregorian date to its Hebrew (Biblical) equivalent.
  static Map<String, dynamic> toBiblical(DateTime date) {
    const monthNamesLeap = [
      'Tishri', 'Cheshvan', 'Kislev', 'Tevet', 'Shevat', 'Adar I', 'Adar II',
      'Nisan', 'Iyar', 'Sivan', 'Tammuz', 'Av', 'Elul',
    ];
    const monthNamesCommon = [
      'Tishri', 'Cheshvan', 'Kislev', 'Tevet', 'Shevat', 'Adar',
      'Nisan', 'Iyar', 'Sivan', 'Tammuz', 'Av', 'Elul',
    ];
    final rd = _gregorianToRD(date);
    int year = (rd + 365) ~/ 365;
    while (_hebrewNewYearRD(year + 1) <= rd) {
      year++;
    }
    while (_hebrewNewYearRD(year) > rd) {
      year--;
    }
    final newYearRD = _hebrewNewYearRD(year);
    final daysSinceNewYear = rd - newYearRD;
    final isLeap = _isHebrewLeapYear(year);
    final monthLengths = _hebrewMonthLengths(year);
    final monthNames = isLeap ? monthNamesLeap : monthNamesCommon;
    int month = 0;
    int day = daysSinceNewYear + 1;
    for (int i = 0; i < monthLengths.length; i++) {
      if (day <= monthLengths[i]) {
        month = i;
        break;
      }
      day -= monthLengths[i];
      month = i + 1;
    }
    return {
      'year': year,
      'month': month + 1,
      'day': day,
      'monthName': monthNames[month],
      'isLeapYear': isLeap,
      'monthCount': monthLengths.length,
    };
  }

  /// Days since the Hebrew epoch for Rosh Hashanah of [year].
  static int _hebrewNewYearRD(int year) {
    final y = year - 1;
    final monthsElapsed =
        235 * (y ~/ 19) + 12 * (y % 19) + ((7 * (y % 19) + 1) ~/ 19);
    final partsElapsed = 204 + 793 * (monthsElapsed % 1080);
    final hoursElapsed = 5 +
        12 * monthsElapsed +
        793 * (monthsElapsed ~/ 1080) +
        (partsElapsed ~/ 1080);
    int day = 1 + 29 * monthsElapsed + (hoursElapsed ~/ 24);
    final parts = 1080 * (hoursElapsed % 24) + (partsElapsed % 1080);
    var dow = day % 7;
    if (parts >= 19440 ||
        (dow == 2 && parts >= 9924 && !_isHebrewLeapYear(year)) ||
        (dow == 1 && parts >= 16789 && _isHebrewLeapYear(year - 1))) {
      day++;
    }
    dow = day % 7;
    if (dow == 0 || dow == 3 || dow == 5) day++;
    return day;
  }

  /// Metonic-cycle leap-year check: 7 leap years per 19-year cycle.
  static bool _isHebrewLeapYear(int year) => ((7 * year + 1) % 19) < 7;

  static int _hebrewYearLength(int year) =>
      _hebrewNewYearRD(year + 1) - _hebrewNewYearRD(year);

  static List<int> _hebrewMonthLengths(int year) {
    final isLeap = _isHebrewLeapYear(year);
    final yearLength = _hebrewYearLength(year);
    if (!isLeap) {
      return [
        30,
        yearLength == 353 || yearLength == 355 ? 29 : 30,
        yearLength == 353 || yearLength == 354 ? 29 : 30,
        29, 30, 29, 30, 29, 30, 29, 30, 29,
      ];
    } else {
      return [
        30,
        yearLength == 383 || yearLength == 385 ? 29 : 30,
        yearLength == 383 || yearLength == 384 ? 29 : 30,
        29, 30, 30, 29, 30, 29, 30, 29, 30, 29,
      ];
    }
  }

  // ==================== CUSTOM ====================

  /// Converts a Gregorian date to the equivalent in a user-defined calendar.
  static Map<String, dynamic> customCalendarDate(
      DateTime date, CalendarModel cal) {
    if (cal.monthLengths.isEmpty || cal.monthNames.isEmpty) {
      return {
        'year': date.year + cal.yearOffset,
        'month': 1,
        'day': date.day,
        'monthName': 'Month 1',
        'week': 1,
      };
    }
    var displayedYear = date.year + cal.yearOffset;
    var gregorianStart =
        DateTime(date.year, cal.yearStartMonth, cal.yearStartDay);
    if (date.isBefore(gregorianStart)) {
      displayedYear--;
      gregorianStart =
          DateTime(date.year - 1, cal.yearStartMonth, cal.yearStartDay);
    }
    final daysSinceStart = date.difference(gregorianStart).inDays;
    final lengths = List<int>.from(cal.monthLengths);
    if (_isLeapYearCustom(displayedYear, cal)) {
      lengths[lengths.length - 1]++;
    }
    var remaining = daysSinceStart + 1;
    var monthIndex = 0;
    while (monthIndex < lengths.length - 1 && remaining > lengths[monthIndex]) {
      remaining -= lengths[monthIndex];
      monthIndex++;
    }
    final safeMonthIndex =
        monthIndex.clamp(0, cal.monthNames.length - 1).toInt();
    return {
      'year': displayedYear,
      'month': safeMonthIndex + 1,
      'day': remaining,
      'monthName': cal.monthNames[safeMonthIndex],
      'week':
          (daysSinceStart ~/ (cal.daysPerWeek < 1 ? 7 : cal.daysPerWeek)) + 1,
    };
  }

  static bool _isLeapYearCustom(int year, CalendarModel cal) {
    switch (cal.leapYearRule) {
      case 'none':
        return false;
      case 'every4':
        return year % 4 == 0;
      case 'gregorian':
        return isGregorianLeapYear(year);
      case 'custom':
        if (cal.leapYearPattern.isEmpty) return false;
        final positions = cal.leapYearPattern
            .split(',')
            .map((v) => int.tryParse(v.trim()))
            .whereType<int>()
            .where((v) => v > 0)
            .toList();
        if (positions.isEmpty) return false;
        final cycleLength = positions.reduce((a, b) => a > b ? a : b);
        final positionInCycle = (year - 1) % cycleLength + 1;
        return positions.contains(positionInCycle);
      default:
        return false;
    }
  }

  // ==================== WEEK START ====================

  /// How many blank cells appear before day 1 in the month grid for [cal].
  static int getWeekStartOffset(CalendarModel cal, DateTime date) {
    final cycle = cal.daysPerWeek.clamp(1, 14).toInt();
    int weekdayIndex;
    int weekStartIndex;
    if (cal.calendarType == 'ethiopian' || cal.calendarType == 'biblical') {
      const sundayFirst = [
        'Sunday', 'Monday', 'Tuesday', 'Wednesday',
        'Thursday', 'Friday', 'Saturday',
      ];
      weekdayIndex = date.weekday % 7;
      final configured = sundayFirst.indexOf(cal.weekStartDay);
      weekStartIndex = configured < 0 ? 0 : configured;
    } else if (cal.calendarType == 'gregorian') {
      weekdayIndex = date.weekday - 1;
      final configured = cal.dayNames.indexOf(cal.weekStartDay);
      weekStartIndex = configured < 0 ? 0 : configured;
    } else {
      final epochMonth = cal.yearStartMonth.clamp(1, 12);
      final epochDay = cal.yearStartDay.clamp(1, 28);
      final epoch = DateTime(2000, epochMonth, epochDay);
      final elapsed = date.difference(epoch).inDays;
      weekdayIndex = ((elapsed % cycle) + cycle) % cycle;
      final configured = cal.dayNames.indexOf(cal.weekStartDay);
      weekStartIndex = configured < 0 ? 0 : configured % cycle;
    }
    return ((weekdayIndex - weekStartIndex) % cycle + cycle) % cycle;
  }

  // ==================== DISPATCH ====================

  /// Full date info for [gregorianDate] in [cal]'s system.
  static Map<String, dynamic> getCalendarDateInfo(
      CalendarModel cal, DateTime gregorianDate) {
    switch (cal.calendarType) {
      case 'gregorian':
        return {
          'year': gregorianDate.year,
          'month': gregorianDate.month,
          'day': gregorianDate.day,
          'monthName': cal.fullMonthNames[gregorianDate.month - 1],
        };
      case 'ethiopian':
        return toEthiopian(gregorianDate);
      case 'biblical':
        return toBiblical(gregorianDate);
      default:
        return customCalendarDate(gregorianDate, cal);
    }
  }

  /// Days in [month] of [year] in [cal]'s system.
  static int getDaysInMonthForCalendar(
      CalendarModel cal, int year, int month) {
    switch (cal.calendarType) {
      case 'gregorian':
        return DateTime(year, month + 1, 0).day;
      case 'ethiopian':
        if (month < 13) return 30;
        return (year % 4 == 3) ? 6 : 5;
      case 'biblical':
        final lengths = _hebrewMonthLengths(year);
        return (month >= 1 && month <= lengths.length)
            ? lengths[month - 1]
            : 30;
      default:
        final lengths = List<int>.from(cal.monthLengths);
        if (_isLeapYearCustom(year, cal)) lengths[lengths.length - 1] += 1;
        return (month >= 1 && month <= lengths.length)
            ? lengths[month - 1]
            : 30;
    }
  }

  /// Same date expressed in every calendar in [calendars].
  static Map<String, Map<String, dynamic>> getEquivalents(
      DateTime date, List<CalendarModel> calendars) {
    final result = <String, Map<String, dynamic>>{};
    for (final cal in calendars) {
      switch (cal.calendarType) {
        case 'gregorian':
          result[cal.name] = {
            'date': formatDate(date, cal.dateFormat),
            'month': cal.monthNames[date.month - 1],
            'year': date.year,
            'day': date.day,
          };
          break;
        case 'ethiopian':
          final e = toEthiopian(date);
          result[cal.name] = {
            'date': '${e['day']}/${e['month']}/${e['year']}',
            'month': e['monthName'],
            'year': e['year'],
            'day': e['day'],
          };
          break;
        case 'biblical':
          final b = toBiblical(date);
          result[cal.name] = {
            'date': '${b['day']}/${b['month']}/${b['year']}',
            'month': b['monthName'],
            'year': b['year'],
            'day': b['day'],
            'isLeapYear': b['isLeapYear'] == true ? 'Yes' : 'No',
            'monthCount': b['monthCount'],
          };
          break;
        default:
          final c = customCalendarDate(date, cal);
          result[cal.name] = {
            'date': '${c['day']}/${c['month']}/${c['year']}',
            'month': c['monthName'],
            'year': c['year'],
            'day': c['day'],
            'week': c['week'],
          };
          break;
      }
    }
    return result;
  }

  // ==================== BIBLICAL HOURS ====================

  /// Formats [hour]:[minute] as a biblical hour.
  ///
  /// With `sunriseHour == 6`:
  ///   • 06:00 → "1st Hour (6 AM - 7 AM)"
  ///   • 12:00 → "7th Hour (12 PM - 1 PM)"
  ///   • 18:00 → "1st Hour of Night (6 PM - 7 PM)"
  ///
  /// With `sunriseHour == 7`, everything shifts one hour later.
  static String getBiblicalTime(int hour, int minute,
      {int sunriseHour = 6}) {
    final sunsetHour = sunriseHour + 12;
    bool isDaytime;
    int relativeHour;
    if (hour >= sunriseHour && hour < sunsetHour) {
      isDaytime = true;
      relativeHour = hour - sunriseHour;
    } else {
      isDaytime = false;
      if (hour >= sunsetHour) {
        relativeHour = hour - sunsetHour;
      } else {
        relativeHour = (24 - sunsetHour) + hour;
      }
    }
    final biblicalHour = relativeHour + 1;
    final startHour24 =
        isDaytime ? sunriseHour + relativeHour : (sunsetHour + relativeHour) % 24;
    final endHour24 = (startHour24 + 1) % 24;
    final start12 = _format12Hour(startHour24);
    final end12 = _format12Hour(endHour24);
    if (isDaytime) {
      return '$biblicalHour${_ordinal(biblicalHour)} Hour ($start12 - $end12)';
    } else {
      return '$biblicalHour${_ordinal(biblicalHour)} Hour of Night ($start12 - $end12)';
    }
  }

  static String _format12Hour(int hour24) {
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    final h12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    return '$h12 $ampm';
  }

  static String _ordinal(int n) {
    if (n == 1) return 'st';
    if (n == 2) return 'nd';
    if (n == 3) return 'rd';
    return 'th';
  }

  /// Formats a `HH:MM` string into the given display format.
  static String formatTimeForCalendar(String timeStr, String format,
      {int sunriseHour = 6}) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return timeStr;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      if (format == '12h') {
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$h12:$minute $ampm';
      } else if (format == 'biblical') {
        return getBiblicalTime(hour, minute, sunriseHour: sunriseHour);
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }
}