import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/quran_api_service.dart';
import '../models/surah.dart';
import '../models/verse.dart';
import '../widgets/verse_display.dart';
import '../widgets/bismillah.dart';

class QuranScreen extends StatefulWidget {
  final void Function(ThemeMode, bool) onThemeToggle;
  final bool isSepia;

  const QuranScreen({
    super.key,
    required this.onThemeToggle,
    required this.isSepia,
  });

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final QuranApiService _apiService = QuranApiService();
  List<Surah>? _surahs;
  List<Verse>? _currentVerses;
  int _currentPage = 1;
  final int _totalPages = 604;
  double _fontSize = 28.0;
  bool _showControls = false;
  bool _isLoading = true;
  final PageController _pageController = PageController();
  final Map<int, List<Verse>> _pageCache = {};
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _loadPreferences();
      await _loadSurahs();
    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Erreur d\'initialisation. Veuillez redémarrer l\'application.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentPage = _prefs.getInt('currentPage') ?? 1;
      _fontSize = _prefs.getDouble('fontSize') ?? 28.0;
    });
  }

  Future<void> _loadSurahs() async {
    try {
      final surahs = await _apiService.getSurahs();
      if (mounted) {
        setState(() {
          _surahs = surahs;
        });
        await _loadCurrentPage();
      }
    } catch (e) {
      print('Error loading surahs: $e');
      rethrow;
    }
  }

  Future<void> _loadCurrentPage() async {
    if (_pageCache.containsKey(_currentPage)) {
      setState(() {
        _currentVerses = _pageCache[_currentPage];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _currentVerses = null;
    });

    try {
      final pageData = await _apiService.getQuranPages(_currentPage);
      _pageCache[_currentPage] = pageData['verses'] as List<Verse>;

      if (_currentPage < _totalPages) {
        try {
          final nextPageData =
              await _apiService.getQuranPages(_currentPage + 1);
          _pageCache[_currentPage + 1] = nextPageData['verses'] as List<Verse>;
        } catch (e) {
          print('Error preloading next page: $e');
        }
      }

      if (mounted) {
        setState(() {
          _currentVerses = _pageCache[_currentPage];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading page $_currentPage: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erreur de chargement de la page $_currentPage. Veuillez réessayer.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveCurrentPage(int page) async {
    await _prefs.setInt('currentPage', page);
  }

  void _handlePageChange(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadCurrentPage();
    _saveCurrentPage(page);
  }


  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    if (_surahs == null || _isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: _handlePageChange,
              itemCount: _totalPages,
              itemBuilder: (context, index) {
                if (_currentVerses == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      if (_currentVerses!.isNotEmpty) _buildHeader(textColor),
                      Expanded(
                        child: _buildVersesList(textColor),
                      ),
                      _buildPageNumber(textColor),
                    ],
                  ),
                );
              },
            ),
            if (_showControls) _buildControls(textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color? textColor) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(
                  alpha: (255 * 0.1).round().toDouble(),
                ),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _surahs!
                .firstWhere((s) =>
                    s.number ==
                    int.parse(_currentVerses!.first.verseKey.split(':')[0]))
                .nameSimple,
            style: TextStyle(
              fontSize: 16,
              color: textColor?.withValues(
                alpha: (255 * 0.7).round().toDouble(),
              ),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            _surahs!
                .firstWhere((s) =>
                    s.number ==
                    int.parse(_currentVerses!.first.verseKey.split(':')[0]))
                .nameArabic,
            style: TextStyle(
              fontFamily: 'Uthmani',
              fontSize: 22,
              color: textColor?.withValues(
                alpha: (255 * 0.7).round().toDouble(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersesList(Color? textColor) {
    if (_currentVerses!.isNotEmpty) {
      print('Debug Bismillah:');
      print('Premier verset: ${_currentVerses!.first.textUthmani}');
      print('Verse key complet: ${_currentVerses!.first.verseKey}');
      print('Nombre total de versets: ${_currentVerses!.length}');
    }

    final isStartOfSurah = _currentVerses!.isNotEmpty &&
        _currentVerses!.first.verseKey.split(':')[1] == '1';
    final surahNumber = _currentVerses!.isNotEmpty
        ? int.parse(_currentVerses!.first.verseKey.split(':')[0])
        : 0;
    final shouldShowBismillah = isStartOfSurah && surahNumber != 9;

    print('Conditions Bismillah:');
    print('isStartOfSurah: $isStartOfSurah');
    print('surahNumber: $surahNumber');
    print('shouldShowBismillah: $shouldShowBismillah');

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                if (shouldShowBismillah) const Bismillah(),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.0,
                  runSpacing: 16.0,
                  children: _currentVerses!.map((verse) {
                    return VerseDisplay(
                      verse: verse,
                      fontSize: _fontSize,
                      textColor: textColor,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumber(Color? textColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Text(
          _currentPage.toString(),
          style: TextStyle(
            fontSize: 14,
            color: textColor?.withValues(
              alpha: (255 * 0.5).round().toDouble(),
            ),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildControls(Color? textColor) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: Colors.black.withValues(
          alpha: (255 * 0.1).round().toDouble(),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).scaffoldBackgroundColor.withValues(
                      alpha: (255 * 0.95).round().toDouble(),
                    ),
                child: Column(
                  children: [
                    _buildSurahDropdown(),
                    _buildControlBar(textColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: (255 * 0.05).round().toDouble()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<int>(
            value: _currentVerses?.isNotEmpty == true
                ? int.parse(_currentVerses!.first.verseKey.split(':')[0])
                : null,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            borderRadius: BorderRadius.circular(12),
            hint: const Text('Sélectionner une sourate'),
            items: _surahs?.map((surah) {
              return DropdownMenuItem<int>(
                value: surah.number,
                child: Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: surah.nameSimple,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                            TextSpan(
                              text: ' (',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                            TextSpan(
                              text: surah.nameArabic,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Uthmani',
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                            TextSpan(
                              text: ')',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (int? surahNumber) async {
              if (surahNumber != null) {
                try {
                  setState(() {
                    _isLoading = true;
                  });

                  final page = await _apiService.getPageForSurah(surahNumber);

                  setState(() {
                    _currentPage = page;
                  });

                  await _loadCurrentPage();
                  await _saveCurrentPage(page);

                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _pageController.jumpToPage(page - 1);
                    });
                  }

                  setState(() {
                    _isLoading = false;
                  });
                } catch (e) {
                  print('Error loading surah: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur de chargement de la sourate'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar(Color? textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 80,
            child: TextField(
              controller: TextEditingController(text: _currentPage.toString()),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              onSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null && page >= 1 && page <= _totalPages) {
                  _pageController.jumpToPage(page - 1);
                }
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                hintText: 'Page',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: textColor?.withValues(
                    alpha: (255 * 0.5).round().toDouble(),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  size: 20,
                ),
                onPressed: () {
                  widget.onThemeToggle(
                    Theme.of(context).brightness == Brightness.dark
                        ? ThemeMode.light
                        : ThemeMode.dark,
                    false,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
