/// A prayer request entry in the Christian Tools section.
///
/// Pure data — no Flutter imports needed. `answered` can be toggled without
/// recreating the object.
class PrayerRequest {
  final String id;
  String title;
  String description;
  DateTime dateAdded;
  bool answered;

  PrayerRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.dateAdded,
    this.answered = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dateAdded': dateAdded.toIso8601String(),
        'answered': answered,
      };

  factory PrayerRequest.fromJson(Map<String, dynamic> json) => PrayerRequest(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        dateAdded: DateTime.parse(json['dateAdded']),
        answered: json['answered'] ?? false,
      );
}