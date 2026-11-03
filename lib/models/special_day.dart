import 'package:flutter/material.dart';

/// A special day marked on a calendar — a feast, fast, holiday, memorial,
/// anniversary, or anything else the user wants to highlight.
///
/// `month` and `day` refer to the calendar's *own* month/day numbering, not
/// Gregorian. A special day at month 3, day 15 of the Ethiopian calendar
/// appears on whichever Gregorian date that maps to. The date recurs every
/// year automatically — no need to re-enter it.
class SpecialDay {
  final String id;
  String name;
  int month;
  int day;
  String emoji;
  String colorHex;

  SpecialDay({
    required this.id,
    required this.name,
    required this.month,
    required this.day,
    this.emoji = '⭐',
    this.colorHex = '#D4AF37',
  });

  /// Resolves [colorHex] to a [Color]. Falls back to gold when malformed.
  Color get color {
    try {
      final hex = colorHex.replaceFirst('#', '');
      if (hex.length != 6) return const Color(0xFFD4AF37);
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFFD4AF37);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'month': month,
        'day': day,
        'emoji': emoji,
        'colorHex': colorHex,
      };

  factory SpecialDay.fromJson(Map<String, dynamic> json) => SpecialDay(
        id: json['id'] as String,
        name: json['name'] as String,
        month: json['month'] as int,
        day: json['day'] as int,
        emoji: (json['emoji'] as String?) ?? '⭐',
        colorHex: (json['colorHex'] as String?) ?? '#D4AF37',
      );

  SpecialDay copy() => SpecialDay(
        id: id,
        name: name,
        month: month,
        day: day,
        emoji: emoji,
        colorHex: colorHex,
      );
}