import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/quran_api_service.dart';
import '../models/surah.dart';
import '../models/verse.dart';
import '../models/verse_segment.dart';
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
          // Ignore preloading errors
        }
      }

      if (mounted) {
        setState(() {
          _currentVerses = _pageCache[_currentPage];
          _isLoading = false;
        });
      }
    } catch (e) {
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
      _currentPage = page + 1;
    });
    _loadCurrentPage();
    _saveCurrentPage(_currentPage);
  }

  String _toArabicDigits(String number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      number = number.replaceAll(english[i], arabic[i]);
    }
    return number;
  }

  @override
  Widget build(BuildContext context) {
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
                      if (_currentVerses!.isNotEmpty) _buildHeader(),
                      Expanded(
                        child: _buildVersesList(),
                      ),
                      _buildPageNumber(),
                    ],
                  ),
                );
              },
            ),
            if (_showControls) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final surah = _surahs!.firstWhere((s) =>
        s.number == int.parse(_currentVerses!.first.verseKey.split(':')[0]));

    return Container(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Text(
            surah.nameArabic,
            style: TextStyle(
              fontFamily: 'Uthmani',
              fontSize: 32,
              color:
                  Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(230),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            surah.nameSimple,
            style: TextStyle(
              fontSize: 16,
              color:
                  Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(179),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersesList() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: LayoutBuilder(builder: (context, constraints) {
              // Calculer la taille de police optimale
              double optimalFontSize = constraints.maxWidth * 0.05;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildVersesWithBismillah(fontSize: optimalFontSize),
              );
            }),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVersesWithBismillah({required double fontSize}) {
    List<Widget> widgets = [];
    // Grouper les versets par ligne selon la mise en page standard
    List<List<VerseSegment>> pageLines = _getStandardPageLayout();

    // Construire le texte avec la mise en page fixe
    for (var line in pageLines) {
      if (line.isEmpty) continue;

      // Vérifier si on doit ajouter la Bismillah
      if (line.first.isStartOfSurah && line.first.surahNumber != 9) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Bismillah(),
        ));
      }

      // Construire la ligne
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0),
          child: Text.rich(
            TextSpan(
              children: line
                  .map((segment) => TextSpan(
                        text: segment.text +
                            (segment.isEndOfVerse
                                ? ' ${_toArabicDigits(segment.verseNumber)} '
                                : ' '),
                        style: TextStyle(
                          fontSize: fontSize,
                          fontFamily: 'Uthmani',
                          height: 1.8,
                          letterSpacing: -0.5,
                        ),
                      ))
                  .toList(),
            ),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    return widgets;
  }

  List<List<VerseSegment>> _getStandardPageLayout() {
    List<List<VerseSegment>> pageLines = [];
    List<VerseSegment> currentLine = [];
    int wordsInCurrentLine = 0;
    const int maxWordsPerLine =
        8; // Augmente le nombre maximum de mots par ligne

    for (var verse in _currentVerses!) {
      final parts = verse.verseKey.split(':');
      final surahNumber = int.parse(parts[0]);
      final verseNumber = parts[1];

      List<String> words = verse.text.split(' ');
      bool isFirstWord = true;

      for (var word in words) {
        if (isFirstWord && verseNumber == "1") {
          if (currentLine.isNotEmpty) {
            pageLines.add(currentLine);
            currentLine = [];
            wordsInCurrentLine = 0;
          }
          currentLine.add(VerseSegment(
            text: word,
            verseNumber: verseNumber,
            isStartOfSurah: true,
            surahNumber: surahNumber,
          ));
          wordsInCurrentLine++;
        } else {
          // Calcule si le mot actuel peut tenir sur la ligne
          bool shouldStartNewLine = wordsInCurrentLine >= maxWordsPerLine ||
              (word.length > 10 && wordsInCurrentLine >= maxWordsPerLine - 2);

          if (shouldStartNewLine && currentLine.isNotEmpty) {
            pageLines.add(currentLine);
            currentLine = [];
            wordsInCurrentLine = 0;
          }

          currentLine.add(VerseSegment(
            text: word,
            verseNumber: verseNumber,
            surahNumber: surahNumber,
          ));
          wordsInCurrentLine++;
        }
        isFirstWord = false;
      }

      // Marquer le dernier segment comme fin de verset
      if (currentLine.isNotEmpty) {
        var lastSegment = currentLine.last;
        currentLine[currentLine.length - 1] = VerseSegment(
          text: lastSegment.text,
          verseNumber: verseNumber,
          isEndOfVerse: true,
          surahNumber: surahNumber,
        );
      }
    }

    if (currentLine.isNotEmpty) {
      pageLines.add(currentLine);
    }

    return pageLines;
  }

  Widget _buildPageNumber() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Text(
          _currentPage.toString(),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(128),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: Colors.black.withAlpha(26),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).scaffoldBackgroundColor.withAlpha(242),
                child: Column(
                  children: [
                    _buildSurahDropdown(),
                    const SizedBox(height: 16),
                    _buildControlBar(),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
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
                      child: Text(
                        '${surah.nameSimple} (${surah.nameArabic})',
                        style: const TextStyle(fontSize: 16),
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

  Widget _buildControlBar() {
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
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withAlpha(128),
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
