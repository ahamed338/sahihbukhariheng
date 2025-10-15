import 'package:flutter/material.dart';
import 'screens/hadith_list.dart';

void main() {
  runApp(const HadithApp());
}

class HadithApp extends StatelessWidget {
  const HadithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahih Bukhari - English',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const HadithListScreen(),
    );
  }
}
