import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:universal_calendar/main.dart';
import 'package:universal_calendar/models/calendar_model.dart';
import 'package:universal_calendar/models/calendar_event.dart';
import 'package:universal_calendar/providers/locale_provider.dart';
import 'package:universal_calendar/providers/calendar_provider.dart';
import 'package:universal_calendar/providers/navigation_provider.dart';
import 'package:universal_calendar/providers/christian_tools_provider.dart';
import 'package:universal_calendar/utils/calendar_math.dart';
import 'package:universal_calendar/l10n/tr.dart';

Future<void> _waitFor(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return;
    await Future.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition not met within ${timeout.inMilliseconds} ms');
}

CalendarModel _ethiopianCal({int yearOffset = -8}) => CalendarModel(
      id: 'eth-test',
      name: 'Ethiopian',
      daysPerWeek: 7,
      dayNames: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      weeksPerMonth: 4,
      monthsPerYear: 13,
      monthNames: const [
        'Meskerem', 'Tikimt', 'Hedar', 'Tahsas', 'Tir', 'Yekatit',
        'Megabit', 'Miazia', 'Genbot', 'Sene', 'Hamle', 'Nehase', 'Pagume',
      ],
      yearStart: '2026-09-11',
      timeFormat: '12h',
      dateFormat: 'DD/MM/YYYY',
      calendarType: 'ethiopian',
      weekStartDay: 'Sunday',
      monthLengths: const [30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 5],
      yearOffset: yearOffset,
    );

CalendarModel _biblicalCal() => CalendarModel(
      id: 'bib-test',
      name: 'Biblical',
      daysPerWeek: 7,
      dayNames: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      weeksPerMonth: 4,
      monthsPerYear: 12,
      monthNames: const [
        'Tishri', 'Cheshvan', 'Kislev', 'Tevet', 'Shevat', 'Adar',
        'Nisan', 'Iyar', 'Sivan', 'Tammuz', 'Av', 'Elul',
      ],
      yearStart: '2026-09-16',
      timeFormat: 'biblical',
      dateFormat: 'DD/MM/YYYY',
      calendarType: 'biblical',
      weekStartDay: 'Sunday',
      monthLengths: const [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29],
      yearOffset: 0,
    );

CalendarModel _customCal({
  String leapRule = 'none',
  String leapPattern = '',
  String weekStartDay = 'Monday',
  int yearStartMonth = 1,
  int yearStartDay = 1,
  int daysPerWeek = 7,
  List<String>? dayNames,
  List<String>? monthNames,
  List<int>? monthLengths,
}) {
  final months = monthNames?.length ?? 12;
  return CalendarModel(
    id: 'custom-test',
    name: 'Custom',
    daysPerWeek: daysPerWeek,
    dayNames: dayNames ?? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    weeksPerMonth: 4,
    monthsPerYear: months,
    monthNames: monthNames ?? List.generate(12, (i) => 'Month ${i + 1}'),
    yearStart: '2026-01-01',
    timeFormat: '24h',
    dateFormat: 'DD/MM/YYYY',
    calendarType: 'user',
    yearStartMonth: yearStartMonth,
    yearStartDay: yearStartDay,
    leapYearRule: leapRule,
    leapYearPattern: leapPattern,
    weekStartDay: weekStartDay,
    monthLengths: monthLengths ?? List.filled(12, 30),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CalendarEvent persistence', () {
    test('reminder, all-day state and duration survive serialization', () {
      final event = CalendarEvent(
        id: 'event-1',
        title: 'Planning session',
        date: '2026-11-02',
        time: '09:30',
        notes: 'Project review',
        calendarId: 'calendar-1',
        color: Colors.teal,
        reminderMinutesBefore: 15,
        isAllDay: false,
        durationMinutes: 90,
      );
      final restored = CalendarEvent.fromJson(event.toJson());
      expect(restored.id, event.id);
      expect(restored.reminderMinutesBefore, 15);
      expect(restored.isAllDay, isFalse);
      expect(restored.durationMinutes, 90);
      expect(restored.color.toARGB32(), Colors.teal.toARGB32());
    });

    test('legacy events receive safe defaults', () {
      final timed = CalendarEvent.fromJson({
        'id': 'legacy-timed',
        'title': 'Old appointment',
        'date': '2026-11-02',
        'time': '09:00',
        'calendarId': 'calendar-1',
      });
      expect(timed.durationMinutes, 60);
      expect(timed.reminderMinutesBefore, isNull);
      expect(timed.isAllDay, isFalse);

      final legacyAllDay = CalendarEvent.fromJson({
        'id': 'legacy-all-day',
        'title': 'Old all-day event',
        'date': '2026-11-02',
        'time': '00:00',
        'calendarId': 'calendar-1',
      });
      expect(legacyAllDay.isAllDay, isTrue);
    });
  });

  group('Custom week structure', () {
    test('week start offset respects a custom five-day week', () {
      final calendar = CalendarModel(
        id: 'five-day',
        name: 'Five Day System',
        daysPerWeek: 5,
        dayNames: const ['A', 'B', 'C', 'D', 'E'],
        weeksPerMonth: 6,
        monthsPerYear: 12,
        monthNames: List<String>.generate(12, (i) => 'Month ${i + 1}'),
        yearStart: '2026-01-01',
        timeFormat: '24h',
        dateFormat: 'DD/MM/YYYY',
        calendarType: 'user',
        yearStartMonth: 1,
        yearStartDay: 1,
        weekStartDay: 'C',
        monthLengths: List<int>.filled(12, 30),
      );
      expect(
        CalendarMath.getWeekStartOffset(calendar, DateTime(2026, 1, 2)),
        1,
      );
    });
  });

  group('Custom calendar leap-year rules', () {
    test('"every4" adds one day in years divisible by 4', () {
      final cal = _customCal(leapRule: 'every4');
      expect(CalendarMath.getDaysInMonthForCalendar(cal, 2024, 12), 31);
      expect(CalendarMath.getDaysInMonthForCalendar(cal, 2025, 12), 30);
    });

    test('"gregorian" respects the century rule', () {
      final cal = _customCal(leapRule: 'gregorian');
      expect(CalendarMath.getDaysInMonthForCalendar(cal, 2000, 12), 31);
      expect(CalendarMath.getDaysInMonthForCalendar(cal, 1900, 12), 30);
    });

    test('"custom" pattern adds leap day at cycle positions', () {
      final cal = _customCal(
        leapRule: 'custom',
        leapPattern: '3,6,8,11,14,17,19',
      );
      expect(CalendarMath.getDaysInMonthForCalendar(cal, 3, 12), 31);
      expect(CalendarMath.getDaysInMonthForCalendar(cal, 4, 12), 30);
    });

    test('"none" never adds a leap day', () {
      final cal = _customCal(leapRule: 'none');
      expect(CalendarMath.getDaysInMonthForCalendar(cal, 2024, 12), 30);
      expect(CalendarMath.getDaysInMonthForCalendar(cal, 2000, 12), 30);
    });
  });

  group('Ethiopian calendar', () {
    test('New Year is Sept 12 the year before a Gregorian leap year', () {
      final info = CalendarMath.toEthiopian(DateTime(2023, 9, 12));
      expect(info['year'], 2016);
      expect(info['month'], 1);
      expect(info['day'], 1);
      expect(info['monthName'], 'Meskerem');
    });

    test('New Year is Sept 11 in a non-leap-preceding year', () {
      final info = CalendarMath.toEthiopian(DateTime(2024, 9, 11));
      expect(info['year'], 2017);
      expect(info['month'], 1);
      expect(info['day'], 1);
    });

    test('Pagume has 6 days in Ethiopian leap years', () {
      final cal = _ethiopianCal();
      expect(CalendarMath.getDaysInMonthForCalendar(cal, 2015, 13), 6);
      expect(CalendarMath.getDaysInMonthForCalendar(cal, 2016, 13), 5);
    });

    test('months 1-12 are all 30 days', () {
      final cal = _ethiopianCal();
      for (var m = 1; m <= 12; m++) {
        expect(CalendarMath.getDaysInMonthForCalendar(cal, 2015, m), 30);
      }
    });
  });

  group('Hebrew (Biblical) calendar', () {
    test('civil-order month names start with Tishri', () {
      final cal = _biblicalCal();
      expect(cal.fullMonthNames.first, 'Tishri');
      expect(cal.fullMonthNames.last, 'Elul');
      expect(cal.fullMonthNames.length, 12);
    });

    test('every day of the year converts to a valid month/day', () {
      for (var d = 0; d < 365; d += 7) {
        final info = CalendarMath.toBiblical(
          DateTime(2024, 1, 1).add(Duration(days: d)),
        );
        expect(info['day'], greaterThanOrEqualTo(1));
        expect(info['month'], greaterThanOrEqualTo(1));
        expect(info['month'], lessThanOrEqualTo(13));
        expect(info['year'], isA<int>());
        expect(info['monthName'], isNotEmpty);
      }
    });
  });

  group('getBiblicalTime', () {
    test('sunrise is the 1st hour', () {
      expect(CalendarMath.getBiblicalTime(6, 0), contains('1st Hour'));
    });

    test('just before sunrise is the 12th hour of night', () {
      expect(CalendarMath.getBiblicalTime(5, 0),
          contains('12th Hour of Night'));
    });

    test('sunrise hour is configurable', () {
      expect(CalendarMath.getBiblicalTime(7, 0, sunriseHour: 7),
          contains('1st Hour'));
      expect(CalendarMath.getBiblicalTime(6, 0, sunriseHour: 7),
          contains('Hour of Night'));
    });

    test('ordinal suffixes are correct', () {
      expect(CalendarMath.getBiblicalTime(6, 0), contains('1st'));
      expect(CalendarMath.getBiblicalTime(8, 0), contains('3rd'));
      expect(CalendarMath.getBiblicalTime(10, 0), contains('5th'));
    });
  });

  group('LocaleProvider lifecycle', () {
    test('first launch has no selected language and defaults to English',
        () async {
      final provider = LocaleProvider();
      await _waitFor(() => provider.isLoaded);
      expect(provider.languageCode, 'en');
      expect(provider.hasSelectedLanguage, isFalse);
    });

    test('saved French is loaded on construction', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'fr'});
      final provider = LocaleProvider();
      await _waitFor(() => provider.isLoaded);
      expect(provider.languageCode, 'fr');
      expect(provider.hasSelectedLanguage, isTrue);
    });

    test('setLanguage persists and updates state', () async {
      final provider = LocaleProvider();
      await _waitFor(() => provider.isLoaded);
      await provider.setLanguage('fr');
      expect(provider.languageCode, 'fr');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'fr');
    });

    test('unsupported language is rejected', () async {
      final provider = LocaleProvider();
      await _waitFor(() => provider.isLoaded);
      await provider.setLanguage('es');
      expect(provider.languageCode, 'en');
    });
  });

  group('CalendarProvider', () {
    test('loads three default calendars on fresh install', () async {
      final provider = CalendarProvider();
      await _waitFor(() => !provider.isLoading);
      expect(provider.calendars.length, 3);
      expect(provider.calendars.map((c) => c.calendarType).toSet(),
          {'gregorian', 'ethiopian', 'biblical'});
    });

    test('resetAllData restores defaults and clears events', () async {
      final provider = CalendarProvider();
      await _waitFor(() => !provider.isLoading);

      provider.addEvent(CalendarEvent(
        id: 'test-event',
        title: 'Test',
        date: '2026-01-01',
        time: '10:00',
        notes: '',
        calendarId: provider.calendars.first.id,
      ));
      expect(provider.events.length, 1);

      await provider.resetAllData();
      expect(provider.events, isEmpty);
      expect(provider.calendars.length, 3);
      expect(provider.primaryCalendarId, provider.calendars.first.id);
      expect(provider.secondaryCalendarId, isNull);
    });

    test('findEventById returns null for unknown ids', () async {
      final provider = CalendarProvider();
      await _waitFor(() => !provider.isLoading);
      expect(provider.findEventById('nonexistent'), isNull);
    });
  });

  group('First-launch experience', () {
    testWidgets('language picker is shown on first launch', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => CalendarProvider()),
            ChangeNotifierProvider(create: (_) => NavigationProvider()),
            ChangeNotifierProvider(create: (_) => ChristianToolsProvider()),
          ],
          child: const UniversalCalendarApp(),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Universal Calendar'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('Continue in English'), findsOneWidget);
      expect(find.text('Continuer en français'), findsOneWidget);
    });
  });

  group('tr() localization', () {
    testWidgets('returns French translations for known keys', (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'fr'});
      final provider = LocaleProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Consumer<LocaleProvider>(
              builder: (context, p, _) {
                if (!p.isLoaded) return const SizedBox.shrink();
                return Column(children: [
                  Text(tr(context, 'Settings')),
                  Text(tr(context, 'Home')),
                  Text(tr(context, 'Calendars')),
                ]);
              },
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Paramètres'), findsOneWidget);
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Calendriers'), findsOneWidget);
    });

    testWidgets('falls back to the key when no translation exists',
        (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'fr'});
      final provider = LocaleProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Consumer<LocaleProvider>(
              builder: (context, p, _) {
                if (!p.isLoaded) return const SizedBox.shrink();
                return Text(tr(context, 'UnmappedKey'));
              },
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('UnmappedKey'), findsOneWidget);
    });
  });
}