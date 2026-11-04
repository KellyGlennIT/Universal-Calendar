import 'package:flutter_test/flutter_test.dart';
import 'package:universal_calendar/models/calendar_model.dart';
import 'package:universal_calendar/utils/calendar_math.dart';
import 'package:universal_calendar/utils/calendar_presets.dart';

CalendarModel _cal(String type) => calendarFromPreset(type);

void main() {
  group('Rata Die', () {
    test('epoch and round-trip', () {
      expect(CalendarMath.rataDie(DateTime(1, 1, 1)), 1);
      expect(CalendarMath.rataDie(DateTime(1970, 1, 1)), 719163);
      expect(CalendarMath.rataDie(DateTime(2000, 1, 1)), 730120);
      final rd = CalendarMath.rataDie(DateTime(2026, 11, 4));
      expect(CalendarMath.fromRataDie(rd), DateTime(2026, 11, 4));
      expect(CalendarMath.weekdayOfRD(rd), DateTime.wednesday);
    });
  });

  group('Julian calendar', () {
    // Reference values from the standard Julian/Gregorian conversion tables.
    final cases = <List<int>>[
      // [gy, gm, gd, jy, jm, jd]
      [1582, 10, 15, 1582, 10, 5], // first Gregorian day
      [1900, 3, 1, 1900, 2, 17], // 13-day skew (post 1900)
      [1918, 11, 11, 1918, 10, 29], // Armistice, 13 days
      [2000, 1, 1, 1999, 12, 19], // 13 days
      [2024, 1, 7, 2023, 12, 25], // Orthodox Christmas
      [2026, 11, 4, 2026, 10, 22],
    ];
    for (final c in cases) {
      test('${c[0]}-${c[1]}-${c[2]}', () {
        final info = CalendarMath.toJulian(DateTime(c[0], c[1], c[2]));
        expect(info['year'], c[3]);
        expect(info['month'], c[4]);
        expect(info['day'], c[5]);
      });
    }

    test('leap years', () {
      expect(CalendarMath.isJulianLeapYear(1900), isTrue); // unlike Gregorian
      expect(CalendarMath.isJulianLeapYear(2000), isTrue);
      expect(CalendarMath.isJulianLeapYear(2023), isFalse);
      expect(
          CalendarMath.getDaysInMonthForCalendar(_cal('julian'), 1900, 2), 29);
    });
  });

  group('Ethiopian calendar', () {
    test('Enkutatash 2025 = 1 Meskerem 2018', () {
      final info = CalendarMath.toEthiopian(DateTime(2025, 9, 11));
      expect(info['year'], 2018);
      expect(info['month'], 1);
      expect(info['day'], 1);
    });
    test('Genna 2026 = 29 Tahsas 2018 (7 January)', () {
      final info = CalendarMath.toEthiopian(DateTime(2026, 1, 7));
      expect(info['year'], 2018);
      expect(info['month'], 4);
      expect(info['day'], 29);
    });
    test('day before Enkutatash is Pagume', () {
      final info = CalendarMath.toEthiopian(DateTime(2025, 9, 10));
      expect(info['month'], 13);
      expect(info['day'], 5);
    });
    test('leap Pagume length', () {
      final cal = _cal('ethiopian');
      // 2019 % 4 == 3 → Pagume has 6 days
      expect(CalendarMath.getDaysInMonthForCalendar(cal, 2019, 13), 6);
      expect(CalendarMath.getDaysInMonthForCalendar(cal, 2018, 13), 5);
    });
  });

  group('Coptic calendar', () {
    test('Nayrouz 2025 = 1 Thout 1742', () {
      final info = CalendarMath.toCoptic(DateTime(2025, 9, 11));
      expect(info['year'], 1742);
      expect(info['month'], 1);
      expect(info['day'], 1);
    });
  });

  group('Islamic (tabular Hijri)', () {
    // From the Umm al-Qura / tabular conversion tables.
    final cases = <List<int>>[
      [2000, 1, 1, 1420, 9, 24],
      [2025, 12, 21, 1447, 7, 1], // 1 Rajab 1447
      [2024, 3, 11, 1445, 9, 1], // 1 Ramadan 1445
      [2024, 6, 8, 1445, 12, 1], // 1 Dhu al-Hijjah 1445
      [2023, 7, 19, 1445, 1, 1], // 1 Muharram 1445
      [2025, 6, 27, 1447, 1, 1], // 1 Muharram 1447
    ];
    for (final c in cases) {
      test('${c[0]}-${c[1]}-${c[2]}', () {
        final info = CalendarMath.toIslamic(DateTime(c[0], c[1], c[2]));
        expect([info['year'], info['month'], info['day']], [c[3], c[4], c[5]]);
      });
    }

    test('month lengths', () {
      expect(CalendarMath.hijriMonthLength(1445, 1), 30);
      expect(CalendarMath.hijriMonthLength(1445, 2), 29);
      expect(CalendarMath.hijriMonthLength(1445, 12), 29);
      expect(CalendarMath.hijriMonthLength(1446, 12), 30); // leap year
    });
  });

  group('Hebrew (Biblical) calendar', () {
    final cases = <List<int>>[
      // [gy, gm, gd, hy, hm, hd]
      [2024, 10, 3, 5785, 1, 1], // Rosh Hashanah 5785
      [2024, 10, 12, 5785, 1, 10], // Yom Kippur
      [2024, 12, 26, 5785, 3, 25], // Hanukkah day 1 (25 Kislev 5785)
      [2025, 4, 13, 5785, 7, 15], // Pesach 5785 (common year: Nisan 7)
      [2025, 9, 23, 5786, 1, 1], // Rosh Hashanah 5786
      [2026, 4, 2, 5786, 7, 15], // Pesach 5786
    ];
    for (final c in cases) {
      test('${c[0]}-${c[1]}-${c[2]}', () {
        final info = CalendarMath.toBiblical(DateTime(c[0], c[1], c[2]));
        expect([info['year'], info['month'], info['day']], [c[3], c[4], c[5]]);
      });
    }

    test('5784 was a leap year with Adar I and II', () {
      final info = CalendarMath.toBiblical(DateTime(2024, 2, 10));
      expect(info['year'], 5784);
      expect(info['isLeapYear'], isTrue);
      expect(info['monthCount'], 13);
    });

    test('month numbers stay inside 1..13 in a leap year', () {
      // 5 Aug 2024 is 1 Av 5784, the month after Adar II.
      final av = CalendarMath.toBiblical(DateTime(2024, 8, 5));
      expect([av['month'], av['day'], av['monthName']], [12, 1, 'Av']);
      // 3 Oct 2024 is 1 Tishri 5785.
      final elul = CalendarMath.toBiblical(DateTime(2024, 9, 30));
      expect([elul['month'], elul['monthName']], [13, 'Elul']);
    });
  });

  group('French Republican calendar', () {
    test('22 Sept 1792 = 1 Vendémiaire an 1', () {
      final info = CalendarMath.toFrenchRepublican(DateTime(1792, 9, 22));
      expect([info['year'], info['month'], info['day']], [1, 1, 1]);
    });
  });

  group('Week start / headers', () {
    test('Gregorian Sunday start (preset default)', () {
      final cal = _cal('gregorian');
      // 1 Nov 2026 is a Sunday; Sunday-first week ⇒ no blanks.
      expect(CalendarMath.getWeekStartOffset(cal, DateTime(2026, 11, 1)), 0);
      expect(CalendarMath.weekdayHeaders(cal).first, 'Sun');
    });
    test('Sunday-first calendars', () {
      final cal = _cal('islamic');
      expect(CalendarMath.getWeekStartOffset(cal, DateTime(2026, 11, 1)), 0);
      expect(CalendarMath.weekdayHeaders(cal).first, 'Sun');
    });
    test('ethiopian Sunday start', () {
      final cal = _cal('ethiopian');
      final offset =
          CalendarMath.getWeekStartOffset(cal, DateTime(2025, 9, 11));
      // 11 Sep 2025 is a Thursday, Sunday-first ⇒ 4 blanks.
      expect(offset, 4);
      // Headers stay in the Ethiopian weekday order, starting on Sunday.
      expect(CalendarMath.weekdayHeaders(cal).first, 'Eho');
    });
    test('custom week start resolves through full day names', () {
      final cal = _cal('biblical');
      // 1 Nov 2026 is a Sunday, i.e. one day after Shabbat; 2 Nov is a Monday,
      // two days after. The header row opens on Saturday.
      cal.weekStartDay = 'Shabbat';
      expect(CalendarMath.getWeekStartOffset(cal, DateTime(2026, 11, 1)), 1);
      expect(CalendarMath.getWeekStartOffset(cal, DateTime(2026, 11, 2)), 2);
      expect(CalendarMath.weekdayHeaders(cal).first, 'Sat');
    });
  });
}
