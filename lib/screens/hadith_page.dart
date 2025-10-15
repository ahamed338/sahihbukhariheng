import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HadithPageScreen extends StatefulWidget {
  const HadithPageScreen({super.key});

  @override
  _HadithPageScreenState createState() => _HadithPageScreenState();
}

class _HadithPageScreenState extends State<HadithPageScreen> {
  List<dynamic> _hadithList = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadHadiths();
  }

  Future<void> _loadHadiths() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReadIndex = prefs.getInt('last_read_index') ?? 0;

    final String data = await rootBundle.loadString('assets/data/hadiths.json');
    final List<dynamic> jsonData = json.decode(data);

    // Flatten the structure: [volume -> books -> hadiths] into a single list
    List<dynamic> allHadiths = [];
    for (var volume in jsonData) {
      for (var book in volume['books']) {
        for (var hadith in book['hadiths']) {
          allHadiths.add({
            'info': hadith['info'],
            'by': hadith['by'],
            'text': hadith['text'],
          });
        }
      }
    }

    setState(() {
      _hadithList = allHadiths;
      _currentIndex = lastReadIndex < _hadithList.length ? lastReadIndex : 0;
    });
  }

  void _saveLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('last_read_index', _currentIndex);
  }

  void _nextHadith() {
    if (_currentIndex < _hadithList.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _saveLastRead();
    }
  }

  void _previousHadith() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _saveLastRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hadithList.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hadith = _hadithList[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Hadith ${_currentIndex + 1} / ${_hadithList.length}'),
      ),
      body: GestureDetector(
        onTapDown: (TapDownDetails details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 2) {
            _previousHadith();
          } else {
            _nextHadith();
          }
        },
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hadith['info'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hadith['by'],
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hadith['text'],
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
