import 'package:flutter/material.dart';
import 'screens/register_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NomNom',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const RegisterScreen(),
    );
  }
}
