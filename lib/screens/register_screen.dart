import &#39;package:flutter/material.dart&#39;;
import &#39;../services/auth_service.dart&#39;;
import &#39;../utils/app_theme.dart&#39;;
class RegisterScreen extends StatefulWidget {
const RegisterScreen({super.key});
@override State&lt;RegisterScreen&gt; createState() =&gt;
_RegisterScreenState();
}
class _RegisterScreenState extends State&lt;RegisterScreen&gt; {
final _fk=GlobalKey&lt;FormState&gt;();
final _nc=TextEditingController();
final _ec=TextEditingController();
final _pc=TextEditingController();
final _svc=AuthService();
String _tipo=&#39;empresa&#39;;
bool _load=false;
Future&lt;void&gt; _reg() async {
if (!_fk.currentState!.validate()) return;
setState(()=&gt;_load=true);
final err = await _svc.registrar(
email:_ec.text.trim(), password:_pc.text.trim(),
nombre:_nc.text.trim(), tipo:_tipo);
setState(()=&gt;_load=false);
if (err!=null &amp;&amp; mounted)
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content:Text(err),
backgroundColor:AppColors.error));
else if (mounted) Navigator.pop(context);
}
@override
Widget build(BuildContext ctx) =&gt; Scaffold(
appBar:AppBar(title:const Text(&#39;Crear cuenta&#39;)),
body:SingleChildScrollView(
padding:const EdgeInsets.all(24),
child:Form(key:_fk, child:Column(
crossAxisAlignment:CrossAxisAlignment.stretch,
children:[
const Text(&#39;Tipo de cuenta&#39;,
style:TextStyle(fontWeight:FontWeight.bold)),
const SizedBox(height:8),
Row(children:[
Expanded(child:_btn(&#39;empresa&#39;,Icons.business)),
const SizedBox(width:12),
Expanded(child:_btn(&#39;colegio&#39;,Icons.school)),
]),
const SizedBox(height:20),
TextFormField(controller:_nc,
decoration:InputDecoration(
labelText:_tipo==&#39;empresa&#39;
?&#39;Nombre de la empresa&#39;:&#39;Nombre del colegio&#39;,
prefixIcon:Icon(_tipo==&#39;empresa&#39;
?Icons.business:Icons.school)),
validator:(v)=&gt;v!.isEmpty?&#39;Requerido&#39;:null),
const SizedBox(height:14),
TextFormField(controller:_ec,
keyboardType:TextInputType.emailAddress,
decoration:const InputDecoration(
labelText:&#39;Correo electronico&#39;,
prefixIcon:Icon(Icons.email_outlined)),
validator:(v)=&gt;v!.isEmpty?&#39;Requerido&#39;:null),

const SizedBox(height:14),
TextFormField(controller:_pc,obscureText:true,
decoration:const InputDecoration(
labelText:&#39;Contraseña (min. 6 caracteres)&#39;,
prefixIcon:Icon(Icons.lock_outline)),
validator:(v)=&gt;v!.length&lt;6?&#39;Min 6 caracteres&#39;:null),
const SizedBox(height:28),
SizedBox(height:50, child:ElevatedButton(
onPressed:_load?null:_reg,
child:_load
?const CircularProgressIndicator(color:Colors.white)
:const Text(&#39;Crear cuenta&#39;,
style:TextStyle(fontSize:16)))),
],
)),
),
);
Widget _btn(String tipo, IconData ic) {
final sel = _tipo==tipo;
return GestureDetector(
onTap:()=&gt;setState(()=&gt;_tipo=tipo),
child:Container(
padding:const EdgeInsets.symmetric(vertical:14),
decoration:BoxDecoration(
color:sel?AppColors.primary:Colors.white,
borderRadius:BorderRadius.circular(12),
border:Border.all(color:sel?AppColors.primary:AppColors.grey)),
child:Column(children:[
Icon(ic,color:sel?Colors.white:AppColors.grey),
const SizedBox(height:4),
Text(tipo==&#39;empresa&#39;?&#39;Empresa&#39;:&#39;Colegio&#39;,
style:TextStyle(
color:sel?Colors.white:AppColors.grey,
fontWeight:FontWeight.bold)),
]),
),
);
}
}