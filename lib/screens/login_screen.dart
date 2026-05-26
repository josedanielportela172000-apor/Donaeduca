import &#39;package:flutter/material.dart&#39;;
import &#39;../services/auth_service.dart&#39;;
import &#39;../utils/app_theme.dart&#39;;
import &#39;register_screen.dart&#39;;
class LoginScreen extends StatefulWidget {
const LoginScreen({super.key});
@override State&lt;LoginScreen&gt; createState() =&gt;
_LoginScreenState();
}
class _LoginScreenState extends State&lt;LoginScreen&gt; {
final _fk = GlobalKey&lt;FormState&gt;();
final _ec = TextEditingController();
final _pc = TextEditingController();
final _svc = AuthService();
bool _load = false, _show = false;
Future&lt;void&gt; _login() async {
if (!_fk.currentState!.validate()) return;
setState(() =&gt; _load = true);

final err = await _svc.login(
email:_ec.text.trim(), password:_pc.text.trim());
setState(() =&gt; _load = false);
if (err != null &amp;&amp; mounted)
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content:Text(err),
backgroundColor:AppColors.error));
}
@override
Widget build(BuildContext ctx) =&gt; Scaffold(
body: SafeArea(child: SingleChildScrollView(
padding: const EdgeInsets.all(28),
child: Form(key:_fk, child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
const SizedBox(height:60),
const Icon(Icons.volunteer_activism,
size:72, color:AppColors.primary),
const SizedBox(height:16),
const Text(&#39;DonaEduca&#39;, textAlign:TextAlign.center,
style:TextStyle(fontSize:28,
fontWeight:FontWeight.bold,
color:AppColors.primary)),
const SizedBox(height:48),
TextFormField(controller:_ec,
keyboardType:TextInputType.emailAddress,
decoration:const InputDecoration(
labelText:&#39;Correo electrónico&#39;,
prefixIcon:Icon(Icons.email_outlined)),
validator:(v)=&gt;v!.isEmpty?&#39;Requerido&#39;:null),
const SizedBox(height:16),
TextFormField(controller:_pc,
obscureText:!_show,
decoration:InputDecoration(
labelText:&#39;Contraseña&#39;,
prefixIcon:const Icon(Icons.lock_outline),
suffixIcon:IconButton(
icon:Icon(_show?Icons.visibility_off
:Icons.visibility),
onPressed:()=&gt;setState(()=&gt;_show=!_show))),
validator:(v)=&gt;v!.isEmpty?&#39;Requerido&#39;:null),
const SizedBox(height:28),
SizedBox(height:50, child:ElevatedButton(
onPressed:_load?null:_login,
child:_load
?const CircularProgressIndicator(color:Colors.white)
:const Text(&#39;Entrar&#39;,
style:TextStyle(fontSize:16)))),
const SizedBox(height:20),
TextButton(
onPressed:()=&gt;Navigator.push(ctx,
MaterialPageRoute(
builder:(_)=&gt;const RegisterScreen())),
child:const Text(&#39;¿No tienes cuenta? Regístrate&#39;,
style:TextStyle(color:AppColors.primary))),
],
)),
)),
);
}