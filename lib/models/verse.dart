class Verse {
  final String verseKey;
  final String text;

  Verse({
    required this.verseKey,
    required this.text,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      verseKey: json['verse_key'] ?? '',
      text: json['text_uthmani'] ?? '',
    );
  }
}
