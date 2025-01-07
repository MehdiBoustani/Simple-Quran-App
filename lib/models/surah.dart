class Surah {
  final int number;
  final String nameSimple;
  final String nameArabic;
  final String nameTranslated;
  final int versesCount;
  final String revelationPlace;
  final int revelationOrder;

  Surah({
    required this.number,
    required this.nameSimple,
    required this.nameArabic,
    required this.nameTranslated,
    required this.versesCount,
    required this.revelationPlace,
    required this.revelationOrder,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['id'],
      nameSimple: json['name_simple'],
      nameArabic: json['name_arabic'],
      nameTranslated: json['translated_name']['name'],
      versesCount: json['verses_count'],
      revelationPlace: json['revelation_place'],
      revelationOrder: json['revelation_order'],
    );
  }
}
