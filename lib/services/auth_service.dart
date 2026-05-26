import &#39;package:firebase_auth/firebase_auth.dart&#39;;
import &#39;package:cloud_firestore/cloud_firestore.dart&#39;;
import &#39;../models/usuario_model.dart&#39;;
class AuthService {
final _auth = FirebaseAuth.instance;
final _db = FirebaseFirestore.instance;
User? get currentUser =&gt; _auth.currentUser;

Future&lt;String?&gt; registrar({required String email,
required String password, required String nombre,
required String tipo}) async {
try {
final c = await _auth.createUserWithEmailAndPassword(
email: email, password: password);
await _db.collection(&#39;usuarios&#39;).doc(c.user!.uid)
.set(UsuarioModel(uid:c.user!.uid, nombre:nombre,
email:email, tipo:tipo).toMap());
return null;
} on FirebaseAuthException catch (e) {
if (e.code==&#39;email-already-in-use&#39;)
return &#39;Este correo ya está registrado&#39;;
return &#39;Error: ${e.message}&#39;;
}
}
Future&lt;String?&gt; login({required String email,
required String password}) async {
try {
await _auth.signInWithEmailAndPassword(
email:email, password:password);
return null;
} on FirebaseAuthException catch (e) {
if (e.code==&#39;user-not-found&#39;) return &#39;Usuario no encontrado&#39;;
if (e.code==&#39;wrong-password&#39;) return &#39;Contraseña incorrecta&#39;;
return &#39;Error al iniciar sesión&#39;;
}
}
Future&lt;void&gt; logout() =&gt; _auth.signOut();
Future&lt;UsuarioModel?&gt; getUsuario(String uid) async {
final d = await _db.collection(&#39;usuarios&#39;).doc(uid).get();
return d.exists ? UsuarioModel.fromMap(d.data()!) : null;
}
}