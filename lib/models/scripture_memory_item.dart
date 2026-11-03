/// A scripture verse being memorized.
class ScriptureMemoryItem {
  final String id;
  String reference;
  String verseText;
  bool memorized;

  ScriptureMemoryItem({
    required this.id,
    required this.reference,
    required this.verseText,
    this.memorized = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference': reference,
        'verseText': verseText,
        'memorized': memorized,
      };

  factory ScriptureMemoryItem.fromJson(Map<String, dynamic> json) => ScriptureMemoryItem(
        id: json['id'],
        reference: json['reference'],
        verseText: json['verseText'],
        memorized: json['memorized'] ?? false,
      );
}