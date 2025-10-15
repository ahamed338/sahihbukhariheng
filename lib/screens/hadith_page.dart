import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HadithPageScreen extends StatefulWidget {
  const HadithPageScreen({super.key});

  @override
  State<HadithPageScreen> createState() => _HadithPageScreenState();
}

class _HadithPageScreenState extends State<HadithPageScreen> {
  List<dynamic> _hadiths = [];
  int _currentIndex = 0;
  bool _isDarkMode = false;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _loadHadiths();
  }

  Future<void> _loadHadiths() async {
    final String data =
        await rootBundle.loadString('assets/data/hadiths.json');
    final List<dynamic> jsonResult = json.decode(data);

    List<dynamic> allHadiths = [];
    for (var volume in jsonResult) {
      for (var book in volume['books']) {
        allHadiths.addAll(book['hadiths']);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    int lastIndex = prefs.getInt('last_read_index') ?? 0;

    setState(() {
      _hadiths = allHadiths;
      _currentIndex = lastIndex.clamp(0, _hadiths.length - 1);
      _pageController = PageController(initialPage: _currentIndex);
    });
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

  @override
  Widget build(BuildContext context) {
    if (_hadiths.isEmpty || _pageController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text('Hadith ${_currentIndex + 1} / ${_hadiths.length}'),
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.orange,
        actions: [
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
                            hadith['info'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hadith['by'] ?? '',
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
                            hadith['text'] ?? '',
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
  }
}
