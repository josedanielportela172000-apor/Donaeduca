import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/usuario_model.dart';
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
  final Map<String, Future<UsuarioModel?>> _usuarioCache = {};

  Future<UsuarioModel?> _getUsuarioCached(String uid) {
    return _usuarioCache.putIfAbsent(uid, () => AuthService().getUsuario(uid));
  }

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
          // ...buscamos sus datos en Firestore.
          return FutureBuilder<UsuarioModel?>(
            future: _getUsuarioCached(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
              }
              final usuario = userSnapshot.data;
              // Si encontramos los datos, lo mandamos a su pantalla de inicio.
              if (usuario != null) {
                return usuario.tipo == 'empresa' ? EmpresaHomeScreen(usuario: usuario) : ColegioHomeScreen(usuario: usuario);
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