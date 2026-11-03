import 'package:flutter/material.dart';
import 'special_day.dart';

/// A single calendar definition.
class CalendarModel {
  final String id;
  String name;
  int daysPerWeek;
  List<String> dayNames;
  int weeksPerMonth;
  int monthsPerYear;
  List<String> monthNames;
  String yearStart;
  String timeFormat;
  String dateFormat;
  String calendarType;
  int yearStartMonth;
  int yearStartDay;
  String leapYearRule;
  String leapYearPattern;
  List<int> monthLengths;
  String weekStartDay;
  String dayStartTime;
  String customDayStart;
  String timezone;
  bool showSeconds;
  bool showMilliseconds;
  int yearOffset;
  String colorHex;
  String emoji;

  /// Days highlighted on this calendar — feasts, fasts, anniversaries.
  /// Each entry recurs annually on its month/day in this calendar's own
  /// numbering system.
  List<SpecialDay> specialDays;

  CalendarModel({
    required this.id,
    required this.name,
    required this.daysPerWeek,
    required this.dayNames,
    required this.weeksPerMonth,
    required this.monthsPerYear,
    required this.monthNames,
    required this.yearStart,
    required this.timeFormat,
    required this.dateFormat,
    this.calendarType = 'user',
    this.yearStartMonth = 1,
    this.yearStartDay = 1,
    this.leapYearRule = 'none',
    this.leapYearPattern = '',
    required this.monthLengths,
    this.weekStartDay = 'Monday',
    this.dayStartTime = 'midnight',
    this.customDayStart = '',
    this.timezone = 'UTC+0',
    this.showSeconds = false,
    this.showMilliseconds = false,
    this.yearOffset = 0,
    this.colorHex = '#8B82FF',
    this.emoji = '📅',
    List<SpecialDay>? specialDays,
  }) : specialDays = specialDays ?? [];

  Color get color {
    try {
      final hex = colorHex.replaceFirst('#', '');
      if (hex.length != 6) return const Color(0xFF8B82FF);
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF8B82FF);
    }
  }

  List<String> get fullDayNames {
    if (calendarType == 'ethiopian') {
      return ['Ehood', 'Segno', 'Maksegno', 'Rob', 'Hamus', 'Arb', 'Kidame'];
    } else if (calendarType == 'biblical') {
      return ['Yom Rishon', 'Yom Sheni', 'Yom Shlishi', 'Yom Revi\'i',
              'Yom Chamishi', 'Yom Shishi', 'Shabbat'];
    }
    return dayNames;
  }

  List<String> get fullMonthNames {
    if (calendarType == 'ethiopian') {
      return ['Meskerem', 'Tikimt', 'Hedar', 'Tahsas', 'Tir', 'Yekatit',
              'Megabit', 'Miazia', 'Genbot', 'Sene', 'Hamle', 'Nehase',
              'Pagume'];
    } else if (calendarType == 'biblical') {
      return ['Tishri', 'Cheshvan', 'Kislev', 'Tevet', 'Shevat', 'Adar',
              'Nisan', 'Iyar', 'Sivan', 'Tammuz', 'Av', 'Elul'];
    }
    return monthNames;
  }

  List<String> get shortDayNames {
    if (calendarType == 'ethiopian') {
      return ['Eho', 'Seg', 'Mak', 'Rob', 'Ham', 'Arb', 'Kid'];
    }
    if (calendarType == 'biblical') {
      return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    }
    return dayNames.map((d) => d.length > 3 ? d.substring(0, 3) : d).toList();
  }

  List<String> get shortMonthNames {
    if (calendarType == 'ethiopian') {
      return ['Mes', 'Tik', 'Hed', 'Tah', 'Tir', 'Yek', 'Meg', 'Mia', 'Gen',
              'Sen', 'Ham', 'Neh', 'Pag'];
    }
    if (calendarType == 'biblical') {
      return ['Tis', 'Che', 'Kis', 'Tev', 'She', 'Ada', 'Nis', 'Iya', 'Siv',
              'Tam', 'Av', 'Elu'];
    }
    return monthNames.map((d) => d.length > 3 ? d.substring(0, 3) : d).toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'daysPerWeek': daysPerWeek,
        'dayNames': dayNames,
        'weeksPerMonth': weeksPerMonth,
        'monthsPerYear': monthsPerYear,
        'monthNames': monthNames,
        'yearStart': yearStart,
        'timeFormat': timeFormat,
        'dateFormat': dateFormat,
        'calendarType': calendarType,
        'yearStartMonth': yearStartMonth,
        'yearStartDay': yearStartDay,
        'leapYearRule': leapYearRule,
        'leapYearPattern': leapYearPattern,
        'monthLengths': monthLengths,
        'weekStartDay': weekStartDay,
        'dayStartTime': dayStartTime,
        'customDayStart': customDayStart,
        'timezone': timezone,
        'showSeconds': showSeconds,
        'showMilliseconds': showMilliseconds,
        'yearOffset': yearOffset,
        'colorHex': colorHex,
        'emoji': emoji,
        'specialDays': specialDays.map((s) => s.toJson()).toList(),
      };

  factory CalendarModel.fromJson(Map<String, dynamic> json) => CalendarModel(
        id: json['id'],
        name: json['name'],
        daysPerWeek: json['daysPerWeek'],
        dayNames: List<String>.from(json['dayNames']),
        weeksPerMonth: json['weeksPerMonth'],
        monthsPerYear: json['monthsPerYear'],
        monthNames: List<String>.from(json['monthNames']),
        yearStart: json['yearStart'],
        timeFormat: json['timeFormat'],
        dateFormat: json['dateFormat'],
        calendarType: json['calendarType'] ?? 'user',
        yearStartMonth: json['yearStartMonth'] ?? 1,
        yearStartDay: json['yearStartDay'] ?? 1,
        leapYearRule: json['leapYearRule'] ?? 'none',
        leapYearPattern: json['leapYearPattern'] ?? '',
        monthLengths: List<int>.from(json['monthLengths'] ?? []),
        weekStartDay: json['weekStartDay'] ?? 'Monday',
        dayStartTime: json['dayStartTime'] ?? 'midnight',
        customDayStart: json['customDayStart'] ?? '',
        timezone: json['timezone'] ?? 'UTC+0',
        showSeconds: json['showSeconds'] ?? false,
        showMilliseconds: json['showMilliseconds'] ?? false,
        yearOffset: json['yearOffset'] ?? 0,
        colorHex: json['colorHex'] ?? '#8B82FF',
        emoji: json['emoji'] ?? '📅',
        specialDays: (json['specialDays'] as List?)
                ?.map((e) =>
                    SpecialDay.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
      );
}