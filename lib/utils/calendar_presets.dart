import '../models/calendar_model.dart';
import 'calendar_math.dart';

/// Definition of a preset calendar type (Julian, Coptic, Islamic, etc.).
class CalendarPreset {
  final String name;
  final String emoji;
  final String colorHex;
  final String calendarType;
  final int daysPerWeek;
  final List<String> dayNames;
  final int weeksPerMonth;
  final int monthsPerYear;
  final List<String> monthNames;
  final List<int> monthLengths;
  final String timeFormat;
  final String dateFormat;
  final String leapYearRule;
  final String leapYearPattern;
  final String weekStartDay;
  final int yearOffset;
  final int yearStartMonth;
  final int yearStartDay;

  const CalendarPreset({
    required this.name,
    required this.emoji,
    required this.colorHex,
    required this.calendarType,
    required this.daysPerWeek,
    required this.dayNames,
    required this.weeksPerMonth,
    required this.monthsPerYear,
    required this.monthNames,
    required this.monthLengths,
    required this.timeFormat,
    required this.dateFormat,
    required this.leapYearRule,
    this.leapYearPattern = '',
    required this.weekStartDay,
    required this.yearOffset,
    this.yearStartMonth = 1,
    this.yearStartDay = 1,
  });
}

const Map<String, CalendarPreset> calendarPresets = {
  'gregorian': CalendarPreset(
    name: 'Gregorian',
    emoji: '📅',
    colorHex: '#4DABF7',
    calendarType: 'gregorian',
    daysPerWeek: 7,
    dayNames: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    weeksPerMonth: 4,
    monthsPerYear: 12,
    monthNames: [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ],
    monthLengths: [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
    timeFormat: '24h',
    dateFormat: 'DD/MM/YYYY',
    leapYearRule: 'gregorian',
    weekStartDay: 'Monday',
    yearOffset: 0,
  ),
  'julian': CalendarPreset(
    name: 'Julian',
    emoji: '🏛️',
    colorHex: '#B197FC',
    calendarType: 'julian',
    daysPerWeek: 7,
    dayNames: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    weeksPerMonth: 4,
    monthsPerYear: 12,
    monthNames: [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ],
    monthLengths: [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
    timeFormat: '24h',
    dateFormat: 'DD/MM/YYYY',
    leapYearRule: 'every4',
    weekStartDay: 'Monday',
    yearOffset: 0,
  ),
  'ethiopian': CalendarPreset(
    name: 'Ethiopian',
    emoji: '🌍',
    colorHex: '#51CF66',
    calendarType: 'ethiopian',
    daysPerWeek: 7,
    dayNames: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    weeksPerMonth: 4,
    monthsPerYear: 13,
    monthNames: [
      'Meskerem', 'Tikimt', 'Hedar', 'Tahsas', 'Tir', 'Yekatit',
      'Megabit', 'Miazia', 'Genbot', 'Sene', 'Hamle', 'Nehase',
      'Pagume',
    ],
    monthLengths: [30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 5],
    timeFormat: '12h',
    dateFormat: 'DD/MM/YYYY',
    leapYearRule: 'every4',
    weekStartDay: 'Sunday',
    yearOffset: -8,
  ),
  'coptic': CalendarPreset(
    name: 'Coptic',
    emoji: '⛪',
    colorHex: '#CC5DE8',
    calendarType: 'coptic',
    daysPerWeek: 7,
    dayNames: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    weeksPerMonth: 4,
    monthsPerYear: 13,
    monthNames: [
      'Thout', 'Paopi', 'Hathor', 'Koiak', 'Tobi', 'Meshir',
      'Paremhat', 'Paremoude', 'Pashons', 'Paoni', 'Epip', 'Mesori',
      'Pi Kogi Enavot',
    ],
    monthLengths: [30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 5],
    timeFormat: '12h',
    dateFormat: 'DD/MM/YYYY',
    leapYearRule: 'every4',
    weekStartDay: 'Sunday',
    yearOffset: -284,
  ),
  'biblical': CalendarPreset(
    name: 'Biblical',
    emoji: '✡️',
    colorHex: '#D4AF37',
    calendarType: 'biblical',
    daysPerWeek: 7,
    dayNames: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    weeksPerMonth: 4,
    monthsPerYear: 12,
    monthNames: [
      'Tishri', 'Cheshvan', 'Kislev', 'Tevet', 'Shevat', 'Adar',
      'Nisan', 'Iyar', 'Sivan', 'Tammuz', 'Av', 'Elul',
    ],
    monthLengths: [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29],
    timeFormat: 'biblical',
    dateFormat: 'DD/MM/YYYY',
    leapYearRule: 'custom',
    leapYearPattern: '3,6,8,11,14,17,19',
    weekStartDay: 'Sunday',
    yearStartMonth: 7,
    yearStartDay: 1,
    yearOffset: 0,
  ),
  'islamic': CalendarPreset(
    name: 'Islamic',
    emoji: '☪️',
    colorHex: '#20C997',
    calendarType: 'islamic',
    daysPerWeek: 7,
    dayNames: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    weeksPerMonth: 4,
    monthsPerYear: 12,
    monthNames: [
      'Muharram', 'Safar', 'Rabi I', 'Rabi II', 'Jumada I',
      'Jumada II', 'Rajab', "Sha'ban", 'Ramadan', 'Shawwal',
      "Dhu al-Q'dah", 'Dhu al-Hijjah',
    ],
    monthLengths: [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29],
    timeFormat: '12h',
    dateFormat: 'DD/MM/YYYY',
    leapYearRule: 'custom',
    leapYearPattern: '2,5,7,10,13,16,18,21,24,26,29',
    weekStartDay: 'Sunday',
    yearOffset: -579,
  ),
  'french_republican': CalendarPreset(
    name: 'French Republican',
    emoji: '🇫🇷',
    colorHex: '#FF8787',
    calendarType: 'french_republican',
    daysPerWeek: 10,
    dayNames: [
      'Primidi', 'Duodi', 'Tridi', 'Quartidi', 'Quintidi',
      'Sextidi', 'Septidi', 'Octidi', 'Nonidi', 'Décadi',
    ],
    weeksPerMonth: 3,
    monthsPerYear: 12,
    monthNames: [
      'Vendémiaire', 'Brumaire', 'Frimaire', 'Nivôse', 'Pluviôse',
      'Ventôse', 'Germinal', 'Floréal', 'Prairial', 'Messidor',
      'Thermidor', 'Fructidor',
    ],
    monthLengths: [30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
    timeFormat: '24h',
    dateFormat: 'DD/MM/YYYY',
    leapYearRule: 'gregorian',
    weekStartDay: 'Primidi',
    yearStartMonth: 9,
    yearStartDay: 22,
    yearOffset: -1791,
  ),
};

/// Builds a fresh [CalendarModel] from the preset keyed by [type].
CalendarModel calendarFromPreset(String type, {String? customName}) {
  final preset = calendarPresets[type];
  if (preset == null) {
    throw ArgumentError('Unknown calendar preset: $type');
  }
  return CalendarModel(
    id: CalendarMath.generateId(),
    name: customName ?? preset.name,
    daysPerWeek: preset.daysPerWeek,
    dayNames: List<String>.from(preset.dayNames),
    weeksPerMonth: preset.weeksPerMonth,
    monthsPerYear: preset.monthsPerYear,
    monthNames: List<String>.from(preset.monthNames),
    monthLengths: List<int>.from(preset.monthLengths),
    yearStart: CalendarMath.formatDate(DateTime.now(), 'YYYY-MM-DD'),
    timeFormat: preset.timeFormat,
    dateFormat: preset.dateFormat,
    calendarType: preset.calendarType,
    yearStartMonth: preset.yearStartMonth,
    yearStartDay: preset.yearStartDay,
    leapYearRule: preset.leapYearRule,
    leapYearPattern: preset.leapYearPattern,
    weekStartDay: preset.weekStartDay,
    yearOffset: preset.yearOffset,
    colorHex: preset.colorHex,
    emoji: preset.emoji,
  );
}