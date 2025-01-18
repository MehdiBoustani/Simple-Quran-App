class VerseSegment {
  final String text;
  final String verseNumber;
  final bool isEndOfVerse;
  final bool isStartOfSurah;
  final int surahNumber;

  VerseSegment({
    required this.text,
    required this.verseNumber,
    this.isEndOfVerse = false,
    this.isStartOfSurah = false,
    required this.surahNumber,
  });
}
