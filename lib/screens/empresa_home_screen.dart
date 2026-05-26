import &#39;package:flutter/material.dart&#39;;
import &#39;package:intl/intl.dart&#39;;
import &#39;../models/usuario_model.dart&#39;;
import &#39;../models/necesidad_model.dart&#39;;
import &#39;../models/donacion_model.dart&#39;;
import &#39;../services/auth_service.dart&#39;;
import &#39;../services/firestore_service.dart&#39;;
import &#39;../utils/app_theme.dart&#39;;
class EmpresaHomeScreen extends StatelessWidget {
final UsuarioModel usuario;
const EmpresaHomeScreen({super.key, required this.usuario});
@override
Widget build(BuildContext ctx) =&gt; Scaffold(
appBar: AppBar(
title: Text(&#39;Hola, ${usuario.nombre}&#39;),
actions:[IconButton(icon:const Icon(Icons.logout),
onPressed:()=&gt;AuthService().logout())],
),
body: StreamBuilder&lt;List&lt;NecesidadModel&gt;&gt;(
stream: FirestoreService().getNecesidadesPendientes(),
builder:(ctx,snap){
if(snap.connectionState==ConnectionState.waiting)
return const Center(child:
CircularProgressIndicator(color:AppColors.primary));
final lista = snap.data??[];
if(lista.isEmpty) return const Center(
child:Text(&#39;No hay necesidades pendientes&#39;));
return ListView.builder(
padding:const EdgeInsets.all(14),
itemCount:lista.length,
itemBuilder:(ctx,i)=&gt;_Card(
necesidad:lista[i], usuario:usuario));
},
),
);
}
class _Card extends StatelessWidget {
final NecesidadModel necesidad;
final UsuarioModel usuario;
const _Card({required this.necesidad,required this.usuario});
Future&lt;void&gt; _donar(BuildContext ctx) async {
final ok = await showDialog&lt;bool&gt;(context:ctx,

builder:(_)=&gt;AlertDialog(
title:const Text(&#39;Confirmar donación&#39;),
content:Text(&#39;Donar a ${necesidad.colegioNombre}:\n${necesidad.descripcion}&#39;),
actions:[
TextButton(onPressed:()=&gt;Navigator.pop(ctx,false),
child:const Text(&#39;Cancelar&#39;)),
ElevatedButton(onPressed:()=&gt;Navigator.pop(ctx,true),
child:const Text(&#39;Confirmar&#39;)),
]));
if(ok!=true) return;
await FirestoreService().donar(
donacion:DonacionModel(id:&#39;&#39;,
empresaId:usuario.uid, empresaNombre:usuario.nombre,
colegioId:necesidad.colegioId,
colegioNombre:necesidad.colegioNombre,
necesidadId:necesidad.id,
descripcion:necesidad.descripcion,
fecha:DateTime.now()),
necesidadId:necesidad.id);
if(ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
const SnackBar(content:Text(&#39;¡Donación registrada!&#39;),
backgroundColor:AppColors.secondary));
}
@override
Widget build(BuildContext ctx) =&gt; Card(
margin:const EdgeInsets.only(bottom:12),
shape:RoundedRectangleBorder(
borderRadius:BorderRadius.circular(16)),
elevation:2,
child:Padding(padding:const EdgeInsets.all(14),
child:Column(crossAxisAlignment:CrossAxisAlignment.start,
children:[
Row(children:[
const Icon(Icons.school,color:AppColors.primary,size:18),
const SizedBox(width:6),
Text(necesidad.colegioNombre,style:const TextStyle(
fontWeight:FontWeight.bold,color:AppColors.primary)),
const Spacer(),
Container(padding:const EdgeInsets.symmetric(
horizontal:10,vertical:4),
decoration:BoxDecoration(color:AppColors.accent.withOpacity(0.2),
borderRadius:BorderRadius.circular(20)),
child:Text(necesidad.categoria,
style:const TextStyle(fontSize:11))),
]),
const SizedBox(height:8),
Text(necesidad.descripcion,style:const TextStyle(fontSize:13)),
const SizedBox(height:10),
Row(children:[
Text(DateFormat(&#39;dd/MM/yyyy&#39;).format(necesidad.fecha),
style:const TextStyle(fontSize:12,color:AppColors.grey)),
const Spacer(),
ElevatedButton.icon(
onPressed:()=&gt;_donar(ctx),
icon:const Icon(Icons.favorite,size:14),
label:const Text(&#39;Donar&#39;),
style:ElevatedButton.styleFrom(
padding:const EdgeInsets.symmetric(
horizontal:14,vertical:8))),
]),
])),
);
}