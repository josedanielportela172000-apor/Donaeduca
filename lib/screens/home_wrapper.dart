import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/usuario_model.dart';
import 'admin_home_screen.dart';
import 'empresa_home_screen.dart';
import 'colegio_home_screen.dart';
import 'login_screen.dart';
import '../utils/app_theme.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  @override
  Widget build(BuildContext context) {
    // Usamos StreamBuilder para reaccionar a los cambios de login/logout en tiempo real.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras se verifica el estado de autenticación, muestra un indicador.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // Si hay un usuario logueado...
        if (snapshot.hasData) {
          final user = snapshot.data!;
          // ...escuchamos sus datos en Firestore en tiempo real.
          // Un stream (en vez de un Future con caché) refleja los cambios
          // de perfil al instante y evita datos desactualizados.
          return StreamBuilder<UsuarioModel?>(
            stream: AuthService.instance.streamUsuario(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
              }
              if (userSnapshot.hasError) {
                return const Scaffold(
                  body: Center(child: Text('Error al cargar tus datos. Intenta cerrar sesión y volver a entrar.')),
                );
              }
              final usuario = userSnapshot.data;
              // Registramos el token FCM y topics para este usuario.
              if (usuario != null) {
                NotificationService.instance.setupUser(usuario);
              }
              if (usuario != null) {
                final tipo = usuario.tipo.trim().toLowerCase();

                if (tipo == 'admin') {
                  return AdminHomeScreen(usuario: usuario);
                }
                if (tipo == 'empresa') {
                  return EmpresaHomeScreen(usuario: usuario);
                }
                return ColegioHomeScreen(usuario: usuario);
              }
              // Si no se encuentran los datos (caso de error), lo deslogueamos y mandamos al login.
              // Aunque el stream de auth se encargará de esto, redirigir explícitamente es más claro.
              return const LoginScreen();
            },
          );
        }
        // Si no hay usuario, mostramos la pantalla de login.
        return const LoginScreen();
      },
    );
  }
}
