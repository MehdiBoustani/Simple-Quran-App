class Verse {
  final String verseKey;
  final String textUthmaniTajweed;
  final String textUthmani;

  Verse({
    required this.verseKey,
    required this.textUthmaniTajweed,
    required this.textUthmani,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      verseKey: json['verse_key'] ?? '',
      textUthmaniTajweed: json['text_uthmani_tajweed'] ?? '',
      textUthmani: json['text_uthmani'] ?? '',
    );
  }
}
