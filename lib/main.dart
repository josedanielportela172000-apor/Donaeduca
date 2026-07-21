import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:donaeduca/firebase_options.dart'; 
import 'package:donaeduca/screens/splash_screen.dart';
import 'package:donaeduca/utils/app_theme.dart';
// Agregamos la palabra 'async' porque la inicialización toma un par de segundos
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DonaEduca',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}