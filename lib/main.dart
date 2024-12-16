import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran; // Importing the Quran package
import 'package:shared_preferences/shared_preferences.dart'; // For saving and loading user preferences
import 'extensions/arabic_number.dart'; // Custom extension for converting numbers to Arabic numerals

void main() {
  runApp(const MyApp());
}

// Root application widget with theme management
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  // Track current theme mode (light, dark, or system default)
  ThemeMode _themeMode = ThemeMode.system;

  // Update the application's theme mode
  void updateThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coran', // Application title
      debugShowCheckedModeBanner: false, // Hide debug banner
      
      // Light theme configuration
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 107, 107, 112)),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      
      // Dark theme configuration
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 107, 107, 112),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      
      // Set current theme mode
      themeMode: _themeMode,
      
      // Main screen of the application
      home: QuranScreen(onThemeToggle: updateThemeMode),
    );
  }
}

// Main Quran reading screen
class QuranScreen extends StatefulWidget {

  // Callback for theme toggling
  final void Function(ThemeMode) onThemeToggle;

  const QuranScreen({super.key, required this.onThemeToggle});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  int surahNumber = 1;
  double _fontSize = 28.0;
  bool _showControls = false;

  // Liste des noms de sourates en arabe
  static const List<String> arabicSurahNames = [
    'الفَاتِحَة',
    'البَقَرَة',
    'آل عِمرَان',
    'النِّسَاء',
    'المَائدة',
    'الأنعَام',
    'الأعرَاف',
    'الأنفَال',
    'التوبَة',
    'يُونس',
    'هُود',
    'يُوسُف',
    'الرَّعْد',
    'إبراهِيم',
    'الحِجْر',
    'النَّحْل',
    'الإسْرَاء',
    'الكَهْف',
    'مَريَم',
    'طه',
    'الأنبيَاء',
    'الحَج',
    'المُؤمنون',
    'النُّور',
    'الفُرْقان',
    'الشُّعَرَاء',
    'النَّمْل',
    'القَصَص',
    'العَنكبوت',
    'الرُّوم',
    'لقمَان',
    'السَّجدَة',
    'الأحزَاب',
    'سَبَأ',
    'فَاطِر',
    'يس',
    'الصَّافات',
    'ص',
    'الزُّمَر',
    'غَافِر',
    'فُصِّلَت',
    'الشُّورى',
    'الزُّخرُف',
    'الدخَان',
    'الجَاثيَة',
    'الأحقاف',
    'مُحَمَّد',
    'الفَتْح',
    'الحُجرَات',
    'ق',
    'الذَّاريَات',
    'الطُّور',
    'النَّجْم',
    'القَمَر',
    'الرَّحمن',
    'الوَاقِعَة',
    'الحَديد',
    'المجَادلة',
    'الحَشر',
    'المُمتَحنَة',
    'الصَّف',
    'الجُمُعَة',
    'المنَافِقون',
    'التغَابُن',
    'الطلَاق',
    'التحْريم',
    'المُلْك',
    'القَلَم',
    'الحَاقَّة',
    'المعَارج',
    'نُوح',
    'الجِن',
    'المُزَّمِّل',
    'المُدَّثِّر',
    'القِيَامَة',
    'الإنسَان',
    'المُرسَلات',
    'النَّبَأ',
    'النَّازعَات',
    'عَبَس',
    'التَّكوير',
    'الانفِطار',
    'المطفِّفِين',
    'الانشِقَاق',
    'البُروج',
    'الطَّارق',
    'الأعلى',
    'الغَاشِية',
    'الفَجْر',
    'البَلَد',
    'الشَّمس',
    'الليل',
    'الضُّحى',
    'الشَّرْح',
    'التِّين',
    'العَلَق',
    'القَدْر',
    'البَيِّنَة',
    'الزَّلزَلة',
    'العَادِيات',
    'القَارِعة',
    'التَّكَاثر',
    'العَصْر',
    'الهُمَزَة',
    'الفِيل',
    'قُرَيْش',
    'المَاعُون',
    'الكَوْثَر',
    'الكَافِرُون',
    'النَّصر',
    'المَسَد',
    'الإخْلَاص',
    'الفَلَق',
    'النَّاس'
  ];

  // SharedPreferences for persisting user settings
  late SharedPreferences _prefs;

  void _handleSwipe(DragEndDetails details) {
    if (details.primaryVelocity! > 0) { // Swipe vers la droite
      if (surahNumber > 1) {
        setState(() {
          surahNumber--;
        });
        _saveCurrentSurah(surahNumber);
      }
    } else if (details.primaryVelocity! < 0) { // Swipe vers la gauche
      if (surahNumber < 114) {
        setState(() {
          surahNumber++;
        });
        _saveCurrentSurah(surahNumber);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Load user preferences when screen initializes
    _loadPreferences();
  }

  // Load saved user preferences (current surah, font size)
  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();

    setState(() {
      // Retrieve saved surah or use default
      surahNumber = _prefs.getInt('currentSurah') ?? 1;

      // Retrieve saved font size or use default
      _fontSize = _prefs.getDouble('fontSize') ?? 28.0;
    });
  }

  // Save current user preferences
  Future<void> _savePreferences() async {
    await _prefs.setInt('currentSurah', surahNumber);
    await _prefs.setDouble('fontSize', _fontSize);
  }

  void _saveCurrentSurah(int value) async {
    await _prefs.setInt('currentSurah', value);
  }

  void _changeFontSize(double value) {
    setState(() {
      _fontSize += value;
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: _handleSwipe,
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Surah names header
                Padding(
                  padding: const EdgeInsets.only(top: 3.0, left: 15.0, right:15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Latin name on the left
                      Text(
                        quran.getSurahName(surahNumber).toUpperCase(),
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      // Arabic name on the right
                      Text(
                        // Les noms de sourates sont indexés à partir de 0
                        arabicSurahNames[surahNumber - 1],
                        style: const TextStyle(
                          fontFamily: 'Uthmani',
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        children: [
                          // Display Bismillah (except for Surah 9)
                          if (surahNumber != 9)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                quran.basmala,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'Uthmani',
                                  fontSize: _fontSize,
                                  color: textColor,
                                  height: 2,
                                ),
                              ),
                            ),

                          // Text of the current surah
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5.0),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: RichText(
                                textAlign: TextAlign.right,
                                text: TextSpan(
                                  style: TextStyle(
                                    fontFamily: 'Uthmani',
                                    fontSize: _fontSize,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                  children: List.generate(
                                    quran.getVerseCount(surahNumber),
                                    (verseIndex) {
                                      final verseNumber = verseIndex + 1;
                                      final verse = quran.getVerse(surahNumber, verseNumber, verseEndSymbol: false);

                                      return TextSpan(
                                        text: '$verse ${verseNumber.toArabicDigits()} ', //Verse followed by verse number
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Controls overlay that appears on tap
            if (_showControls)
              Container(
                color: Colors.black54,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top controls
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Surah selector
                            IntrinsicWidth(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: surahNumber,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    elevation: 2,
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    onChanged: (int? value) {
                                      if (value != null) {
                                        setState(() {
                                          surahNumber = value;
                                        });
                                        _saveCurrentSurah(value);
                                      }
                                    },
                                    items: List.generate(
                                      114,
                                      (index) => DropdownMenuItem<int>(
                                        value: index + 1,
                                        child: Text(
                                          '${index + 1}. ${quran.getSurahName(index + 1)} (${arabicSurahNames[index]})',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Theme and font size controls
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Theme.of(context).brightness == Brightness.dark
                                      ? Icons.light_mode
                                      : Icons.dark_mode),
                                  onPressed: () {
                                    widget.onThemeToggle(Theme.of(context).brightness == Brightness.dark
                                        ? ThemeMode.light
                                        : ThemeMode.dark);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.text_decrease),
                                  onPressed: _fontSize > 20
                                      ? () => _changeFontSize(-2)
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.text_increase),
                                  onPressed: _fontSize < 40
                                      ? () => _changeFontSize(2)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}