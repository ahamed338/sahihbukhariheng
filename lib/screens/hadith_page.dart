import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

// --- Hadith Data Model ---
class Hadith {
  final String info;
  final String by;
  final String text;

  Hadith({required this.info, required this.by, required this.text});

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      info: json['info'] ?? '',
      by: json['by'] ?? '',
      text: json['text'] ?? '',
    );
  }
}

// --- Hadith Service for Data Loading ---
class HadithService {
  Future<List<Hadith>> loadAllHadiths() async {
    final String data = await rootBundle.loadString('assets/data/hadiths.json');
    final List<dynamic> jsonResult = json.decode(data);

    List<Hadith> allHadiths = [];
    for (var volume in jsonResult) {
      if (volume is Map && volume.containsKey('books')) {
        for (var book in volume['books']) {
          if (book is Map && book.containsKey('hadiths')) {
            for (var hadithJson in book['hadiths']) {
               allHadiths.add(Hadith.fromJson(hadithJson));
            }
          }
        }
      }
    }
    return allHadiths;
  }
}

// ------------------------------------------------------------------------

class HadithPageScreen extends StatefulWidget {
  const HadithPageScreen({super.key});

  @override
  State<HadithPageScreen> createState() => _HadithPageScreenState();
}

class _HadithPageScreenState extends State<HadithPageScreen> {
  late Future<List<Hadith>> _hadithsFuture; 
  List<Hadith> _hadiths = [];
  int _currentIndex = 0;
  bool _isDarkMode = false;
  double _fontSize = 18.0; // 🎯 NEW: Default font size
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    // 🎯 UPDATED: Combine data loading and settings loading
    _hadithsFuture = _initializeData(); 
  }

  Future<List<Hadith>> _initializeData() async {
    final loadedHadiths = await HadithService().loadAllHadiths();
    final prefs = await SharedPreferences.getInstance();
    
    // Load persisted settings
    int lastIndex = prefs.getInt('last_read_index') ?? 0;
    // 🎯 NEW: Load saved font size, default to 18.0
    double savedFontSize = prefs.getDouble('hadith_font_size') ?? 18.0; 

    if (mounted) {
      setState(() {
        _hadiths = loadedHadiths;
        _currentIndex = lastIndex.clamp(0, _hadiths.length > 0 ? _hadiths.length - 1 : 0);
        _pageController = PageController(initialPage: _currentIndex);
        _fontSize = savedFontSize; // Apply loaded font size
      });
    }
    return loadedHadiths;
  }

  Future<void> _saveLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_index', _currentIndex);
  }

  // 🎯 NEW: Save the current font size to SharedPreferences
  Future<void> _saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('hadith_font_size', size);
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    // NOTE: Theme persistence (saving _isDarkMode) is a separate upgrade.
  }

  // Function to share the current Hadith
  Future<void> _shareHadith() async {
    if (_hadiths.isEmpty) return;
    
    final currentHadith = _hadiths[_currentIndex];
    final shareText = 
        'Hadith: ${currentHadith.text}\n\n'
        'Info: ${currentHadith.info}\n'
        'Source: ${currentHadith.by}';
        
    await Share.share(shareText, subject: 'Hadith ${_currentIndex + 1}');
  }
  
  // Function to copy the current Hadith
  Future<void> _copyHadith() async {
    if (_hadiths.isEmpty) return;
    
    final currentHadith = _hadiths[_currentIndex];
    final copyText = 
        'Hadith: ${currentHadith.text}\n'
        'Info: ${currentHadith.info}\n'
        'Source: ${currentHadith.by}';
        
    await Clipboard.setData(ClipboardData(text: copyText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hadith copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 🎯 NEW: Function to show the font size settings dialog
  void _showSettingsDialog() {
    double tempFontSize = _fontSize;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Text Size'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: tempFontSize,
                    min: 12.0, // Minimum readable size
                    max: 30.0, // Maximum size
                    divisions: 18,
                    label: tempFontSize.round().toString(),
                    onChanged: (double value) {
                      setDialogState(() {
                        tempFontSize = value;
                      });
                    },
                    onChangeEnd: (double value) {
                      // Apply size instantly for preview
                      setState(() {
                        _fontSize = value;
                      });
                      // Save the new size
                      _saveFontSize(value);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Example Text',
                    style: TextStyle(
                      fontSize: tempFontSize,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Hadith>>(
      future: _hadithsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || _hadiths.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error loading Hadiths: ${snapshot.error}')),
          );
        }
        
        // Data Loaded State
        return Scaffold(
          backgroundColor: _isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            title: Text('Hadith ${_currentIndex + 1} / ${_hadiths.length}'),
            backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.orange,
            actions: [
              // 🎯 NEW: Settings Button
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showSettingsDialog,
              ),
              // Share Button
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareHadith,
              ),
              // Copy Button
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _copyHadith,
              ),
              // Theme Toggle Button
              IconButton(
                icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: _toggleTheme,
              )
            ],
          ),
          body: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _hadiths.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _saveLastRead();
                },
                itemBuilder: (context, index) {
                  final hadith = _hadiths[index];
                  return GestureDetector(
                    onTapUp: (details) {
                      final width = MediaQuery.of(context).size.width;
                      if (details.localPosition.dx > width / 2) {
                        _pageController!.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                      } else {
                        _pageController!.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: _isDarkMode ? Colors.black : Colors.white,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hadith.info,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: _fontSize - 2, // Use dynamic size, slightly smaller
                                  color: _isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hadith.by,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: _fontSize - 4, // Use dynamic size, smaller still
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                hadith.text,
                                style: TextStyle(
                                  fontSize: _fontSize, // 🎯 Use the main dynamic size here
                                  color: _isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _hadiths.length,
                  color: Colors.orange,
                  backgroundColor:
                      _isDarkMode ? Colors.white12 : Colors.orange[100],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}