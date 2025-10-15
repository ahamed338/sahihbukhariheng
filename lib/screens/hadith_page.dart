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
  List<Map<String, String>> allHadiths = [];
  int currentIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHadiths();
  }

  Future<void> loadHadiths() async {
    try {
      // Load JSON
      final String jsonString = await rootBundle.loadString('assets/data/hadiths.json');
      final List<dynamic> volumes = json.decode(jsonString);

      // Flatten all hadiths
      List<Map<String, String>> hadithList = [];
      for (var volume in volumes) {
        for (var book in volume['books']) {
          for (var hadith in book['hadiths']) {
            hadithList.add({
              'info': hadith['info'],
              'by': hadith['by'],
              'text': hadith['text'],
            });
          }
        }
      }

      // Load last read index
      final prefs = await SharedPreferences.getInstance();
      int lastIndex = prefs.getInt('last_read_index') ?? 0;

      setState(() {
        allHadiths = hadithList;
        currentIndex = lastIndex < hadithList.length ? lastIndex : 0;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading hadiths: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void nextHadith() {
    if (currentIndex < allHadiths.length - 1) {
      setState(() {
        currentIndex++;
      });
      saveLastRead();
    }
  }

  void previousHadith() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      saveLastRead();
    }
  }

  Future<void> saveLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('last_read_index', currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (allHadiths.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No Hadith found')),
      );
    }

    final hadith = allHadiths[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Hadith ${currentIndex + 1} / ${allHadiths.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hadith['info'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              hadith['by'] ?? '',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  hadith['text'] ?? '',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: previousHadith,
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: nextHadith,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
