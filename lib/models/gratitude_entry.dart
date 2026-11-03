/// A single gratitude journal entry.
class GratitudeEntry {
  final String id;
  String text;
  DateTime date;

  GratitudeEntry({
    required this.id,
    required this.text,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'date': date.toIso8601String(),
      };

  factory GratitudeEntry.fromJson(Map<String, dynamic> json) => GratitudeEntry(
        id: json['id'],
        text: json['text'],
        date: DateTime.parse(json['date']),
      );
}