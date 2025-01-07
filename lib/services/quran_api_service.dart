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
    print('Fetching page $pageNumber from Quran API');
    try {
      final url = Uri.parse(
          '$baseUrl/verses/by_page/$pageNumber?words=true&word_fields=text_uthmani,text_uthmani_tajweed&fields=text_uthmani,text_uthmani_tajweed');
      print('Request URL: $url');

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      print('Response status code: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Error response body: ${response.body}');
        throw Exception('Failed to load page: HTTP ${response.statusCode}');
      }

      print('Parsing response body...');
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData['verses'] == null) {
        print('Response data: $responseData');
        throw Exception('No verses data in response');
      }

      final List<dynamic> verses = responseData['verses'];
      print('Found ${verses.length} verses');

      final Map<String, dynamic> pagination = responseData['pagination'] ??
          {
            'current_page': pageNumber,
            'next_page': pageNumber < 604 ? pageNumber + 1 : null,
            'total_pages': 604
          };
      print('Pagination info: $pagination');

      return {
        'verses': verses.map((json) => Verse.fromJson(json)).toList(),
        'current_page': pagination['current_page'] ?? pageNumber,
        'next_page': pagination['next_page'] ??
            (pageNumber < 604 ? pageNumber + 1 : null),
        'total_pages': pagination['total_pages'] ?? 604,
      };
    } catch (e, stackTrace) {
      print('Error in getQuranPages: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Verse>> getVerses(int surahNumber) async {
    print('Fetching verses for surah $surahNumber');
    final response = await http.get(
      Uri.parse(
          '$baseUrl/verses/by_chapter/$surahNumber?words=true&word_fields=text_uthmani,text_uthmani_tajweed&fields=text_uthmani,text_uthmani_tajweed'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['verses'];
      print('Received ${data.length} verses');
      print('First verse: ${json.encode(data.first)}');
      return data.map((json) => Verse.fromJson(json)).toList();
    } else {
      print('Error: ${response.statusCode} - ${response.body}');
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
      return chapter['pages'][0] as int;
    } else {
      throw Exception('Failed to get page for surah');
    }
  }
}
