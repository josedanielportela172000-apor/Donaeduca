import 'package:flutter/material.dart';
import 'dart:async';
import 'package:donaeduca/screens/home_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:donaeduca/utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Espera 3 segundos y luego navega a la pantalla de login
    Timer(
      const Duration(seconds: 3),
      () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeWrapper()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.dmSans(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                ),
                children: const <TextSpan>[
                  TextSpan(text: 'Dona', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'Educa', style: TextStyle(color: AppColors.accent)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Empresas que educan,\ncolegios que crecen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}