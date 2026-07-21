import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';

class AuthService {
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

      final nuevoUsuario = UsuarioModel(
        uid: user.uid,
        nombre: nombre,
        email: email,
        tipo: tipo,
        direccion: direccion,
        comuna: comuna,
        telefono: telefono,
        identificacion: identificacion,
      );

      try {
        await _db.collection('usuarios').doc(user.uid).set(nuevoUsuario.toMap());
      } catch (e) {
        await user.delete();
        throw Exception('Error al guardar datos del usuario. Inténtalo de nuevo.');
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

  Future<void> logout() => _auth.signOut();

  Future<String?> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No hay un usuario autenticado.';

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
    final d = await _db.collection('usuarios').doc(uid).get();
    return d.exists ? UsuarioModel.fromMap(d.data()!) : null;
  }
}
