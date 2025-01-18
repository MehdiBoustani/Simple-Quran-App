import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah.dart';
import '../models/verse.dart';

class QuranApiService {
  static const String baseUrl = 'https://api.quran.com/api/v4';

  Future<List<Surah>> getSurahs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chapters?language=fr'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['chapters'];
      return data.map((json) => Surah.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load surahs');
    }
  }

  Future<Map<String, dynamic>> getQuranPages(int pageNumber) async {
    try {
      final url =
          Uri.parse('$baseUrl/verses/by_page/$pageNumber?fields=text_uthmani');

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load page: HTTP ${response.statusCode}');
      }

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData['verses'] == null) {
        throw Exception('No verses data in response');
      }

      final List<dynamic> verses = responseData['verses'];
      final Map<String, dynamic> pagination = responseData['pagination'] ??
          {
            'current_page': pageNumber,
            'next_page': pageNumber < 604 ? pageNumber + 1 : null,
            'total_pages': 604
          };

      return {
        'verses': verses.map((json) => Verse.fromJson(json)).toList(),
        'current_page': pagination['current_page'] ?? pageNumber,
        'next_page': pagination['next_page'] ??
            (pageNumber < 604 ? pageNumber + 1 : null),
        'total_pages': pagination['total_pages'] ?? 604,
      };
    } catch (e) {
      print('Error in getQuranPages: $e');
      rethrow;
    }
  }

  Future<List<Verse>> getVerses(int surahNumber) async {
    final response = await http.get(
      Uri.parse('$baseUrl/verses/by_chapter/$surahNumber?fields=text_uthmani'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['verses'];
      return data.map((json) => Verse.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load verses');
    }
  }

  Future<int> getPageForSurah(int surahNumber) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chapters/$surahNumber'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final Map<String, dynamic> chapter = responseData['chapter'];
      final List<dynamic> pages = chapter['pages'] as List<dynamic>;
      return pages.last as int;
    } else {
      throw Exception('Failed to get page for surah');
    }
  }
}
