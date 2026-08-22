import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const OussstrApp());
}

class OussstrApp extends StatelessWidget {
  const OussstrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oussstr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
