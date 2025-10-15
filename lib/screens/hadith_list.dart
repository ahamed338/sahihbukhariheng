import 'package:flutter/material.dart';
import '../models/hadith.dart';
import 'hadith_detail.dart';
import '../storage/last_read_storage.dart';

class HadithListScreen extends StatefulWidget {
  const HadithListScreen({super.key});

  @override
  _HadithListScreenState createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  final LastReadStorage storage = LastReadStorage();
  int lastReadIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    int index = await storage.getLastReadIndex();
    setState(() {
      lastReadIndex = index;
    });
  }

  // Sample Hadith data
  final List<Hadith> hadiths = [
    Hadith(book: 'Revelation', narrator: 'Narrated by Aisha', text: 'Hadith text 1...'),
    Hadith(book: 'Faith', narrator: 'Narrated by Abu Huraira', text: 'Hadith text 2...'),
    Hadith(book: 'Prayer', narrator: 'Narrated by Anas', text: 'Hadith text 3...'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sahih Bukhari')),
      body: ListView.builder(
        itemCount: hadiths.length,
        itemBuilder: (context, index) {
          final hadith = hadiths[index];
          final isLastRead = index == lastReadIndex;

          return Card(
            color: isLastRead ? Colors.orange[200] : null,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListTile(
              title: Text(hadith.book),
              subtitle: Text(hadith.narrator),
              onTap: () async {
                await storage.saveLastReadIndex(index);
                setState(() {
                  lastReadIndex = index;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HadithDetailScreen(hadith: hadith),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
