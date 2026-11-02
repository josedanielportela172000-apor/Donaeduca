import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/usuario_model.dart';
import '../services/geocoding_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UsuarioModel> registrar({
    required String email,
    required String password,
    required String nombre,
    required String tipo,
    String? direccion,
    String? comuna,
    String? telefono,
    String? identificacion,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw Exception('No se pudo crear el usuario.');
      }

      double? lat;
      double? lng;
      bool geoPreciso = false;
      // Para colegios geocodificamos la dirección acotada a Cali y validamos
      // contra la comuna indicada (ver GeocodingService).
      if (tipo == 'colegio' && direccion != null && direccion.isNotEmpty) {
        final geo = await GeocodingService.instance.geocodeDireccion(
          direccion: direccion,
          comuna: comuna,
        );
        if (geo != null) {
          lat = geo.lat;
          lng = geo.lng;
          geoPreciso = geo.preciso;
        }
      }

      final nuevoUsuario = UsuarioModel(
        uid: user.uid,
        nombre: nombre,
        email: email,
        tipo: tipo, // El tipo siempre será 'empresa' o 'colegio'
        direccion: direccion,
        comuna: comuna,
        telefono: telefono,
        identificacion: identificacion,
        lat: lat,
        lng: lng,
        geoPreciso: geoPreciso,
      );

      try {
        await _db.collection('usuarios').doc(user.uid).set(nuevoUsuario.toMap());
      } catch (e) {
        await user.delete();
        throw Exception('Error al guardar datos del usuario. Inténtalo de nuevo.');
      }

      // Directorio público de empresas (bandeja in-app sin Cloud Functions).
      if (tipo == 'empresa') {
        try {
          await _db.collection('empresas_publicas').doc(user.uid).set({
            'tipo': 'empresa',
            'nombre': nombre,
          });
        } catch (e) {
          // No bloqueamos el registro si este paso falla.
        }
      }

      return nuevoUsuario;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') throw Exception('Este correo ya está registrado.');
      throw Exception('Error al registrar: ${e.message}');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<UsuarioModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Usuario no encontrado tras el inicio de sesión.');
      }
      final usuario = await getUsuario(user.uid);
      if (usuario == null) {
        throw Exception('No se encontraron los datos del usuario en la base de datos.');
      }
      return usuario;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') throw Exception('Correo o contraseña incorrectos.');
      throw Exception('Error al iniciar sesión: ${e.message}');
    }
  }

  Future<UsuarioModel?> loginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;

      // Verificar si el usuario ya existe en Firestore
      UsuarioModel? usuario = await getUsuario(user.uid);

      // Si no existe, crear registro con datos de Google
      if (usuario == null) {
        usuario = UsuarioModel(
          uid: user.uid,
          nombre: user.displayName ?? 'Usuario Google',
          email: user.email ?? '',
          tipo: 'empresa', // Por defecto empresa; el usuario elegirá después
        );
        await _db.collection('usuarios').doc(user.uid).set(usuario.toMap());

        // Directorio público de empresas
        try {
          await _db.collection('empresas_publicas').doc(user.uid).set({
            'tipo': 'empresa',
            'nombre': usuario.nombre,
          });
        } catch (e) {
          // No bloqueamos el login si este paso falla.
        }
      }

      return usuario;
    } catch (e) {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  Future<void> logout() async {
    // Nos desuscribimos del topic de empresas para no recibir avisos
    // de otras cuentas en el mismo dispositivo.
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('empresas');
    } catch (_) {
      // No bloqueamos el cierre de sesión si esto falla.
    }
    await _auth.signOut();
  }

  /// Envía el correo de verificación al usuario actual.
  Future<String?> enviarVerificacion() async {
    final user = _auth.currentUser;
    if (user == null) return 'No hay un usuario autenticado.';
    try {
      await user.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return 'Error: ${e.message}';
    }
  }

  /// Indica si el usuario actual tiene el correo verificado.
  bool get emailVerificado => _auth.currentUser?.emailVerified ?? false;

  /// Recarga el usuario actual desde Firebase Auth y retorna el estado de verificación.
  Future<bool> reloadEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.reload();
        return _auth.currentUser?.emailVerified ?? false;
      } catch (e) {
        return user.emailVerified;
      }
    }
    return false;
  }

  Future<String?> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return 'No hay un usuario autenticado.';

      // Re-autenticar al usuario
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);

      // Actualizar la contraseña
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') return 'La contraseña actual es incorrecta.';
      if (e.code == 'weak-password') return 'La nueva contraseña es muy débil.';
      return 'Error: ${e.message}';
    }
  }

  Future<UsuarioModel?> getUsuario(String uid) async {
    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UsuarioModel.fromMap(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error al obtener usuario: $e');
      return null;
    }
  }

  // Stream en tiempo real: refleja los cambios de perfil al instante.
  Stream<UsuarioModel?> streamUsuario(String uid) => _db
      .collection('usuarios')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists && doc.data() != null
          ? UsuarioModel.fromMap(doc.data()!, id: doc.id)
          : null);

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No existe una cuenta con ese correo.';
      if (e.code == 'invalid-email') return 'El correo ingresado no es válido.';
      return 'Error: ${e.message}';
    }
  }
}