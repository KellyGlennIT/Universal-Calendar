import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/calendar_model.dart';

/// The core calendar engine.
///
/// All methods are static — this is a pure utility class, never instantiated.
///
/// Every conversion is expressed in **Rata Die** (RD), a fixed day count where
/// day 1 is 1 January 1 CE of the proleptic Gregorian calendar. Anchoring all
/// systems to one absolute timeline — instead of ad-hoc per-calendar epoch
/// arithmetic — is what makes the Julian, Islamic, Ethiopian, Coptic, Hebrew
/// and French Republican results agree with scholarly conversion tables.
///
///   • Gregorian          — international civil calendar
///   • Julian             — Alexandrian reckoning, leap year every 4 years
///   • Ethiopian          — 13 months (12 × 30 + Pagume), leap when y % 4 == 3
///   • Coptic             — 13 months, same shape, 284 CE epoch
///   • Biblical (Hebrew)  — 12/13 months, Metonic cycle with postponements
///   • Islamic (Hijri)    — tabular calendar, 30-year arithmetic cycle
///   • French Republican  — 12 × 30 + complementary days, autumnal equinox year
///   • Custom (`user`)    — arbitrary month structure + leap rules
///
/// Renamed from `DateUtils` to avoid the collision with the `DateUtils`
/// class exported by `package:flutter/material.dart`.
class CalendarMath {
  static const _uuid = Uuid();

  /// Generates a fresh UUID v4 — used as event and calendar IDs.
  static String generateId() => _uuid.v4();

  // ==================== FIXED-DAY ARITHMETIC ====================

  /// Rata Die of a Gregorian calendar date (day 1 = 1 Jan 1 CE).
  static int rataDie(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    // 719163 == Rata Die of 1970-01-01.
    return 719163 + d.difference(DateTime(1970, 1, 1)).inDays;
  }

  /// Inverse of [rataDie].
  static DateTime fromRataDie(int rd) {
    final base = DateTime(1970, 1, 1).add(Duration(days: rd - 719163));
    return DateTime(base.year, base.month, base.day);
  }

  /// Weekday of a Rata Die number (Monday = 1 … Sunday = 7).
  /// RD 1 (1 Jan 1 CE) was a Monday.
  static int weekdayOfRD(int rd) => _mod(rd - 1, 7) + 1;

  static int _floorDiv(int a, int b) => (a - (a % b)) ~/ b;

  static int _mod(int a, int b) => ((a % b) + b) % b;

  /// Standard Gregorian leap-year rule.
  static bool isGregorianLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

  /// Days in a Gregorian month. Uses the standard day-0 trick.
  static int getDaysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  // ==================== JULIAN ====================

  /// Julian leap-year rule: every fourth year, no century exceptions.
  static bool isJulianLeapYear(int year) => _mod(year, 4) == 0;

  static const List<int> _julianMonthLengths = [
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
  ];

  static const List<String> _julianMonthNames = [
    'Januarius',
    'Februarius',
    'Martius',
    'Aprilis',
    'Maius',
    'Iunius',
    'Iulius',
    'Augustus',
    'September',
    'October',
    'November',
    'December',
  ];

  /// RD of 1 January [year] in the Julian calendar.
  ///
  /// RD 1 (1 January 1 CE Gregorian) is 3 January 1 CE Julian: the
  /// Alexandrian reckoning had already slipped 2 days behind by then, and the
  /// gap widens to 13 days in 1900 and stays there until 2100.
  static int _julianYearStartRD(int year) {
    final y = year - 1;
    return 365 * y + _floorDiv(y, 4) - 1;
  }

  /// Julian year/month for [rd] — returns the map without the skew info.
  static Map<String, dynamic> toJulian(DateTime date) {
    final rd = rataDie(date);
    // First guess from the mean year length, then settle with the while loops
    // so leap years and century boundaries are always exact.
    var year = 1 + _floorDiv(rd * 4, 1461);
    while (_julianYearStartRD(year + 1) <= rd) {
      year++;
    }
    while (_julianYearStartRD(year) > rd) {
      year--;
    }
    var dayOfYear = rd - _julianYearStartRD(year);
    final monthLengths = List<int>.from(_julianMonthLengths);
    if (isJulianLeapYear(year)) monthLengths[1] = 29;
    var month = 0;
    while (month < 11 && dayOfYear >= monthLengths[month]) {
      dayOfYear -= monthLengths[month];
      month++;
    }
    // How many days the civil (Gregorian) reckoning is ahead of the Julian
    // one: 10 days in 1582, 13 days from 1900 until 2100.
    return {
      'year': year,
      'month': month + 1,
      'day': dayOfYear + 1,
      'monthName': _julianMonthNames[month],
      'isLeapYear': isJulianLeapYear(year),
      'skewDays': _julianGregorianSkew(date),
    };
  }

  /// Gregorian − Julian offset for a civil date: 10 days from 1582, 11 from
  /// 1700, 12 from 1800, 13 from 1900 until 2100.
  static int _julianGregorianSkew(DateTime gregorian) {
    final y = gregorian.year;
    if (y >= 1582) {
      return 10 + _floorDiv(y - 1582, 100) - _floorDiv(y - 1582, 400);
    }
    // Before the Gregorian reform the two calendars agree on the Julian base.
    return 0;
  }

  // ==================== ETHIOPIAN & COPTIC ====================

  /// Ethiopian and Coptic leap years (both get a 6th Pagume day when
  /// year % 4 == 3) — offset per era, see [_ethiopicYearStartRD].
  static bool isEthiopicLeapYear(int year) => _mod(year, 4) == 3;

  /// Coptic leap years are phase-shifted one year against the Ethiopian ones.
  static bool isCopticLeapYear(int year) => _mod(year, 4) == 3;

  static const List<String> _ethiopianMonthNames = [
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
  ];

  static const List<String> _copticMonthNames = [
    'Thout',
    'Paopi',
    'Hathor',
    'Koiak',
    'Tobi',
    'Meshir',
    'Paremhat',
    'Paremoude',
    'Pashons',
    'Paoni',
    'Epip',
    'Mesori',
    'Pi Kogi Enavot',
  ];

  /// RD of 1 Meskerem 1 CE (Ethiopian year 1) = 29 August 8 CE Gregorian.
  static final int _ethiopianEpochRD = rataDie(DateTime(8, 8, 27));

  /// RD of 1 Thout 1 CE (Coptic year 1) = 29 August 284 CE Gregorian (the Era
  /// of Martyrs).
  static final int _copticEpochRD = rataDie(DateTime(284, 8, 29));

  static int _ethiopicYearStartRD(int year, int epochRD, int epochYear,
      {required bool coptic}) {
    final y = year - epochYear;
    // Every four years gain a Pagume day, phased so leap years are exactly
    // those with year % 4 == 3. Ethiopian year 1 opens the cycle (carry =
    // floor(y/4)); the Coptic era starts one year later in that cycle.
    final cycles = coptic
        ? _floorDiv(year + 1, 4) - _floorDiv(epochYear + 1, 4)
        : _floorDiv(year, 4) - _floorDiv(epochYear, 4);
    return epochRD + 365 * y + cycles;
  }

  static Map<String, dynamic> _toEthiopicFamily(
    DateTime date, {
    required int epochRD,
    required int epochYear,
    required List<String> monthNames,
    required bool coptic,
  }) {
    final rd = rataDie(date);
    var year = epochYear + _floorDiv(rd - epochRD, 365);
    while (_ethiopicYearStartRD(year + 1, epochRD, epochYear, coptic: coptic) <=
        rd) {
      year++;
    }
    while (
        _ethiopicYearStartRD(year, epochRD, epochYear, coptic: coptic) > rd) {
      year--;
    }
    final dayOfYear =
        rd - _ethiopicYearStartRD(year, epochRD, epochYear, coptic: coptic);
    final monthIndex = dayOfYear < 360 ? dayOfYear ~/ 30 : 12;
    return {
      'year': year,
      'month': monthIndex + 1,
      'day': dayOfYear - monthIndex * 30 + 1,
      'monthName': monthNames[monthIndex],
      'isLeapYear': coptic ? _mod(year, 4) == 3 : isEthiopicLeapYear(year),
    };
  }

  /// Converts a Gregorian date to its Ethiopian equivalent.
  static Map<String, dynamic> toEthiopian(DateTime date) => _toEthiopicFamily(
        date,
        epochRD: _ethiopianEpochRD,
        epochYear: 1,
        monthNames: _ethiopianMonthNames,
        coptic: false,
      );

  /// Converts a Gregorian date to its Coptic equivalent.
  static Map<String, dynamic> toCoptic(DateTime date) => _toEthiopicFamily(
        date,
        epochRD: _copticEpochRD,
        epochYear: 1,
        monthNames: _copticMonthNames,
        coptic: true,
      );

  // ==================== ISLAMIC (TABULAR HIJRI) ====================

  static const List<String> _hijriMonthNames = [
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  /// RD of 1 Muharram 1 AH (16 July 622 Julian = 19 July 622 Gregorian).
  ///
  /// The tabular cycle is anchored so that 1 Muharram 1445 = 19 July 2023,
  /// matching published conversion tables.
  static const int _hijriEpochRD = 227015;

  /// A year is leap (355 days) when the 30-year cycle grants it an extra day.
  /// Derived from the same counter as [_hijriYearStartRD], so the year
  /// boundary and the month lengths can never disagree.
  static bool isHijriLeapYear(int year) =>
      _hijriYearStartRD(year + 1) - _hijriYearStartRD(year) == 355;

  /// Fixed date of 1 Muharram [year] in the tabular Islamic calendar.
  ///
  /// Reingold & Dershowitz: RD = epoch − 1 + (year − 1)·354 +
  /// floor((3 + 11·year) / 30). The epoch constant already folds in the −1.
  static int _hijriYearStartRD(int year) {
    final y = year - 1;
    return _hijriEpochRD + 354 * y + _floorDiv(11 * y + 3, 30);
  }

  /// Days from 1 Muharram to the first day of [month] (1-based month).
  /// Zero-based: the start of Muharram is 0.
  static int _hijriMonthStartOffset(int year, int month) {
    var offset = 0;
    for (var m = 1; m < month; m++) {
      offset += hijriMonthLength(year, m);
    }
    return offset;
  }

  static int hijriMonthLength(int year, int month) {
    if (_mod(month, 2) == 1) return 30; // odd months are full
    if (month == 12) return isHijriLeapYear(year) ? 30 : 29;
    return 29;
  }

  /// Converts a Gregorian date to the tabular Islamic (Hijri) calendar.
  static Map<String, dynamic> toIslamic(DateTime date) {
    final rd = rataDie(date);
    var year = _floorDiv(30 * (rd - _hijriEpochRD) + 10646, 10631);
    while (_hijriYearStartRD(year + 1) <= rd) {
      year++;
    }
    while (_hijriYearStartRD(year) > rd) {
      year--;
    }
    // Locate the month by comparing against each month's fixed offset from
    // 1 Muharram, so month lengths and the leap day can never drift apart.
    final dayOfYear = rd - _hijriYearStartRD(year);
    var month = 1;
    while (month < 12 && dayOfYear >= _hijriMonthStartOffset(year, month + 1)) {
      month++;
    }
    return {
      'year': year,
      'month': month,
      'day': dayOfYear - _hijriMonthStartOffset(year, month) + 1,
      'monthName': _hijriMonthNames[month - 1],
      'isLeapYear': isHijriLeapYear(year),
    };
  }

  // ==================== HEBREW / BIBLICAL ====================

  static const List<String> _hebrewMonthNamesLeap = [
    'Tishri',
    'Cheshvan',
    'Kislev',
    'Tevet',
    'Shevat',
    'Adar I',
    'Adar II',
    'Nisan',
    'Iyar',
    'Sivan',
    'Tammuz',
    'Av',
    'Elul',
  ];

  static const List<String> _hebrewMonthNamesCommon = [
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
  ];

  /// Metonic leap years: 7 per 19-year cycle (years 3, 6, 8, 11, 14, 17, 19).
  static bool _isHebrewLeapYear(int year) => ((7 * year + 1) % 19) < 7;

  /// Rata Die of 1 Tishri 1 AM — the Hebrew epoch.
  static const int _hebrewEpochRD = -1373427;

  /// RD of 1 Tishri [year] with the four traditional postponement rules
  /// (deḥiyyot), as given in Reingold & Dershowitz, *Calendrical
  /// Calculations*.
  static int _hebrewNewYearRD(int year) {
    // Reingold & Dershowitz, *Calendrical Calculations* 3rd ed., 5.6.
    final monthsElapsed = _floorDiv(235 * year - 234, 19);
    final partsElapsed = 12084 + 13753 * monthsElapsed;
    var day = 29 * monthsElapsed + _floorDiv(partsElapsed, 25920);
    // Lo ADU Rosh: Rosh Hashanah may not fall on Sunday, Wednesday or Friday.
    if (_mod(3 * (day + 1), 7) < 3) {
      day += 1;
    }
    // 1 Tishri 1 AM = RD −1373427. Reingold counts from the epoch, so the
    // absolute fixed date is that constant plus the elapsed day count.
    return _hebrewEpochRD + day;
  }

  static int _hebrewYearLength(int year) =>
      _hebrewNewYearRD(year + 1) - _hebrewNewYearRD(year);

  /// Month lengths for a Hebrew year, always in Tishri-first order.
  ///
  /// Cheshvan is long (30) in a "complete" year (355/385 days) and Kislev is
  /// short (29) in a "deficient" year (353/383 days).
  static List<int> _hebrewMonthLengths(int year) {
    final isLeap = _isHebrewLeapYear(year);
    // The year is deficient (353), regular (354) or complete (355) *excluding*
    // the intercalated Adar I, so subtract it first to classify the year.
    final total = _hebrewYearLength(year);
    final base = isLeap ? total - 30 : total; // 353..355
    final complete = base == 355;
    final deficient = base == 353;
    return [
      30, // Tishri
      complete ? 30 : 29, // Cheshvan: 30 only in a complete year
      deficient ? 29 : 30, // Kislev: 29 only in a deficient year
      29, // Tevet
      30, // Shevat
      if (isLeap) 30, // Adar I
      29, // Adar (Adar II in a leap year)
      30, // Nisan
      29, // Iyar
      30, // Sivan
      29, // Tammuz
      30, // Av
      29, // Elul
    ];
  }

  /// Debug hooks for tests.
  static bool debugHebrewLeap(int y) => _isHebrewLeapYear(y);
  static List<int> debugHebrewMonthLengths(int y) => _hebrewMonthLengths(y);
  static int debugHijriYearStart(int y) => _hijriYearStartRD(y);
  static int debugHebrewNewYear(int y) => _hebrewNewYearRD(y);

  /// Converts a Gregorian date to the Hebrew calendar.
  static Map<String, dynamic> toBiblical(DateTime date) {
    final rd = rataDie(date);
    // Hebrew year ≈ Gregorian year + 3760, but Rosh Hashanah falls in the
    // previous civil year from January to mid-September, so start low and let
    // the loops settle it exactly against Rosh Hashanah.
    var year = date.year + 3759;
    while (_hebrewNewYearRD(year + 1) <= rd) {
      year++;
    }
    while (_hebrewNewYearRD(year) > rd) {
      year--;
    }
    final isLeap = _isHebrewLeapYear(year);
    final lengths = _hebrewMonthLengths(year);
    var dayOfYear = rd - _hebrewNewYearRD(year) + 1; // 1-based
    var month = 0;
    while (month < lengths.length - 1 && dayOfYear > lengths[month]) {
      dayOfYear -= lengths[month];
      month++;
    }
    final names = isLeap ? _hebrewMonthNamesLeap : _hebrewMonthNamesCommon;
    // Indexes are Tishri-first (Tishri = 0). The single Adar of a common year
    // takes number 6, so from Nisan onward every month is one higher in the
    // leap year (which carries the extra Adar I).
    return {
      'year': year,
      'month': month + 1,
      'day': dayOfYear,
      'monthName': names[month],
      'isLeapYear': isLeap,
      'monthCount': lengths.length,
    };
  }

  // ==================== FRENCH REPUBLICAN ====================

  static const List<String> _frenchMonthNames = [
    'Vendémiaire',
    'Brumaire',
    'Frimaire',
    'Nivôse',
    'Pluviôse',
    'Ventôse',
    'Germinal',
    'Floréal',
    'Prairial',
    'Messidor',
    'Thermidor',
    'Fructidor',
  ];

  /// RD of 1 Vendémiaire an 1 = 22 September 1792.
  static final int _frenchEpochRD = rataDie(DateTime(1792, 9, 22));

  /// The Republican year begins on the day of the autumnal equinox in Paris,
  /// which is 22 September in years 3, 7, 11 … of the Gregorian calendar and
  /// 23 September on the years Romme called sextile. This uses the
  /// astronomical approximation from *Calendrical Calculations*.
  static bool _isFrenchLeapYear(int year) =>
      (year % 4 == 3) || (year % 4 == 0 && year % 100 == 0 && year % 400 != 0);

  static int _frenchYearStartRD(int annee) {
    // Use the equinox formula: leap years are those where year % 4 == 3.
    final y = annee - 1;
    return _frenchEpochRD + 365 * y + _floorDiv(y + 1, 4);
  }

  static Map<String, dynamic> toFrenchRepublican(DateTime date) {
    final rd = rataDie(date);
    var annee = _floorDiv(rd - _frenchEpochRD, 365) + 1;
    while (_frenchYearStartRD(annee + 1) <= rd) {
      annee++;
    }
    while (_frenchYearStartRD(annee) > rd) {
      annee--;
    }
    final dayOfYear = rd - _frenchYearStartRD(annee);
    if (dayOfYear < 360) {
      final month = dayOfYear ~/ 30;
      return {
        'year': annee,
        'month': month + 1,
        'day': dayOfYear % 30 + 1,
        'monthName': _frenchMonthNames[month],
        'isLeapYear': _isFrenchLeapYear(annee),
      };
    }
    return {
      'year': annee,
      'month': 13,
      'day': dayOfYear - 360 + 1,
      'monthName': 'Complémentaires',
      'isLeapYear': _isFrenchLeapYear(annee),
    };
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
    final daysSinceStart = rataDie(date) - rataDie(gregorianStart);
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
        return _mod(year, 4) == 0;
      case 'julian':
        return isJulianLeapYear(year);
      case 'gregorian':
        return isGregorianLeapYear(year);
      case 'ethiopic':
        return isEthiopicLeapYear(year);
      case 'hebrew':
        return _isHebrewLeapYear(year);
      case 'hijri':
        return isHijriLeapYear(year);
      case 'french':
        return _isFrenchLeapYear(year);
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
        final positionInCycle = _mod(year - 1, cycleLength) + 1;
        return positions.contains(positionInCycle);
      default:
        return false;
    }
  }

  // ==================== WEEK START ====================

  /// Canonical weekday index (Monday = 0 … Sunday = 6) for a day name.
  ///
  /// Accepts English, French and the Hebrew / Ethiopian course names as well
  /// as anything that merely *starts* like them, so a renamed weekday such as
  /// "Shabbat" still resolves to Saturday.
  static int weekdayIndexFromName(String name) {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return 0;
    const aliases = <String, int>{
      'mon': 0, 'monday': 0, 'lun': 0, 'lundi': 0,
      'tue': 1, 'tuesday': 1, 'mar': 1, 'mardi': 1,
      'wed': 2, 'wednesday': 2, 'mer': 2, 'mercredi': 2,
      'thu': 3, 'thursday': 3, 'jeu': 3, 'jeudi': 3,
      'fri': 4, 'friday': 4, 'ven': 4, 'vendredi': 4,
      'sat': 5, 'saturday': 5, 'sam': 5, 'samedi': 5,
      'sha': 5, 'shb': 5, 'sab': 5, // Shabbat / Sabbath
      'sun': 6, 'sunday': 6, 'dim': 6, 'dimanche': 6,
      'yom': 6, // Yom Rishon = first day (Sunday-first Hebrew reckoning)
    };
    // Longest key first, so "monday" wins over "mon".
    final keys = aliases.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in keys) {
      if (n == key) return aliases[key]!;
    }
    for (final key in keys) {
      if (n.startsWith(key)) return aliases[key]!;
    }
    return 0;
  }

  /// How many blank cells appear before day 1 in the month grid for [cal].
  ///
  /// Every seven-day calendar shares the same real weekdays, so the offset is
  /// simply "weekday of day 1 relative to the configured week start". Calendars
  /// with a non-heptadic week (the French décades) count from their epoch.
  static int getWeekStartOffset(CalendarModel cal, DateTime date) {
    final firstDay = DateTime(date.year, date.month, date.day);
    final cycle = cal.daysPerWeek.clamp(1, 14).toInt();

    if (cycle != 7) {
      final epochMonth = cal.yearStartMonth.clamp(1, 12);
      final epochDay = cal.yearStartDay.clamp(1, 28);
      final epoch = DateTime(2000, epochMonth, epochDay);
      final elapsed = rataDie(firstDay) - rataDie(epoch);
      final configured = cal.dayNames.indexOf(cal.weekStartDay);
      final weekStart = configured < 0 ? 0 : _mod(configured, cycle);
      return _mod(_mod(elapsed, cycle) - weekStart, cycle);
    }

    final weekday = _mod(firstDay.weekday - 1, 7); // Monday = 0
    final weekStart = weekdayIndexFromName(cal.weekStartDay);
    return _mod(weekday - weekStart, 7);
  }

  /// Weekday header labels for [cal], rotated to its configured week start.
  ///
  /// Two conventions are in play:
  ///   • Gregorian/Julian keep Monday-first `dayNames`, and their display list
  ///     is also Monday-first.
  ///   • Ethiopian, Biblical, Coptic, Islamic and French Republican keep their
  ///     own labels but display them Sunday-first.
  /// Resolving the configured start to a real weekday and then anchoring it in
  /// the display list handles both without special-casing.
  static List<String> weekdayHeaders(CalendarModel cal) {
    final count = cal.daysPerWeek.clamp(1, 14).toInt();
    final names = cal.shortDayNames;
    if (names.isEmpty) return List.generate(count, (i) => 'D${i + 1}');

    if (count != 7) {
      final index = cal.dayNames.indexOf(cal.weekStartDay);
      final offset = index < 0 ? 0 : _mod(index, count);
      return List.generate(count, (i) => names[_mod(offset + i, names.length)]);
    }

    // `weekdayIndexFromName` is Monday-based. For calendars whose display list
    // is Sunday-anchored with custom labels (Ethiopian, Biblical, Coptic), the
    // configured start is a *display* index, but a renamed start such as
    // 'Shabbat' still has to be translated. Shifting by one converts a
    // Monday-based weekday into its Sunday-based display position.
    final usesPlainWeekdayNames = cal.calendarType == 'gregorian' ||
        cal.calendarType == 'julian' ||
        cal.calendarType == 'islamic' ||
        cal.calendarType == 'french_republican' ||
        cal.calendarType == 'user';
    final weekStart = weekdayIndexFromName(cal.weekStartDay);
    final int startIndex;
    if (usesPlainWeekdayNames) {
      final listStart = weekdayIndexFromName(names.first);
      startIndex = _mod(weekStart - listStart, 7);
    } else {
      final declared = cal.fullDayNames.indexOf(cal.weekStartDay);
      startIndex =
          declared >= 0 && declared < 7 ? declared : _mod(weekStart + 1, 7);
    }
    return List.generate(7, (i) => names[_mod(startIndex + i, names.length)]);
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
          'monthName': cal.fullMonthNames.length >= gregorianDate.month
              ? cal.fullMonthNames[gregorianDate.month - 1]
              : DateFormat('MMMM').format(gregorianDate),
        };
      case 'julian':
        return toJulian(gregorianDate);
      case 'ethiopian':
        return toEthiopian(gregorianDate);
      case 'coptic':
        return toCoptic(gregorianDate);
      case 'biblical':
        return toBiblical(gregorianDate);
      case 'islamic':
        return toIslamic(gregorianDate);
      case 'french_republican':
        return toFrenchRepublican(gregorianDate);
      default:
        return customCalendarDate(gregorianDate, cal);
    }
  }

  /// The Gregorian date on which month [month] of [year] starts in [cal].
  static DateTime monthStartInCalendar(CalendarModel cal, int year, int month) {
    final probe = getCalendarDateInfo(cal, DateTime.now());
    // Work from an approximation of the calendar's year, then correct.
    final approxGregorianYear =
        year - (probe['year'] as int? ?? year) + DateTime.now().year;
    var guess = DateTime(approxGregorianYear, 1, 1);
    var info = getCalendarDateInfo(cal, guess);
    var guard = 0;
    while ((info['year'] as int) > year && guard < 800) {
      guess = guess.subtract(const Duration(days: 30));
      info = getCalendarDateInfo(cal, guess);
      guard++;
    }
    guard = 0;
    while ((info['year'] as int) < year && guard < 800) {
      guess = guess.add(const Duration(days: 30));
      info = getCalendarDateInfo(cal, guess);
      guard++;
    }
    guard = 0;
    while ((info['month'] as int) < month && guard < 400) {
      guess = guess.add(const Duration(days: 1));
      info = getCalendarDateInfo(cal, guess);
      guard++;
    }
    while ((info['month'] as int) > month && guard < 800) {
      guess = guess.subtract(const Duration(days: 1));
      info = getCalendarDateInfo(cal, guess);
      guard++;
    }
    // Walk to day 1 of that month.
    guard = 0;
    while ((info['day'] as int) > 1 && guard < 400) {
      guess = guess.subtract(const Duration(days: 1));
      info = getCalendarDateInfo(cal, guess);
      guard++;
    }
    return DateTime(guess.year, guess.month, guess.day);
  }

  /// Days in [month] of [year] in [cal]'s system.
  static int getDaysInMonthForCalendar(CalendarModel cal, int year, int month) {
    switch (cal.calendarType) {
      case 'gregorian':
        return DateTime(year, month + 1, 0).day;
      case 'julian':
        if (month == 2) return isJulianLeapYear(year) ? 29 : 28;
        return _julianMonthLengths[month - 1];
      case 'ethiopian':
      case 'coptic':
        if (month < 13) return 30;
        return isEthiopicLeapYear(year) ? 6 : 5;
      case 'biblical':
        final lengths = _hebrewMonthLengths(year);
        // [month] is the Tishri-first index reported by toBiblical. A common
        // year numbers Adar Nisan-shifted (Nisan 7 … Elul 12), so the single
        // Adar (6) has no slot in `lengths` and defaults to 29.
        if (_isHebrewLeapYear(year)) {
          return (month >= 1 && month <= lengths.length)
              ? lengths[month - 1]
              : 29;
        }
        if (month >= 1 && month <= 5) return lengths[month - 1];
        return month == 6 ? 29 : lengths[_mod(month, lengths.length)];
      case 'islamic':
        if (month < 1 || month > 12) return 30;
        return hijriMonthLength(year, month);
      case 'french_republican':
        if (month == 13) return _isFrenchLeapYear(year) ? 6 : 5;
        return 30;
      default:
        final lengths = List<int>.from(cal.monthLengths);
        if (_isLeapYearCustom(year, cal) && lengths.isNotEmpty) {
          lengths[lengths.length - 1] += 1;
        }
        return (month >= 1 && month <= lengths.length)
            ? lengths[month - 1]
            : 30;
    }
  }

  /// Month names for [cal] in the order this specific year presents them.
  static List<String> monthNamesForYear(CalendarModel cal, int year) {
    switch (cal.calendarType) {
      case 'julian':
        return _julianMonthNames;
      case 'biblical':
        return _isHebrewLeapYear(year)
            ? _hebrewMonthNamesLeap
            : _hebrewMonthNamesCommon;
      case 'islamic':
        return _hijriMonthNames;
      case 'french_republican':
        return [..._frenchMonthNames, 'Complémentaires'];
      case 'ethiopian':
        return _ethiopianMonthNames;
      case 'coptic':
        return _copticMonthNames;
      default:
        return cal.fullMonthNames;
    }
  }

  /// Same date expressed in every calendar in [calendars].
  static Map<String, Map<String, dynamic>> getEquivalents(
      DateTime date, List<CalendarModel> calendars) {
    final result = <String, Map<String, dynamic>>{};
    for (final cal in calendars) {
      final info = getCalendarDateInfo(cal, date);
      result[cal.name] = {
        'date': '${info['day']}/${info['month']}/${info['year']}',
        'month': info['monthName'],
        'year': info['year'],
        'day': info['day'],
        if (info['isLeapYear'] != null)
          'isLeapYear': info['isLeapYear'] == true ? 'Yes' : 'No',
        if (info['monthCount'] != null) 'monthCount': info['monthCount'],
        if (cal.daysPerWeek != 7 && cal.dayNames.isNotEmpty)
          'dayName': cal.dayNames[_mod(rataDie(date) - 1, cal.daysPerWeek)],
      };
    }
    return result;
  }

  // ==================== BIBLICAL HOURS ====================

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

  /// Formats [hour]:[minute] as a biblical hour.
  ///
  /// With `sunriseHour == 6`:
  ///   • 06:00 → "1st Hour (6 AM - 7 AM)"
  ///   • 12:00 → "7th Hour (12 PM - 1 PM)"
  ///   • 18:00 → "1st Hour of Night (6 PM - 7 PM)"
  static String getBiblicalTime(int hour, int minute, {int sunriseHour = 6}) {
    final sunsetHour = sunriseHour + 12;
    bool isDaytime;
    int relativeHour;
    if (hour >= sunriseHour && hour < sunsetHour) {
      isDaytime = true;
      relativeHour = hour - sunriseHour;
    } else {
      isDaytime = false;
      relativeHour =
          hour >= sunsetHour ? hour - sunsetHour : (24 - sunsetHour) + hour;
    }
    final biblicalHour = relativeHour + 1;
    final startHour24 = isDaytime
        ? sunriseHour + relativeHour
        : (sunsetHour + relativeHour) % 24;
    final endHour24 = (startHour24 + 1) % 24;
    final start12 = _format12Hour(startHour24);
    final end12 = _format12Hour(endHour24);
    if (isDaytime) {
      return '$biblicalHour${_ordinal(biblicalHour)} Hour ($start12 - $end12)';
    }
    return '$biblicalHour${_ordinal(biblicalHour)} Hour of Night '
        '($start12 - $end12)';
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
        return '$h12:${minute.toString().padLeft(2, '0')} $ampm';
      } else if (format == 'biblical') {
        return getBiblicalTime(hour, minute, sunriseHour: sunriseHour);
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }
}
