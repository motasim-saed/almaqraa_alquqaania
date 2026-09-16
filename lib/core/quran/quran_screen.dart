import 'package:flutter/material.dart';
import 'package:flutter_quran/flutter_quran.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const FlutterQuranScreen(),
    );
  }
}
