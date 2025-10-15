import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart'; // Ensure this package is added to pubspec.yaml

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
    // Loads the 4MB JSON file completely. 
    // Remember to consider an SQLite solution later for better performance.
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
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _hadithsFuture = _initializeData(); 
  }

  Future<List<Hadith>> _initializeData() async {
    final loadedHadiths = await HadithService().loadAllHadiths();
    final prefs = await SharedPreferences.getInstance();
    int lastIndex = prefs.getInt('last_read_index') ?? 0;

    if (mounted) {
      setState(() {
        _hadiths = loadedHadiths;
        // Ensure index is within bounds
        _currentIndex = lastIndex.clamp(0, _hadiths.length > 0 ? _hadiths.length - 1 : 0);
        _pageController = PageController(initialPage: _currentIndex);
      });
    }
    return loadedHadiths;
  }

  Future<void> _saveLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_index', _currentIndex);
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
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

    // Provide user feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hadith copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
                                  fontSize: 16,
                                  color: _isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hadith.by,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14,
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                hadith.text,
                                style: TextStyle(
                                  fontSize: 18,
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