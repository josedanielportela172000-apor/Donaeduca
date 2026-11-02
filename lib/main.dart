import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:donaeduca/firebase_options.dart'; 
import 'package:donaeduca/screens/splash_screen.dart';
import 'package:donaeduca/services/notification_service.dart';
import 'package:donaeduca/utils/app_theme.dart';
import 'package:donaeduca/utils/navigation.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Agregamos la palabra 'async' porque la inicialización toma un par de segundos
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga las variables de entorno (CLOUDINARY_*) desde el archivo .env.
  try {
    await dotenv.load();
  } catch (e) {
    debugPrint('No se pudo cargar el archivo .env: $e');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check: Protección contra abusos y bots en producción y modo debug.
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );
  } catch (e) {
    debugPrint('No se pudo inicializar Firebase App Check: $e');
  }

  // Cache local: la app funciona sin conexión (lecturas en caché) y se
  // sincroniza al recuperar la conexión.
  try {
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: true);
  } catch (e) {
    debugPrint('No se pudo habilitar la persistencia local: $e');
  }

  await NotificationService.instance.init();

  await initializeDateFormatting('es', null);
  Intl.defaultLocale = 'es';

  runApp(const MyApp());
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'DonaEduca',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          navigatorKey: navigatorKey,
          home: const SplashScreen(),
        );
      },
    );
  }
}