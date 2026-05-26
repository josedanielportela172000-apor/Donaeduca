import &#39;package:flutter/material.dart&#39;;
import &#39;package:firebase_auth/firebase_auth.dart&#39;;
import &#39;../services/auth_service.dart&#39;;
import &#39;../models/usuario_model.dart&#39;;
import &#39;empresa_home_screen.dart&#39;;
import &#39;colegio_home_screen.dart&#39;;
import &#39;../utils/app_theme.dart&#39;;
class HomeWrapper extends StatelessWidget {
const HomeWrapper({super.key});
@override
Widget build(BuildContext ctx) {
final uid = FirebaseAuth.instance.currentUser!.uid;
return FutureBuilder&lt;UsuarioModel?&gt;(
future: AuthService().getUsuario(uid),
builder: (ctx, snap) {
if (snap.connectionState==ConnectionState.waiting)

return const Scaffold(body:Center(
child:CircularProgressIndicator(
color:AppColors.primary)));
final u = snap.data;
if (u==null) {
FirebaseAuth.instance.signOut();
return const SizedBox();
}
return u.tipo==&#39;empresa&#39;
? EmpresaHomeScreen(usuario:u)
: ColegioHomeScreen(usuario:u);
},
);
}
}