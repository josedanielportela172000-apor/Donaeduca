import &#39;package:flutter/material.dart&#39;;
import &#39;../models/usuario_model.dart&#39;;
import &#39;../models/necesidad_model.dart&#39;;
import &#39;../services/auth_service.dart&#39;;
import &#39;../services/firestore_service.dart&#39;;
import &#39;../utils/app_theme.dart&#39;;
import &#39;publicar_necesidad_screen.dart&#39;;
class ColegioHomeScreen extends StatelessWidget {
final UsuarioModel usuario;
const ColegioHomeScreen({super.key,required this.usuario});
@override
Widget build(BuildContext ctx) =&gt; Scaffold(
appBar:AppBar(
title:Text(usuario.nombre),
actions:[IconButton(icon:const Icon(Icons.logout),
onPressed:()=&gt;AuthService().logout())],
),
floatingActionButton:FloatingActionButton.extended(
backgroundColor:AppColors.primary,
onPressed:()=&gt;Navigator.push(ctx,MaterialPageRoute(
builder:(_)=&gt;PublicarNecesidadScreen(usuario:usuario))),
icon:const Icon(Icons.add,color:Colors.white),
label:const Text(&#39;Publicar necesidad&#39;,
style:TextStyle(color:Colors.white))),
body:StreamBuilder&lt;List&lt;NecesidadModel&gt;&gt;(
stream:FirestoreService().getNecesidadesColegio(usuario.uid),
builder:(ctx,snap){
if(snap.connectionState==ConnectionState.waiting)
return const Center(child:CircularProgressIndicator(
color:AppColors.primary));
final lista=snap.data??[];
if(lista.isEmpty) return const Center(
child:Text(&#39;Presiona + para publicar una necesidad&#39;));
return ListView.builder(
padding:const EdgeInsets.fromLTRB(14,14,14,80),
itemCount:lista.length,
itemBuilder:(ctx,i){
final n=lista[i];
return Card(
margin:const EdgeInsets.only(bottom:10),
shape:RoundedRectangleBorder(
borderRadius:BorderRadius.circular(14)),
child:ListTile(
contentPadding:const EdgeInsets.all(14),
leading:CircleAvatar(
backgroundColor:n.estado==&#39;pendiente&#39;
?AppColors.accent.withOpacity(0.25)
:AppColors.secondary.withOpacity(0.2),
child:Icon(
n.estado==&#39;pendiente&#39;
?Icons.hourglass_empty:Icons.check_circle,
color:n.estado==&#39;pendiente&#39;
?AppColors.dark:AppColors.secondary)),
title:Text(n.descripcion,style:const TextStyle(
fontWeight:FontWeight.bold,fontSize:13)),
subtitle:Text(n.categoria),
trailing:Container(
padding:const EdgeInsets.symmetric(
horizontal:10,vertical:4),
decoration:BoxDecoration(
color:n.estado==&#39;pendiente&#39;

?AppColors.accent.withOpacity(0.2)
:AppColors.secondary.withOpacity(0.15),
borderRadius:BorderRadius.circular(20)),
child:Text(
n.estado==&#39;pendiente&#39;?&#39;Pendiente&#39;:&#39;Cubierta&#39;,
style:TextStyle(fontSize:11,fontWeight:FontWeight.bold,
color:n.estado==&#39;pendiente&#39;
?AppColors.dark:AppColors.secondary))),
));
});
}
),
);
}