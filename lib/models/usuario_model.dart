class UsuarioModel {
final String uid, nombre, email, tipo;
UsuarioModel({required this.uid, required this.nombre,
required this.email, required this.tipo});
factory UsuarioModel.fromMap(Map&lt;String, dynamic&gt; m) =&gt;
UsuarioModel(uid:m[&#39;uid&#39;]??&#39;&#39;, nombre:m[&#39;nombre&#39;]??&#39;&#39;,
email:m[&#39;email&#39;]??&#39;&#39;, tipo:m[&#39;tipo&#39;]??&#39;&#39;);
Map&lt;String,dynamic&gt; toMap() =&gt;
{&#39;uid&#39;:uid,&#39;nombre&#39;:nombre,&#39;email&#39;:email,&#39;tipo&#39;:tipo};
}