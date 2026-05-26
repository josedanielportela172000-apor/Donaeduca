import &#39;package:flutter/material.dart&#39;;
import &#39;../models/usuario_model.dart&#39;;
import &#39;../models/necesidad_model.dart&#39;;
import &#39;../services/firestore_service.dart&#39;;
import &#39;../utils/app_theme.dart&#39;;
class PublicarNecesidadScreen extends StatefulWidget {
final UsuarioModel usuario;
const PublicarNecesidadScreen(
{super.key,required this.usuario});
@override State&lt;PublicarNecesidadScreen&gt; createState()=&gt;
_PNState();
}
class _PNState extends State&lt;PublicarNecesidadScreen&gt; {
final _fk=GlobalKey&lt;FormState&gt;();
final _dc=TextEditingController();
String _cat=&#39;Tecnologia&#39;;
bool _load=false;
final cats=[&#39;Tecnologia&#39;,&#39;Mobiliario&#39;,&#39;utiles escolares&#39;,
&#39;Deportes&#39;,&#39;Libros&#39;,&#39;Infraestructura&#39;,&#39;Alimentacion&#39;,&#39;Otro&#39;];
Future&lt;void&gt; _pub() async {
if(!_fk.currentState!.validate()) return;
setState(()=&gt;_load=true);
await FirestoreService().publicarNecesidad(NecesidadModel(
id:&#39;&#39;, colegioId:widget.usuario.uid,
colegioNombre:widget.usuario.nombre,
descripcion:_dc.text.trim(), categoria:_cat,
estado:&#39;pendiente&#39;, fecha:DateTime.now()));
setState(()=&gt;_load=false);
if(mounted) Navigator.pop(context);
}
@override
Widget build(BuildContext ctx) =&gt; Scaffold(
appBar:AppBar(title:const Text(&#39;Publicar necesidad&#39;)),
body:SingleChildScrollView(
padding:const EdgeInsets.all(22),
child:Form(key:_fk,child:Column(
crossAxisAlignment:CrossAxisAlignment.stretch,
children:[
const Text(&#39;Categoria&#39;,style:TextStyle(
fontWeight:FontWeight.bold)),
const SizedBox(height:8),

DropdownButtonFormField&lt;String&gt;(value:_cat,
decoration:const InputDecoration(
prefixIcon:Icon(Icons.category_outlined)),
items:cats.map((c)=&gt;DropdownMenuItem(
value:c,child:Text(c))).toList(),
onChanged:(v)=&gt;setState(()=&gt;_cat=v!)),
const SizedBox(height:18),
const Text(&#39;Descripcion&#39;,style:TextStyle(
fontWeight:FontWeight.bold)),
const SizedBox(height:8),
TextFormField(controller:_dc,maxLines:4,
decoration:const InputDecoration(hintText:
&#39;Ej: Necesitamos 20 sillas para 5to grado...&#39;),
validator:(v)=&gt;v!.isEmpty?&#39;Escribe la descripcion&#39;:null),
const SizedBox(height:28),
SizedBox(height:50,child:ElevatedButton(
onPressed:_load?null:_pub,
child:_load
?const CircularProgressIndicator(color:Colors.white)
:const Text(&#39;Publicar necesidad&#39;,
style:TextStyle(fontSize:16)))),
],
)),
),
);
}